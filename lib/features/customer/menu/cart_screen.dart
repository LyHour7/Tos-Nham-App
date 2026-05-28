import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/auth_guard.dart';
import '../../../l10n/app_localizations.dart';
import '../orders/order_online_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartItems = [];
  List branches = [];
  int? selectedBranchId;
  final Set<int> selectedMenuItemIds = {};
  bool isLoading = true;

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  /// BUILD IMAGE URL
  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";
    if (image.startsWith("http")) return image;
    final baseUrl = "${ApiConfig.baseUrl.replaceAll('/api', '')}";
    return "$baseUrl$image";
  }

  /// FETCH CART
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
        final availableMenuItemIds = items.map(_menuItemId).whereType<int>();
        selectedMenuItemIds.removeWhere(
          (menuItemId) => !availableMenuItemIds.contains(menuItemId),
        );
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Cart error: $e");
      setState(() => isLoading = false);
    }
  }

  /// FILTER BY BRANCH
  List get filteredItems {
    if (selectedBranchId == null) return cartItems;
    return cartItems.where((item) {
      return _itemBranchId(item) == selectedBranchId;
    }).toList();
  }

  List get selectedFilteredItems {
    return filteredItems.where(_isItemSelected).toList();
  }

  int? _menuItemId(dynamic item) {
    final menuItemId = item['menuItem']?['id'];
    if (menuItemId is int) return menuItemId;
    return int.tryParse(menuItemId?.toString() ?? '');
  }

  int? _itemBranchId(dynamic item) {
    final branchId = item['menuItem']?['branch']?['id'];
    if (branchId is int) return branchId;
    return int.tryParse(branchId?.toString() ?? '');
  }

  bool _isItemSelected(dynamic item) {
    final menuItemId = _menuItemId(item);
    return menuItemId != null && selectedMenuItemIds.contains(menuItemId);
  }

  void _toggleItemSelection(dynamic item) {
    final menuItemId = _menuItemId(item);
    if (menuItemId == null) return;

    setState(() {
      if (selectedMenuItemIds.contains(menuItemId)) {
        selectedMenuItemIds.remove(menuItemId);
      } else {
        selectedMenuItemIds.add(menuItemId);
      }
    });
  }

  void _showAllBranches() {
    setState(() {
      selectedBranchId = null;
    });
  }

  /// TOTAL PRICE
  double get total {
    return selectedFilteredItems.fold(0.0, (sum, item) {
      final price =
          double.tryParse(item['menuItem']['price'].toString()) ?? 0.0;
      return sum + (price * item['quantity']);
    });
  }

  /// UPDATE QTY
  Future<void> updateQuantity(Map item, int originalIndex, int newQty) async {
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

  /// INCREASE
  void increaseQty(int index) {
    final item = filteredItems[index];
    final originalIndex = cartItems.indexOf(item);
    final currentQty = cartItems[originalIndex]['quantity'];
    updateQuantity(item, originalIndex, currentQty + 1);
  }

  /// DECREASE OR REMOVE
  void decreaseQty(int index) async {
    final item = filteredItems[index];
    final originalIndex = cartItems.indexOf(item);
    final currentQty = cartItems[originalIndex]['quantity'];

    if (currentQty <= 1) {
      await ApiService.delete("/cart/${item['menuItem']['id']}");
      setState(() {
        cartItems.removeAt(originalIndex);
        final menuItemId = _menuItemId(item);
        if (menuItemId != null) {
          selectedMenuItemIds.remove(menuItemId);
        }
      });
      return;
    }

    updateQuantity(item, originalIndex, currentQty - 1);
  }

  /// GO TO ORDER ONLINE
  void goToOrderOnline() {
    final selectedItems = selectedFilteredItems;

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please check item to order"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final selectedBranchIds =
        selectedItems.map(_itemBranchId).whereType<int>().toSet();
    final orderBranchId =
        selectedBranchIds.length == 1 ? selectedBranchIds.first : null;

    if (orderBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please choose items from one branch only"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    ensureLoggedIn(context).then((allowed) {
      if (!allowed || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderOnlineScreen(
            selectedBranchId: orderBranchId,
            selectedMenuItemIds:
                selectedItems.map(_menuItemId).whereType<int>().toList(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF009688)),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF008F99),
                  ),
                  child: Text(
                    lang.startBooking,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Logo circle overlapping the bar
                Positioned(
                  left: 0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF009688), width: 2.5),
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.restaurant,
                          color: Color(0xFF009688),
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
          /// SCROLLABLE BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// BRANCH FILTER DROPDOWN
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: Color(0xFF009688),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lang.listBranch,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(canvasColor: Colors.white),
                          child: DropdownButtonFormField<int>(
                            value: selectedBranchId,
                            isExpanded: true,
                            menuMaxHeight: 260,
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: 'Select branch',
                              hintStyle: const TextStyle(
                                color: Color(0xFF6B8D89),
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                                color: Color(0xFF009688),
                                size: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF009688),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE8F5F4),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      const Color(0xFF009688).withOpacity(0.35),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF009688),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            icon: const SizedBox.shrink(),
                            items:
                                branches.map<DropdownMenuItem<int>>((branch) {
                              final int id = branch['id'];
                              final bool isSelected = selectedBranchId == id;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        branch['branch_name'],
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF00796B)
                                              : const Color(0xFF2F3B3A),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Color(0xFF009688),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedBranchId = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _showAllBranches,
                          icon: Icon(
                            selectedBranchId == null
                                ? Icons.check_circle
                                : Icons.select_all,
                            size: 18,
                          ),
                          label: const Text("All"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF009688),
                            side: BorderSide(
                              color: const Color(0xFF009688).withOpacity(0.45),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// CART ITEMS
                  filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              lang.cartEmpty,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: filteredItems.map((item) {
                            final menu = item['menuItem'];
                            final qty = item['quantity'];
                            final index = filteredItems.indexOf(item);
                            final imageUrl = buildImageUrl(menu['image']);
                            final isSelected = _isItemSelected(item);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      const Color(0xFF009688).withOpacity(0.25),
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
                                    GestureDetector(
                                      onTap: () => _toggleItemSelection(item),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFF009688)
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF009688)
                                                : const Color(0xFFB8DAD6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check
                                              : Icons.check_outlined,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF80B9B3),
                                          size: 18,
                                        ),
                                      ),
                                    ),

                                    /// FOOD IMAGE
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
                                                return Container(
                                                  width: 95,
                                                  height: 95,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                      Icons.fastfood,
                                                      color: Colors.grey),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 95,
                                              height: 95,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.fastfood,
                                                  color: Colors.grey),
                                            ),
                                    ),

                                    const SizedBox(width: 12),

                                    /// INFO + QTY
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Name pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2F1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              menu['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF00695C),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            "${lang.price}: ${menu['price']}\$",
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(height: 2),

                                          Text(
                                            "status: Available",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),

                                          Text(
                                            "${lang.location}: ${menu['branch']?['branch_name'] ?? ''}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 8),

                                          /// QTY CONTROLS
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              // Minus button
                                              GestureDetector(
                                                onTap: () => decreaseQty(index),
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF009688),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.remove,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),

                                              // Qty display
                                              Container(
                                                width: 40,
                                                height: 30,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  qty
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),

                                              // Plus button
                                              GestureDetector(
                                                onTap: () => increaseQty(index),
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF009688),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 8),

                  /// TOTAL + PAY NOW
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF008F99).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.totals,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF00695C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${total.toStringAsFixed(2)}\$",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008F99),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: selectedFilteredItems.isEmpty
                                ? null
                                : goToOrderOnline,
                            child: Text(
                              lang.payNow,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
