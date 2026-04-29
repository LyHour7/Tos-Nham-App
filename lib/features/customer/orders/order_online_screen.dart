import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/api_service.dart';
import 'qr_payment_screen.dart';

class OrderOnlineScreen extends StatefulWidget {
  const OrderOnlineScreen({super.key});

  @override
  State<OrderOnlineScreen> createState() => _OrderOnlineScreenState();
}

class _OrderOnlineScreenState extends State<OrderOnlineScreen> {
  GoogleMapController? mapController;

  LatLng selectedLocation = const LatLng(11.5564, 104.9282);
  bool isMapDragging = false;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  List items = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String paymentMethod = "qr_payment";

  static const Color teal = Color(0xFF009688);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    locationController.text =
        "${selectedLocation.latitude}, ${selectedLocation.longitude}";
  }

  @override
  void dispose() {
    mapController?.dispose();
    locationController.dispose();
    phoneController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> fetchCartItems() async {
    try {
      final data = await ApiService.get("/cart");
      setState(() {
        items = data['data']['cartItems'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  double get total {
    return items.fold(0.0, (sum, item) {
      final price =
          double.tryParse(item['menuItem']['price'].toString()) ?? 0;
      return sum + (price * item['quantity']);
    });
  }

  Future<void> increaseQty(Map item) async {
    final qty = item['quantity'];
    await ApiService.post("/cart/update", {
      "menu_item_id": item['menuItem']['id'],
      "quantity": qty + 1,
    });
    fetchCartItems();
  }

  Future<void> decreaseQty(Map item) async {
    final qty = item['quantity'];
    if (qty <= 1) {
      await ApiService.delete("/cart/remove/${item['menuItem']['id']}");
    } else {
      await ApiService.post("/cart/update", {
        "menu_item_id": item['menuItem']['id'],
        "quantity": qty - 1,
      });
    }
    fetchCartItems();
  }

  void onMapTapped(LatLng position) {
    setState(() {
      selectedLocation = position;
      locationController.text =
          "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
    });
  }

  void onCameraMove(CameraPosition position) {
    setState(() {
      isMapDragging = true;
    });
  }

  void onCameraIdle() {
    setState(() {
      isMapDragging = false;
    });
  }

  Future<void> submitOrder() async {
    if (locationController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Location & phone required"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Cart is empty"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await ApiService.post("/orders", {
        "branch_id": items.first['menuItem']['branch']['id'],
        "order_type": "delivery",
        "payment_method": paymentMethod,
        "items": items.map((item) {
          return {
            "menu_item_id": item['menuItem']['id'],
            "quantity": item['quantity'],
          };
        }).toList(),
        "delivery_address": locationController.text,
        "delivery_phone": phoneController.text,
        "delivery_name": "Customer",
        "delivery_lat": selectedLocation.latitude,
        "delivery_lng": selectedLocation.longitude,
        "notes": remarksController.text,
      });

      final order = response['data']['order'];

      if (paymentMethod == "qr_payment") {
        final payment = response['data']['payment'];
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QRPaymentScreen(
              qrString: payment['qr'],
              md5: payment['md5'],
              orderId: order['id'],
              total: order['total_amount'],
            ),
          ),
        );
      } else {
        // Cash payment - show success dialog
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Order Successful!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your order has been placed.\nPay cash on delivery.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Total: \$${order['total_amount']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Order failed. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() => isSubmitting = false);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, color: teal, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? 14 : 0,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: teal, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: teal)),
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
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Order Online",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                          Icons.delivery_dining,
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
const SizedBox(height: 10),
          /// ============================
          /// SCROLLABLE BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// MAP SECTION
                  _sectionLabel("Delivery Location", Icons.map_outlined),

                  // Map container with smooth pin in center
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Google Map
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation,
                              zoom: 14,
                            ),
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                            onTap: onMapTapped,
                            onCameraMove: onCameraMove,
                            onCameraIdle: onCameraIdle,
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            markers: {
                              Marker(
                                markerId: const MarkerId("selected"),
                                position: selectedLocation,
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen,
                                ),
                              ),
                            },
                          ),

                          // Animated center pin (smooth drag feedback)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              isMapDragging ? -12 : 0,
                              0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: teal,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: teal.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                // Shadow dot when lifted
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 2),
                                  width: isMapDragging ? 6 : 0,
                                  height: isMapDragging ? 6 : 0,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Top-left coordinate badge
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.my_location,
                                      size: 12, color: teal),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${selectedLocation.latitude.toStringAsFixed(3)}, ${selectedLocation.longitude.toStringAsFixed(3)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tealDark,
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

                  const SizedBox(height: 12),

                  // Location text field
                  _inputField(
                    controller: locationController,
                    label: "Address / Coordinates",
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 20),

                  /// PHONE
                  _sectionLabel("Phone Number", Icons.phone_outlined),
                  _inputField(
                    controller: phoneController,
                    label: "Enter your phone number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  /// ORDER ITEMS
                  _sectionLabel("Your Order", Icons.receipt_long_outlined),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: teal.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                "No items in cart",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        : Column(
                            children: items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final menu = item['menuItem'];
                              final qty = item['quantity'];
                              final price = double.tryParse(
                                      menu['price'].toString()) ??
                                  0;
                              final isLast = index == items.length - 1;

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Name
                                        Expanded(
                                          child: Text(
                                            menu['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),

                                        // Qty controls
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => decreaseQty(item),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: teal,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.remove,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                            ),
                                            Container(
                                              width: 34,
                                              alignment: Alignment.center,
                                              child: Text(
                                                qty.toString().padLeft(2, '0'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => increaseQty(item),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: teal,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.add,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(width: 12),

                                        // Price
                                        Text(
                                          "\$${(price * qty).toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                        height: 1,
                                        indent: 14,
                                        endIndent: 14,
                                        color: Colors.grey.shade100),
                                ],
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 20),

                  /// REMARKS
                  _sectionLabel("Remarks", Icons.notes_outlined),
                  _inputField(
                    controller: remarksController,
                    label: "Special instructions (optional)",
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  /// PAYMENT METHOD
                  _sectionLabel("Payment Method", Icons.payment_outlined),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: teal.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QR Payment option
                        GestureDetector(
                          onTap: () => setState(() => paymentMethod = "qr_payment"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: paymentMethod == "qr_payment"
                                  ? tealLight
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  color: paymentMethod == "qr_payment"
                                      ? teal
                                      : Colors.grey.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "QR Payment",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: paymentMethod == "qr_payment"
                                              ? tealDark
                                              : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Pay via BAKONG QR",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: paymentMethod == "qr_payment"
                                          ? teal
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: paymentMethod == "qr_payment"
                                        ? teal
                                        : Colors.transparent,
                                  ),
                                  child: paymentMethod == "qr_payment"
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 14,
                          endIndent: 14,
                        ),
                        // Cash option
                        GestureDetector(
                          onTap: () => setState(() => paymentMethod = "cash"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: paymentMethod == "cash"
                                  ? tealLight
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.money,
                                  color: paymentMethod == "cash"
                                      ? teal
                                      : Colors.grey.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Cash on Delivery",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: paymentMethod == "cash"
                                              ? tealDark
                                              : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Pay when you receive",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: paymentMethod == "cash"
                                          ? teal
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: paymentMethod == "cash"
                                        ? teal
                                        : Colors.transparent,
                                  ),
                                  child: paymentMethod == "cash"
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// TOTAL + CONFIRM
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: tealLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tealDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "\$${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        GestureDetector(
                          onTap: isSubmitting ? null : submitOrder,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28),
                            decoration: BoxDecoration(
                              color: isSubmitting
                                  ? teal.withOpacity(0.5)
                                  : teal,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Confirm Order",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}