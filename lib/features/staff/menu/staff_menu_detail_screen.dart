import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/menu_service.dart';
import '../../../models/menu_model.dart';

class StaffMenuDetailScreen extends StatefulWidget {
  final MenuItem item;

  const StaffMenuDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<StaffMenuDetailScreen> createState() => _StaffMenuDetailScreenState();
}

class _StaffMenuDetailScreenState extends State<StaffMenuDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String _selectedStatus = 'available';

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  bool _isLoadingReviews = true;
  List<Map<String, dynamic>> _reviews = [];

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    _priceController =
        TextEditingController(text: widget.item.price.toString());
    _selectedCategoryId = widget.item.categoryId;
    _selectedStatus = widget.item.status;
    _loadCategories();
    _loadReviews();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await MenuService.fetchCategoriesByBranch(widget.item.branchId);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final response =
          await ApiService.get('/menu/items/${widget.item.id}');

      dynamic data = response['data'];
      if (data is Map && data['item'] is Map) {
        data = data['item'];
      } else if (data is Map && data['menuItem'] is Map) {
        data = data['menuItem'];
      }

      List rawReviews = [];
      if (data is Map && data['reviews'] is List) {
        rawReviews = data['reviews'];
      } else if (response['data'] is Map &&
          response['data']['reviews'] is List) {
        rawReviews = response['data']['reviews'];
      }

      if (!mounted) return;
      setState(() {
        _reviews = rawReviews
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        _isLoadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingReviews = false);
    }
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnack('Please select a category', Colors.orange);
      return;
    }

    final parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null) {
      _showSnack('Price must be a valid number', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await MenuService.updateMenuItem(
        itemId: widget.item.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        price: parsedPrice,
        status: _selectedStatus,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _showSnack('Menu item updated successfully', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnack('Failed to update menu item', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: teal)),
      );
    }

    final isAvailable = _selectedStatus == 'available';

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
                  decoration: const BoxDecoration(color: teal),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_back_ios,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 2),
                              Text(
                                'Back',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Edit Menu Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant_menu,
                            color: teal,
                            size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ============================
          /// BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// FOOD IMAGE + STATUS BADGE
                    if (widget.item.image != null &&
                        widget.item.image!.isNotEmpty) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.item.image!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: double.infinity,
                                height: 180,
                                color: tealLight,
                                child: const Icon(Icons.fastfood,
                                    size: 56, color: teal),
                              ),
                            ),
                          ),
                          // Status overlay badge
                          Positioned(
                            top: 10,
                            right: 10,
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
                                isAvailable ? '✓ Available' : '✗ Unavailable',
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
                      const SizedBox(height: 16),
                    ],

                    /// EDIT FORM CARD
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.edit_outlined, 'Item Details'),
                          const SizedBox(height: 16),

                          // Name
                          _inputField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.fastfood_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                          ),

                          const SizedBox(height: 12),

                          // Category dropdown
                          _dropdownField<int>(
                            value: _selectedCategoryId,
                            label: 'Category',
                            icon: Icons.category_outlined,
                            items: _categories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat['id'] as int,
                                child: Text(
                                  (cat['name'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategoryId = v),
                          ),

                          const SizedBox(height: 12),

                          // Price
                          _inputField(
                            controller: _priceController,
                            label: 'Price (\$)',
                            icon: Icons.attach_money_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Price is required';
                              }
                              if (double.tryParse(v.trim()) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Status dropdown
                          _dropdownField<String>(
                            value: _selectedStatus,
                            label: 'Status',
                            icon: Icons.toggle_on_outlined,
                            items: [
                              DropdownMenuItem(
                                value: 'available',
                                child: Row(
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green)),
                                    const SizedBox(width: 8),
                                    const Text('Available',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'unavailable',
                                child: Row(
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red)),
                                    const SizedBox(width: 8),
                                    const Text('Unavailable',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedStatus = v);
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // Description
                          _inputField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// CUSTOMER REVIEWS
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionTitle(
                                  Icons.rate_review_outlined,
                                  'Customer Reviews'),
                              if (!_isLoadingReviews &&
                                  _reviews.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tealLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_reviews.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: tealDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingReviews)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    color: teal, strokeWidth: 2),
                              ),
                            )
                          else if (_reviews.isEmpty)
                            Column(
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 36,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  'No customer reviews yet.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          else
                            ..._reviews.map((review) {
                              final reviewer = review['user'] is Map
                                  ? (review['user']['name']
                                          ?.toString() ??
                                      'Anonymous')
                                  : (review['user_name']?.toString() ??
                                      'Anonymous');
                              final ratingValue = int.tryParse(
                                    review['rating']?.toString() ?? '0',
                                  ) ??
                                  0;
                              final reviewText =
                                  review['review']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          Colors.grey.withOpacity(0.12)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: tealLight,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            reviewer.isNotEmpty
                                                ? reviewer[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: tealDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reviewer,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                              if (ratingValue > 0)
                                                _buildFixedStars(
                                                    ratingValue),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (reviewText.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        reviewText,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// SAVE BUTTON
                    GestureDetector(
                      onTap: _isSaving ? null : _saveChanges,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _isSaving ? Colors.grey.shade300 : teal,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isSaving
                              ? []
                              : [
                                  BoxShadow(
                                    color: teal.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// White card section wrapper
  Widget _sectionCard({required Widget child}) {
    return Container(
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

  /// Section title with icon in tealLight circle
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  /// Reusable styled text field
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: teal, size: 18),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: teal.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: teal.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.red.withOpacity(0.6)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 14 : 0,
        ),
      ),
    );
  }

  /// Reusable styled dropdown field
  Widget _dropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: teal.withOpacity(0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                TextStyle(color: Colors.grey.shade600, fontSize: 13),
            prefixIcon: Icon(icon, color: teal, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, color: teal),
        ),
      ),
    );
  }
}