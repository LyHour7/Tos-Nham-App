import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

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

  /// BUILD IMAGE URL
  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";

    if (image.startsWith("http")) {
      return image; // Supabase image
    }

    return "http://10.0.2.2:5000$image"; // Local image
  }

  /// RATING STARS
  Widget buildRatingStars(String ratingString) {
    final rating = double.tryParse(ratingString) ?? 0;
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final rating = item['average_rating'] ?? "0";
    final totalRatings = item['total_ratings'] ?? "0";
    final isAvailable =
        item['status'].toString().toLowerCase() == "available";

    final imageUrl = buildImageUrl(item['image']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey,
                          child: const Icon(
                            Icons.fastfood,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey,
                      child: const Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            /// INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME + PRICE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${item['price']}",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// STATUS
                  Row(
                    children: [
                      const Text("Status: "),
                      Text(
                        isAvailable ? "Available" : "Unavailable",
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// RATING
                  Row(
                    children: [
                      buildRatingStars(rating),
                      const SizedBox(width: 6),
                      Text("($totalRatings reviews)"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// DESCRIPTION
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              item['description']?.toString().isNotEmpty == true
                  ? item['description']
                  : "No description available.",
              style: const TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            /// QUANTITY + ADD TO CART
            Row(
              children: [

                /// QUANTITY SELECTOR
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [

                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                      ),

                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),

                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// ADD TO CART BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAvailable ? Colors.teal : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  onPressed: isAvailable
                      ? () async {
                          await ApiService.post("/cart", {
                            "menu_item_id": item['id'],
                            "quantity": quantity
                          });

                          if (!mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text("Added to cart"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  child: const Text("Add to cart"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}