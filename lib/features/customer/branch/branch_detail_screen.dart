import 'package:flutter/material.dart';
import 'package:tos_nham_app/features/customer/menu/menu_detail_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/home_service.dart';

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

  @override
  void initState() {
    super.initState();
    loadBranchMenu();
  }

  Future<void> loadBranchMenu() async {
    try {
      final data =
          await ApiService.get("/menu/items?branch_id=${widget.branchId}");

      final items = data['data']['menuItems'];

      /// remove duplicate categories
      final Map<int, dynamic> uniqueMap = {};
      for (var item in items) {
        final cat = item['category'];
        uniqueMap[cat['id']] = cat;
      }

      setState(() {
        menuItems = items;
        categories = uniqueMap.values.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Branch menu error: $e");
      setState(() => isLoading = false);
    }
  }

  /// FIX IMAGE URL
  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";

    if (image.startsWith("http")) {
      return image; // Supabase image
    }

    return "http://10.0.2.2:5000$image"; // local image
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branchName),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// CATEGORY FILTER
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected =
                      selectedCategoryId == category['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryId = category['id'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.teal
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// MENU LIST
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text("No items found"))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {

                        final item = filteredItems[index];
                        final bool isAvailable =
                            item['status'].toString().toLowerCase() ==
                                "available";

                        final imageUrl = buildImageUrl(item['image']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [

                              /// IMAGE
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.fastfood,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey,
                                        child: const Icon(
                                          Icons.fastfood,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),

                              const SizedBox(width: 15),

                              /// DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Price: \$${item['price']}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "Status: ${item['status']}",
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// ACTIONS
                              Column(
                                children: [

                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.teal,
                                    ),
                                    onPressed: isAvailable
                                        ? () async {
                                            try {
                                              await HomeService
                                                  .addToCart(
                                                      item['id']);

                                              if (!mounted)
                                                return;

                                              ScaffoldMessenger.of(
                                                      context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Added to cart"),
                                                  backgroundColor:
                                                      Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                      context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text("Error: $e"),
                                                  backgroundColor:
                                                      Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                  ),

                                  const SizedBox(height: 5),

                                  ElevatedButton(
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.teal,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 6),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MenuDetailScreen(
                                                  item: item),
                                        ),
                                      );
                                    },
                                    child:
                                        const Text("View Detail"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}