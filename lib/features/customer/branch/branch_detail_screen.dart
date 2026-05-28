import 'package:flutter/material.dart';
import 'package:tos_nham_app/features/customer/menu/menu_detail_screen.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/auth_guard.dart';

class BranchDetailScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const BranchDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  List menuItems = [];
  List categories = [];
  int? selectedCategoryId;
  bool isLoading = true;

  static const Color teal = Color(0xFF009688);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color readableText = Color(0xFF111111);
  static const List<String> khmerFontFallback = [
    'Noto Sans Khmer',
    'Khmer OS Battambang',
    'Roboto',
  ];

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    loadBranchMenu();
  }

  Future<void> loadBranchMenu() async {
    try {
      final responses = await Future.wait([
        ApiService.get("/menu/items?branch_id=${widget.branchId}"),
        ApiService.get("/menu/categories?branch_id=${widget.branchId}"),
      ]);

      final menuResponse = responses[0];
      final categoryResponse = responses[1];

      final items = menuResponse['data']?['menuItems'] ?? [];

      List endpointCategories = [];
      final categoryData = categoryResponse['data'];
      if (categoryData is List) {
        endpointCategories = categoryData;
      } else if (categoryData is Map && categoryData['categories'] is List) {
        endpointCategories = categoryData['categories'];
      }

      // Fallback to categories from menu items if endpoint format differs.
      if (endpointCategories.isEmpty) {
        final Map<int, dynamic> uniqueMap = {};
        for (var item in items) {
          final cat = item['category'];
          if (cat != null && cat['id'] != null) {
            uniqueMap[cat['id']] = cat;
          }
        }
        endpointCategories = uniqueMap.values.toList();
      }

      setState(() {
        menuItems = items;
        categories = endpointCategories;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Branch menu error: $e");
      setState(() => isLoading = false);
    }
  }

  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";
    if (image.startsWith("http")) return image;
    final baseUrl = "${ApiConfig.baseUrl.replaceAll('/api', '')}";
    return "$baseUrl$image";
  }

  List get filteredItems {
    if (selectedCategoryId == null) return menuItems;
    return menuItems
        .where((item) => item['category']['id'] == selectedCategoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: teal),
        ),
      );
    }

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
                // Teal bar
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.only(
                    left: 52,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF008F99)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.branchName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo overlapping
                Positioned(
                  left: 0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Color(0xFF008F99), width: 2.5),
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
                          Icons.store,
                          color: teal,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ============================
          /// CATEGORY FILTER
          /// ============================
          Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 15, bottom: 5),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1, // +1 for "All"
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : categories[index - 1];
                  final isSelected = isAll
                      ? selectedCategoryId == null
                      : selectedCategoryId == category['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryId = isAll ? null : category['id'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF008F99) : tealLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFF008F99)
                              : Color(0xFF008F99).withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isAll ? "All" : category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : readableText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamilyFallback: khmerFontFallback,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// ============================
          /// MENU LIST
          /// ============================
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final bool isAvailable =
                          item['status'].toString().toLowerCase() ==
                              "available";
                      final imageUrl = buildImageUrl(item['image']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: teal.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// IMAGE
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 95,
                                        height: 95,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _imageFallback();
                                        },
                                      )
                                    : _imageFallback(),
                              ),

                              const SizedBox(width: 12),

                              /// DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tealLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: readableText,
                                          fontFamilyFallback: khmerFontFallback,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Price: \$${item['price']}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isAvailable
                                              ? Colors.green.withOpacity(0.4)
                                              : Colors.red.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        item['status'],
                                        style: TextStyle(
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              /// ACTIONS
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Cart icon
                                  GestureDetector(
                                    onTap: isAvailable
                                        ? () async {
                                            final allowed =
                                                await ensureLoggedIn(context);
                                            if (!allowed) return;

                                            try {
                                              await ApiService.post(
                                                "/cart",
                                                {
                                                  "menu_item_id": item['id'],
                                                  "quantity": 1,
                                                },
                                              );

                                              if (!mounted) return;

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      "Added to cart"),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text("Error: $e"),
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? tealLight
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: isAvailable
                                            ? teal
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // View button
                                  SizedBox(
                                    width: 72,
                                    height: 32,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF008F99),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                MenuDetailScreen(item: item),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "View",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: tealLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood, color: teal, size: 36),
    );
  }
}
