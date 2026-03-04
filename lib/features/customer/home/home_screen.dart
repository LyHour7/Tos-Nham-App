import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List branches = [];
  List menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      final branchData = await HomeService.fetchBranches();
      final menuData = await HomeService.fetchMenuItems();

      menuData.shuffle(Random());

      setState(() {
        branches = branchData;
        menuItems = menuData.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Home Load Error: $e");
      setState(() => isLoading = false);
    }
  }

  /// BUILD IMAGE URL
  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";

    if (image.startsWith("http")) {
      return image; // Supabase image
    }

    return "http://10.0.2.2:5000$image"; // Local image
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ===============================
          /// 🔹 ALL BRANCH
          /// ===============================
          const Text(
            "All Branch",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];

                return Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal,
                        child: Text(
                          branch['branch_name'][0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        branch['branch_name'],
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          /// ===============================
          /// 🔹 POPULAR FOOD
          /// ===============================
          const Text(
            "Popular Food",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Column(
            children: menuItems.map((item) {

              final bool isAvailable =
                  item['status'].toString().toLowerCase() == "available";

              final imageUrl = buildImageUrl(item['image']);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),

                child: Row(
                  children: [

                    /// IMAGE
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),

                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 100,
                              height: 110,
                              fit: BoxFit.cover,

                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 110,
                                  color: Colors.grey,
                                  child: const Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 100,
                              height: 110,
                              color: Colors.grey,
                              child: const Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    /// DETAILS
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// NAME
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// PRICE
                            Text(
                              "Price: \$${item['price']}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// LOCATION
                            Text(
                              "Location: ${item['branch']['branch_name']}",
                              style: const TextStyle(fontSize: 13),
                            ),

                            const SizedBox(height: 4),

                            /// STATUS
                            Text(
                              "Status: ${item['status']}",
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// ADD TO CART
                            Align(
                              alignment: Alignment.centerRight,

                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                ),

                                onPressed: isAvailable
                                    ? () async {
                                        try {

                                          await HomeService.addToCart(
                                              item['id']);

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text("Added to cart"),
                                              backgroundColor:
                                                  Colors.green,
                                            ),
                                          );

                                        } catch (e) {

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text("Failed: $e"),
                                              backgroundColor:
                                                  Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    : null,

                                child: const Text("Add"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),
          ),
        ],
      ),
    );
  }
}