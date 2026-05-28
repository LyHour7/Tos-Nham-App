import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/auth_guard.dart';
import '../widgets/bottom_nav_bar.dart';

class MenuDetailScreen extends StatefulWidget {
  final Map item;

  const MenuDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int quantity = 1;
  int selectedRating = 5;
  bool isSubmittingRating = false;
  bool isLoadingReviews = true;
  int? currentUserId;
  bool hasRatedThisItem = false;
  int myRating = 0;
  late TextEditingController reviewController;
  late double averageRating;
  late int totalRatingsCount;
  List<Map<String, dynamic>> reviews = [];

  static const Color teal = Color(0xFF009688);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController();
    averageRating =
        double.tryParse(widget.item['average_rating']?.toString() ?? '0') ?? 0;
    totalRatingsCount =
        int.tryParse(widget.item['total_ratings']?.toString() ?? '0') ?? 0;
    _initializeDetails();
  }

  Future<void> _initializeDetails() async {
    await _loadCurrentUser();
    await _loadReviews();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() => currentUserId = user?.id);
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";
    if (image.startsWith("http")) return image;
    final baseUrl = "${ApiConfig.baseUrl.replaceAll('/api', '')}";
    return "$baseUrl$image";
  }

  Widget _buildRatingStars(double rating, {double size = 18}) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (i == fullStars && hasHalf) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  Widget _buildFixedStars(int count, {double size = 15}) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < count ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  String _formatReviewDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic>? _extractMenuItem(dynamic response) {
    if (response is! Map) return null;

    dynamic data = response['data'] ?? response;
    if (data is Map && data['item'] is Map) {
      data = data['item'];
    } else if (data is Map && data['menuItem'] is Map) {
      data = data['menuItem'];
    }

    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  bool _syncRatingSummary(Map<String, dynamic> itemData) {
    final averageRaw = itemData['average_rating'] ??
        itemData['averageRating'] ??
        itemData['avg_rating'] ??
        itemData['avgRating'];
    final totalRaw = itemData['total_ratings'] ??
        itemData['totalRatings'] ??
        itemData['rating_count'] ??
        itemData['ratings_count'];
    var updated = false;

    if (averageRaw != null) {
      final parsedAverage = double.tryParse(averageRaw.toString());
      if (parsedAverage != null) {
        averageRating = parsedAverage;
        widget.item['average_rating'] = parsedAverage;
        updated = true;
      }
    }

    if (totalRaw != null) {
      final parsedTotal = int.tryParse(totalRaw.toString());
      if (parsedTotal != null) {
        totalRatingsCount = parsedTotal;
        widget.item['total_ratings'] = parsedTotal;
        updated = true;
      }
    }

    return updated;
  }

  bool _syncRatingSummaryFromReviews(List rawReviews) {
    var ratingCount = 0;
    var totalScore = 0;

    for (final raw in rawReviews) {
      if (raw is! Map) continue;
      final rating = int.tryParse(raw['rating']?.toString() ?? '0') ?? 0;
      if (rating <= 0) continue;

      ratingCount += 1;
      totalScore += rating;
    }

    if (ratingCount == 0) return false;

    averageRating = totalScore / ratingCount;
    totalRatingsCount = ratingCount;
    widget.item['average_rating'] = averageRating;
    widget.item['total_ratings'] = totalRatingsCount;
    return true;
  }

  Future<void> _submitRating() async {
    if (selectedRating < 1 || selectedRating > 5) return;
    final reviewText = reviewController.text.trim();
    final wasRated = hasRatedThisItem;
    final submittedRating = selectedRating;

    if (wasRated && reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('You already rated this item. Please write a review.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => isSubmittingRating = true);

    try {
      final payload = <String, dynamic>{'review': reviewText};
      if (!wasRated) payload['rating'] = submittedRating;

      final response = await ApiService.post(
          '/menu/items/${widget.item['id']}/rate', payload);

      if (!mounted) return;

      setState(() {
        final updatedItem = _extractMenuItem(response);
        final hasServerSummary =
            updatedItem != null && _syncRatingSummary(updatedItem);

        if (!wasRated) {
          if (!hasServerSummary) {
            final totalScore =
                (averageRating * totalRatingsCount) + submittedRating;
            totalRatingsCount += 1;
            averageRating =
                totalRatingsCount == 0 ? 0 : totalScore / totalRatingsCount;
            widget.item['average_rating'] = averageRating;
            widget.item['total_ratings'] = totalRatingsCount;
          }
          hasRatedThisItem = true;
          myRating = submittedRating;
          selectedRating = submittedRating;
        }
        if (reviewText.isNotEmpty) {
          reviews.insert(0, {
            'review': reviewText,
            'rating': wasRated ? myRating : submittedRating,
            'user': {'name': 'You'},
            'user_id': currentUserId,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      });

      reviewController.clear();
      await _loadReviews();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Thanks! Your rating has been submitted.'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasRatedThisItem
              ? 'Failed to submit review.'
              : 'Failed to submit rating.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmittingRating = false);
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => isLoadingReviews = true);
    try {
      final response = await ApiService.get('/menu/items/${widget.item['id']}');

      final data = _extractMenuItem(response);

      List rawReviews = [];
      if (data != null && data['reviews'] is List) {
        rawReviews = data['reviews'];
      } else {
        final responseData = response is Map ? response['data'] : null;
        if (responseData is Map && responseData['reviews'] is List) {
          rawReviews = responseData['reviews'];
        }
      }

      bool rated = false;
      int ratingValue = 0;
      final hasRatedFromApi = data != null && data['has_rated'] == true;
      final apiRatingRaw = data?['my_rating'];

      if (hasRatedFromApi) {
        rated = true;
        ratingValue = int.tryParse(apiRatingRaw?.toString() ?? '0') ?? 0;
      } else if (currentUserId != null) {
        for (final raw in rawReviews) {
          if (raw is! Map) continue;
          final review = Map<String, dynamic>.from(raw);
          final reviewUserId = review['user_id'] ??
              (review['user'] is Map ? review['user']['id'] : null);
          final reviewRating =
              int.tryParse(review['rating']?.toString() ?? '0') ?? 0;
          if (reviewUserId == currentUserId && reviewRating > 0) {
            rated = true;
            ratingValue = reviewRating;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        final hasSummary = data != null && _syncRatingSummary(data);
        if (!hasSummary) _syncRatingSummaryFromReviews(rawReviews);
        reviews = rawReviews
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        hasRatedThisItem = rated;
        if (ratingValue > 0) {
          myRating = ratingValue;
          selectedRating = ratingValue;
        }
      });
    } catch (_) {
      // keep current local reviews
    } finally {
      if (mounted) setState(() => isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rating = averageRating.toStringAsFixed(1);
    final totalRatings = totalRatingsCount.toString();
    final isAvailable = item['status'].toString().toLowerCase() == "available";
    final imageUrl = buildImageUrl(item['image']);
    final branchName = item['branch']?['branch_name'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// ============================
          /// HEADER
          /// ============================
          Container(
            color: Colors.transparent,
            margin: const EdgeInsets.only(top: 48),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.only(
                      left: 52, right: 16, top: 14, bottom: 14),
                  decoration: const BoxDecoration(color: Color(0xFF008F99)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (branchName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              branchName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: teal, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.restaurant, color: teal, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ============================
          /// SCROLLABLE BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// FOOD IMAGE — full bleed with gradient overlay
                  Stack(
                    children: [
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              )
                            : _imageFallback(),
                      ),
                      // Subtle bottom gradient to blend into info card
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Availability badge over image
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withOpacity(0.88)
                                : Colors.red.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable ? "✓ Available" : "✗ Unavailable",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// INFO CARD — name, price, rating
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tealLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: teal.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                "\$${item['price']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(color: teal.withOpacity(0.2), height: 1),
                        const SizedBox(height: 12),

                        // Rating + count row
                        Row(
                          children: [
                            _buildRatingStars(averageRating),
                            const SizedBox(width: 8),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "($totalRatings reviews)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Branch location row
                        if (branchName.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 14, color: tealDark),
                              const SizedBox(width: 5),
                              Text(
                                branchName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tealDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  /// DESCRIPTION
                  _sectionCard(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                            Icons.description_outlined, "Description"),
                        const SizedBox(height: 10),
                        Text(
                          item['description']?.toString().isNotEmpty == true
                              ? item['description']
                              : "No description available.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RATE PRODUCT
                  _sectionCard(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.star_outline, "Rate this product"),
                        const SizedBox(height: 12),

                        // Stars row
                        Row(
                          children: hasRatedThisItem
                              ? List.generate(
                                  5,
                                  (i) => Icon(
                                    i < myRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                )
                              : List.generate(5, (i) {
                                  final star = i + 1;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => selectedRating = star),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        star <= selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 30,
                                      ),
                                    ),
                                  );
                                }),
                        ),

                        if (hasRatedThisItem) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 13, color: Colors.orange.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'You already rated this item. You can still add a review.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Review text field
                        TextField(
                          controller: reviewController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Write your review (optional)...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: teal.withOpacity(0.25)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: teal.withOpacity(0.25)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: teal, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed:
                                isSubmittingRating ? null : _submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSubmittingRating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    hasRatedThisItem
                                        ? 'Submit Review'
                                        : 'Submit Rating',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// CUSTOMER REVIEWS
                  _sectionCard(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle(
                                Icons.rate_review_outlined, "Customer Reviews"),
                            if (!isLoadingReviews)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tealLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${reviews.length}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: tealDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: tealLight.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: teal.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              _buildRatingStars(averageRating, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '$rating/5',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$totalRatings ratings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isLoadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: teal, strokeWidth: 2),
                            ),
                          )
                        else if (reviews.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 26),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: tealLight.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.chat_bubble_outline,
                                      size: 28, color: teal.withOpacity(0.8)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first customer to share feedback.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...reviews.map((review) {
                            final reviewer = review['user'] is Map
                                ? (review['user']['name']?.toString() ??
                                    'Anonymous')
                                : (review['user_name']?.toString() ??
                                    'Anonymous');
                            final ratingValue = int.tryParse(
                                  review['rating']?.toString() ?? '0',
                                ) ??
                                0;
                            final reviewText =
                                review['review']?.toString() ?? '';
                            final isMe = review['user_id'] == currentUserId;
                            final reviewDate =
                                _formatReviewDate(review['createdAt']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12.5),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? tealLight.withOpacity(0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMe
                                      ? teal.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Avatar circle
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isMe
                                              ? teal
                                              : Colors.grey.shade300,
                                        ),
                                        child: Center(
                                          child: Text(
                                            reviewer.isNotEmpty
                                                ? reviewer[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  reviewer,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                if (isMe) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: teal,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Text(
                                                      'You',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (ratingValue > 0)
                                              _buildFixedStars(ratingValue),
                                          ],
                                        ),
                                      ),
                                      if (reviewDate.isNotEmpty)
                                        Text(
                                          reviewDate,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (reviewText.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        reviewText,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      /// ============================
      /// BOTTOM BAR
      /// ============================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quantity",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Minus
                GestureDetector(
                  onTap: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: quantity > 1 ? teal : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.remove, color: Colors.white, size: 18),
                  ),
                ),
                Container(
                  width: 48,
                  height: 36,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Plus
                GestureDetector(
                  onTap: () => setState(() => quantity++),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),

                const Spacer(),

                // Go to cart
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CustomerBottomNavBar(initialIndex: 2),
                      ),
                    );
                  },
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: teal.withOpacity(0.5)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Go to cart",
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Add to cart
                GestureDetector(
                  onTap: isAvailable
                      ? () async {
                          final allowed = await ensureLoggedIn(context);
                          if (!allowed) return;

                          await ApiService.post("/cart", {
                            "menu_item_id": item['id'],
                            "quantity": quantity,
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text("${item['name']} added to cart"),
                                ],
                              ),
                              backgroundColor: Color(0xFF008F99),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: isAvailable ? teal : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isAvailable
                          ? [
                              BoxShadow(
                                color: Color(0xFF008F99).withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isAvailable ? "Add to cart" : "Unavailable",
                      style: TextStyle(
                        color: isAvailable ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable white card container
  Widget _sectionCard({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Section title with icon
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: tealDark),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 240,
      width: double.infinity,
      color: tealLight,
      child: const Icon(Icons.fastfood, size: 72, color: teal),
    );
  }
}
