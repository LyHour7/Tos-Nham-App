import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartItems = [];
  List branches = [];
  int? selectedBranchId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      final data = await ApiService.get("/cart");
      final items = data['data']['cartItems'] ?? [];

      final Map<int, dynamic> branchMap = {};

      for (var item in items) {
        final branch = item['menuItem']?['branch'];
        if (branch != null) {
          branchMap[branch['id']] = branch;
        }
      }

      setState(() {
        cartItems = items;
        branches = branchMap.values.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Cart error: $e");
      setState(() => isLoading = false);
    }
  }

  List get filteredItems {
    if (selectedBranchId == null) return cartItems;

    return cartItems.where((item) {
      return item['menuItem']?['branch']?['id'] ==
          selectedBranchId;
    }).toList();
  }

  double get total {
    return filteredItems.fold(0.0, (sum, item) {
      final price =
          double.tryParse(item['menuItem']['price']) ?? 0.0;
      return sum + (price * item['quantity']);
    });
  }

  Future<void> updateQuantity(
      Map item, int originalIndex, int newQty) async {
    try {
      await ApiService.put(
        "/cart/${item['menuItem']['id']}",
        {"quantity": newQty},
      );

      setState(() {
        cartItems[originalIndex]['quantity'] = newQty;
      });
    } catch (e) {
      debugPrint("Update quantity error: $e");
    }
  }

  void increaseQty(int index) {
    final item = filteredItems[index];
    final originalIndex = cartItems.indexOf(item);

    final currentQty = cartItems[originalIndex]['quantity'];
    updateQuantity(item, originalIndex, currentQty + 1);
  }

  void decreaseQty(int index) {
    final item = filteredItems[index];
    final originalIndex = cartItems.indexOf(item);

    final currentQty = cartItems[originalIndex]['quantity'];
    if (currentQty <= 1) return;

    updateQuantity(item, originalIndex, currentQty - 1);
  }

  /// ===============================
  /// SHOW PAYMENT OPTIONS
  /// ===============================
  void showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Select the option",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize:
                      const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/booking',
                  );
                },
                child: const Text("Booking"),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize:
                      const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/order-online',
                  );
                },
                child: const Text("Order Online"),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
        title: const Text("Start your booking"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButtonFormField<int>(
              value: selectedBranchId,
              hint: const Text("List Branch"),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.teal.shade50,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: branches
                  .map<DropdownMenuItem<int>>((branch) {
                return DropdownMenuItem<int>(
                  value: branch['id'],
                  child: Text(branch['branch_name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBranchId = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text("Cart is empty"))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder:
                          (context, index) {
                        final item =
                            filteredItems[index];
                        final menu =
                            item['menuItem'];
                        final qty =
                            item['quantity'];

                        return Container(
                          margin:
                              const EdgeInsets.only(
                                  bottom: 15),
                          padding:
                              const EdgeInsets.all(
                                  12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors
                                    .teal.shade200),
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                          ),
                          child: Row(
                            children: [

                              ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                                child:
                                    menu['image'] !=
                                            null
                                        ? Image
                                            .network(
                                            "http://10.0.2.2:5000${menu['image']}",
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit
                                                .cover,
                                          )
                                        : Container(
                                            width: 90,
                                            height:
                                                90,
                                            color: Colors
                                                .grey,
                                            child: const Icon(
                                                Icons
                                                    .fastfood),
                                          ),
                              ),

                              const SizedBox(
                                  width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Text(
                                      menu['name'],
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold),
                                    ),

                                    const SizedBox(
                                        height: 6),

                                    Text(
                                      "Price: ${menu['price']}\$",
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.red,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 8),

                                    Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons
                                                  .remove,
                                              size:
                                                  18),
                                          onPressed: () =>
                                              decreaseQty(
                                                  index),
                                        ),
                                        Text(
                                          qty
                                              .toString(),
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons
                                                  .add,
                                              size:
                                                  18),
                                          onPressed: () =>
                                              increaseQty(
                                                  index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal
                    .withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        "Totals",
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                      Text(
                        "${total.toStringAsFixed(2)}\$",
                        style:
                            const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.teal,
                    ),
                    onPressed:
                        filteredItems.isEmpty
                            ? null
                            : showPaymentOptions,
                    child:
                        const Text("Pay Now"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}