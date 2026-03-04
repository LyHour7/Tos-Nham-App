import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/api_service.dart';
import 'qr_payment_screen.dart';

class OrderOnlineScreen extends StatefulWidget {
  const OrderOnlineScreen({super.key});

  @override
  State<OrderOnlineScreen> createState() =>
      _OrderOnlineScreenState();
}

class _OrderOnlineScreenState
    extends State<OrderOnlineScreen> {

  GoogleMapController? mapController;

  LatLng selectedLocation =
      const LatLng(11.5564, 104.9282); // Phnom Penh default

  final TextEditingController locationController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController remarksController =
      TextEditingController();

  List items = [];
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
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
          double.tryParse(item['menuItem']['price']) ?? 0;
      return sum + (price * item['quantity']);
    });
  }

  void onMapTapped(LatLng position) {
    setState(() {
      selectedLocation = position;
      locationController.text =
          "${position.latitude}, ${position.longitude}";
    });
  }

  Future<void> submitOrder() async {
    if (locationController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location & phone required")),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Cart is empty")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await ApiService.post("/orders", {
        "branch_id":
            items.first['menuItem']['branch']['id'],
        "order_type": "delivery",
        "payment_method": "qr_payment", // IMPORTANT
        "items": items.map((item) {
          return {
            "menu_item_id":
                item['menuItem']['id'],
            "quantity": item['quantity']
          };
        }).toList(),
        "delivery_address":
            locationController.text,
        "delivery_phone":
            phoneController.text,
        "delivery_name": "Customer",
        "delivery_lat":
            selectedLocation.latitude,
        "delivery_lng":
            selectedLocation.longitude,
        "notes": remarksController.text,
      });

      final order = response['data']['order'];
      final payment = response['data']['payment'];

      // Navigate to QR Screen
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

    } catch (e) {
      debugPrint("Order error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Order failed")),
      );
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Start your pay order"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// GOOGLE MAP
            SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(
                  target: selectedLocation,
                  zoom: 14,
                ),
                onMapCreated:
                    (GoogleMapController controller) {
                  mapController = controller;
                },
                onTap: onMapTapped,
                markers: {
                  Marker(
                    markerId:
                        const MarkerId("selected"),
                    position: selectedLocation,
                  )
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text("Location"),
            const SizedBox(height: 6),
            TextField(
              controller: locationController,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            const Text("Phone Number"),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Items",
              style: TextStyle(
                  fontWeight:
                      FontWeight.bold),
            ),

            Column(
              children:
                  items.map((item) {
                final menu =
                    item['menuItem'];
                return ListTile(
                  title: Text(
                      "${menu['name']} x${item['quantity']}"),
                  trailing: Text(
                    "\$${(double.parse(menu['price']) * item['quantity']).toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.red),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text("Remarks"),
            const SizedBox(height: 6),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.green,
                  ),
                  onPressed:
                      isSubmitting
                          ? null
                          : submitOrder,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirm"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}