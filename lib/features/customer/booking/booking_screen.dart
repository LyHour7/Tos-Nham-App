import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../reservation/reservation_qr_payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() =>
      _BookingFormScreenState();
}

class _BookingFormScreenState
    extends State<BookingFormScreen> {

  int guestCount = 1;
  DateTime selectedDate = DateTime.now();
  String selectedTime = "18:00";

  final TextEditingController remarksController =
      TextEditingController();

  List cartItems = [];
  List tables = [];
  List branches = [];

  double itemsTotal = 0;

  // If user didn't select any food items, charge a booking-only fee
  double get effectiveItemsTotal => cartItems.isEmpty ? 2.5 : itemsTotal;

  int? branchId;           // from cart
  int? selectedBranchId;   // manual selection
  int? selectedTableId;

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialData();
    });
  }

  Future<void> loadInitialData() async {
    setState(() => isLoading = true);
    await fetchBranches();
    await fetchCart();
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  /// =========================
  /// FETCH BRANCHES
  /// =========================
  Future<void> fetchBranches() async {
    try {
      final response = await ApiService.get("/branches");
      setState(() {
        branches = response['data']['branches'];
      });
      // If no branch selected yet, choose the first branch so tables are visible
      if (selectedBranchId == null && branches.isNotEmpty) {
        selectedBranchId = branches.first['id'];
        await fetchTables(selectedBranchId!);
      }
    } catch (e) {
      debugPrint("Branch error: $e");
    }
  }

  /// =========================
  /// FETCH CART
  /// =========================
  Future<void> fetchCart() async {
    try {
      final data = await ApiService.get("/cart");
      final items = data['data']['cartItems'] ?? [];

      double total = 0;
      int? extractedBranch;

      for (var item in items) {
        final price =
            double.tryParse(item['menuItem']['price'].toString()) ?? 0.0;

        total += price * item['quantity'];
        extractedBranch =
            item['menuItem']['branch']['id'];
      }

      setState(() {
        cartItems = items;
        itemsTotal = total;
        branchId = extractedBranch;
      });

      // If cart contains a branch, select it and fetch its tables.
      if (extractedBranch != null) {
        selectedBranchId = extractedBranch;
        await fetchTables(extractedBranch);
      }

    } catch (e) {
      debugPrint("Cart error: $e");
    }

    // isLoading is finalized by the caller (loadInitialData)
  }

  /// =========================
  /// FETCH TABLES
  /// =========================
  Future<void> fetchTables(int branchId) async {
    try {
      final response =
          await ApiService.get("/tables?branch_id=$branchId");

      setState(() {
        tables = response['data'];
      });

    } catch (e) {
      debugPrint("Tables error: $e");
    }
  }

  /// =========================
  /// FILTER TABLES
  /// =========================
  List get availableTables {
    return tables.where((table) {
      return table['seat_capacity'] >= guestCount;
    }).toList();
  }

  /// =========================
  /// SUBMIT RESERVATION
  /// =========================
  Future<void> submitReservation() async {

    if (selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a branch")),
      );
      return;
    }

    if (selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a table")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final payload = {
      "branch_id": selectedBranchId,
      "table_id": selectedTableId,
      "reservation_date": selectedDate.toIso8601String().split("T")[0],
      "reservation_time": selectedTime.substring(0, 5),
      "number_of_people": guestCount,
      // include both items_total and total_amount to match API expectations
      "items_total": itemsTotal,
      "total_amount": effectiveItemsTotal,
      // deposit for booking-only can be same as effective total (backend may use it)
      "deposit_amount": cartItems.isEmpty ? effectiveItemsTotal : 0.0,
      "booking_type": cartItems.isEmpty ? "booking_only" : "order",
      "special_requests": remarksController.text,
    };

    debugPrint("Reservation payload: $payload");

    try {
      final response = await ApiService.post("/reservations", payload);
      debugPrint("Reservation response: $response");

      if (response is Map && response['success'] == true) {
        final data = response['data'];

        if (data['payment_required'] == true) {
          final payment = data['payment'];
          final reservation = data['reservation'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservationQRPaymentScreen(
                qrString: payment['qr'],
                md5: payment['md5'],
                reservationId: reservation['id'],
                depositAmount: payment['deposit_amount'].toString(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reservation confirmed!")),
          );
          Navigator.pop(context);
        }
      } else {
        // show API-provided message if available
        final message = (response is Map && response['message'] != null)
            ? response['message'].toString()
            : "Failed to create reservation";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

    } catch (e) {
      debugPrint("Reservation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create reservation")),
      );
    }

    setState(() => isSubmitting = false);
  }

  /// =========================
  /// UI
  /// =========================
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
        title: const Text("Start your Booking"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// Branch
            const Text("Select Branch"),
           DropdownButtonFormField<int>(
  value: selectedBranchId,
  hint: const Text("Choose Branch"),
  items: branches.map<DropdownMenuItem<int>>((branch) {
    return DropdownMenuItem<int>(
      value: branch['id'],
      child: Text(branch['branch_name']),
    );
  }).toList(),
  onChanged: (value) async {
    setState(() {
      selectedBranchId = value;
      selectedTableId = null;
      tables = []; // reset table list
    });

    if (value != null) {
      await fetchTables(value);
    }
  },
),

            const SizedBox(height: 20),

            /// Guests
            const Text("Number of Guests"),
            Row(
              children: [
                IconButton(
                  onPressed: guestCount > 1
                      ? () {
                          setState(() {
                            guestCount--;
                            selectedTableId = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  guestCount.toString(),
                  style:
                      const TextStyle(fontSize: 18),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      guestCount++;
                      selectedTableId = null;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Date
            const Text("Select Date"),
            ElevatedButton(
              onPressed: () async {
                final date =
                    await showDatePicker(
                  context: context,
                  initialDate:
                      selectedDate,
                  firstDate:
                      DateTime.now(),
                  lastDate:
                      DateTime(2030),
                );

                if (date != null) {
                  setState(() =>
                      selectedDate =
                          date);
                }
              },
              child: Text(selectedDate
                  .toIso8601String()
                  .split("T")[0]),
            ),

            const SizedBox(height: 20),

            /// Time
            const Text("Select Time"),
            DropdownButton<String>(
              value: selectedTime,
              items: const [
                DropdownMenuItem(
                    value: "12:00",
                    child: Text("12:00 PM")),
                DropdownMenuItem(
                    value: "18:00",
                    child: Text("06:00 PM")),
              ],
              onChanged: (value) =>
                  setState(() =>
                      selectedTime =
                          value!),
            ),

            const SizedBox(height: 20),

            /// Table
            const Text("Select Table"),
            if (availableTables.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No tables available for the selected branch."),
              )
            else
              DropdownButtonFormField<int>(
                value: selectedTableId,
                hint: const Text("Choose Table"),
                items: availableTables
                    .map<DropdownMenuItem<int>>(
                        (table) {
                  return DropdownMenuItem<int>(
                    value: table['id'],
                    child: Text(
                      "${table['table_number']} (${table['seat_capacity']} seats)",
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTableId = value;
                  });
                },
              ),

            const SizedBox(height: 20),

            /// Special Request
            const Text("Special Requests"),
            TextField(
              controller:
                  remarksController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// Cart Section
            const Text(
              "Your Order",
              style: TextStyle(
                  fontWeight:
                      FontWeight.bold),
            ),

            if (cartItems.isEmpty) ...[
              const Text("No items selected"),
              const SizedBox(height: 8),
              const Text(
                "Note: A booking-only fee of \$2.50 will be charged if you don't order food.",
                style: TextStyle(color: Colors.black54),
              ),
            ] else
  Column(
    children: cartItems.map((item) {
      final menu = item['menuItem'];
      final qty = item['quantity'];
      final price =
          double.tryParse(menu['price'].toString()) ?? 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            /// Item Name
            Expanded(
              child: Text(
                menu['name'],
                style: const TextStyle(fontSize: 16),
              ),
            ),

            /// Quantity Controls
            Row(
              children: [

                /// Minus
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    if (qty > 1) {
                      await ApiService.post("/cart/update", {
                        "menu_item_id": menu['id'],
                        "quantity": qty - 1,
                      });
                    } else {
                      await ApiService.delete(
                          "/cart/remove/${menu['id']}");
                    }

                    fetchCart(); // refresh
                  },
                ),

                Text(
                  qty.toString(),
                  style: const TextStyle(fontSize: 16),
                ),

                /// Plus
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await ApiService.post("/cart/update", {
                      "menu_item_id": menu['id'],
                      "quantity": qty + 1,
                    });

                    fetchCart(); // refresh
                  },
                ),
              ],
            ),

            /// Price
            Text(
              "\$${(price * qty).toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  ),

            const SizedBox(height: 20),

            Text(
              cartItems.isEmpty
                  ? "Items Total: \$${effectiveItemsTotal.toStringAsFixed(2)} (booking-only fee)"
                  : "Items Total: \$${effectiveItemsTotal.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isSubmitting
                        ? null
                        : submitReservation,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.green,
                ),
                child: isSubmitting
                  ? const CircularProgressIndicator(
                    color: Colors.white,
                    )
                  : Text(cartItems.isEmpty ? "Reserve" : "Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}