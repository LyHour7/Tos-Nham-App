import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../reservation/reservation_qr_payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  int guestCount = 1;
  DateTime selectedDate = DateTime.now();
  String selectedTime = "09:00";

  final TextEditingController remarksController = TextEditingController();

  List cartItems = [];
  List tables = [];
  List branches = [];

  double itemsTotal = 0;

  double get effectiveItemsTotal => cartItems.isEmpty ? 2.5 : itemsTotal;

  int? branchId;
  int? selectedBranchId;
  int? selectedTableId;

  bool isLoading = true;
  bool isSubmitting = false;

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  // Available time slots
  final List<String> timeSlots = [
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
  ];

  // Seat capacity filter options
  final List<int> seatOptions = [2, 4, 6, 8, 10];
  int? selectedSeatFilter;

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

  Future<void> fetchBranches() async {
    try {
      final response = await ApiService.get("/branches");
      setState(() {
        branches = response['data']['branches'];
      });
      if (selectedBranchId == null && branches.isNotEmpty) {
        selectedBranchId = branches.first['id'];
        await fetchTables(selectedBranchId!);
      }
    } catch (e) {
      debugPrint("Branch error: $e");
    }
  }

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
        extractedBranch = item['menuItem']['branch']['id'];
      }

      setState(() {
        cartItems = items;
        itemsTotal = total;
        branchId = extractedBranch;
      });

      if (extractedBranch != null) {
        selectedBranchId = extractedBranch;
        await fetchTables(extractedBranch);
      }
    } catch (e) {
      debugPrint("Cart error: $e");
    }
  }

  Future<void> fetchTables(int branchId) async {
    try {
      final response = await ApiService.get("/tables?branch_id=$branchId");
      setState(() {
        tables = response['data'];
      });
    } catch (e) {
      debugPrint("Tables error: $e");
    }
  }

  List get availableTables {
    return tables.where((table) {
      return table['seat_capacity'] >= guestCount;
    }).toList();
  }

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
      "special_requests": remarksController.text,
      "booking_type": cartItems.isEmpty ? "TABLE_ONLY" : "WITH_FOOD",
    };

    if (cartItems.isNotEmpty) {
      payload["items"] = cartItems.map((item) {
        return {
          "menu_id": item['menuItem']['id'],
          "quantity": item['quantity']
        };
      }).toList();
    }

    try {
      final response = await ApiService.post("/reservations", payload);

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

  // Helper: section label with icon
  Widget _sectionLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF009688), size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF333333),
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
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// ============================
          /// HEADER (overlapping logo style)
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
                    left: 52,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF008F99)),
                  child: const Text(
                    "Start your Booking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                        errorBuilder: (_, __, ___) => const Icon(
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
const SizedBox(height: 10),
          /// ============================
          /// SCROLLABLE BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// BRANCH DROPDOWN
                  _sectionLabel(Icons.storefront_outlined, "Choose Branch"),
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white,
                    ),
                    child: DropdownButtonFormField<int>(
                      value: selectedBranchId,
                      isExpanded: true,
                      menuMaxHeight: 260,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Select branch",
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
                            color: const Color(0xFF009688).withOpacity(0.35),
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
                      items: branches.map<DropdownMenuItem<int>>((branch) {
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
                      onChanged: (value) async {
                        setState(() {
                          selectedBranchId = value;
                          selectedTableId = null;
                          tables = [];
                        });
                        if (value != null) await fetchTables(value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// NUMBER OF GUESTS
                  _sectionLabel(Icons.people_outline, "Number of Guests"),
                  Row(
                    children: [
                      // Minus
                      GestureDetector(
                        onTap: guestCount > 1
                            ? () => setState(() {
                                  guestCount--;
                                  selectedTableId = null;
                                })
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: guestCount > 1
                                ? const Color(0xFF009688)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove,
                              color: Colors.white, size: 20),
                        ),
                      ),

                      // Count display
                      Container(
                        width: 60,
                        height: 36,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF009688).withOpacity(0.4)),
                        ),
                        child: Text(
                          guestCount.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ),

                      // Plus
                      GestureDetector(
                        onTap: () => setState(() {
                          guestCount++;
                          selectedTableId = null;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CHOOSE TIME
                  _sectionLabel(Icons.access_time, "Choose Time"),
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: timeSlots.length,
                      itemBuilder: (context, index) {
                        final time = timeSlots[index];
                        final isSelected = selectedTime == time;

                        // Format display
                        final hour = int.parse(time.split(":")[0]);
                        final ampm = hour < 12 ? "AM" : "PM";
                        final displayHour = hour <= 12 ? hour : hour - 12;
                        final displayTime = "$displayHour:00 $ampm";

                        return GestureDetector(
                          onTap: () => setState(() => selectedTime = time),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF009688)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF009688).withOpacity(0.5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              displayTime,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF009688),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SELECT DATE (calendar grid style)
                  _sectionLabel(Icons.calendar_today_outlined, "Select Date"),
                  _buildDateGrid(),

                  const SizedBox(height: 20),

                  /// CHOOSE TABLE
                  _sectionLabel(
                      Icons.table_restaurant_outlined, "Choose Table"),

                  // Seat filter chips
                  Wrap(
                    spacing: 8,
                    children: seatOptions.map((seats) {
                      final isSelected = selectedSeatFilter == seats;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSeatFilter = isSelected ? null : seats;
                            selectedTableId = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF009688)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF009688).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            "$seats Seats",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF009688),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Table qty selector (after filter)
                  if (availableTables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "No tables available for the selected branch.",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          onTap: selectedTableId != null
                              ? () => setState(() => selectedTableId = null)
                              : null,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF009688),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 34,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFF009688).withOpacity(0.4)),
                          ),
                          child: Text(
                            selectedTableId != null
                                ? availableTables
                                    .indexWhere(
                                        (t) => t['id'] == selectedTableId)
                                    .toString()
                                    .padLeft(2, '0')
                                : "01",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF009688),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (availableTables.isNotEmpty) {
                              final nextIndex = selectedTableId == null
                                  ? 0
                                  : (availableTables.indexWhere((t) =>
                                              t['id'] == selectedTableId) +
                                          1) %
                                      availableTables.length;
                              setState(() => selectedTableId =
                                  availableTables[nextIndex]['id']);
                            }
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF009688),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  /// REMARKS
                  const Text(
                    "Remarks",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF009688).withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// YOUR ORDER
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF009688).withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: Color(0xFF009688), width: 4),
                            ),
                          ),
                          child: const Text(
                            "Your order",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),

                        if (cartItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("No items selected"),
                                const SizedBox(height: 6),
                                Text(
                                  "Note: A booking-only fee of \$2.50 will be charged.",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        else
                          ...cartItems.map((item) {
                            final menu = item['menuItem'];
                            final qty = item['quantity'];
                            final price =
                                double.tryParse(menu['price'].toString()) ??
                                    0.0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu['name'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        // Quantity controls
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: qty > 1
                                                  ? () => setState(() {
                                                        item['quantity']--;
                                                        itemsTotal -= price;
                                                      })
                                                  : null,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: qty > 1
                                                      ? const Color(0xFF009688)
                                                      : Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.remove,
                                                    color: Colors.white,
                                                    size: 14),
                                              ),
                                            ),
                                            Container(
                                              width: 32,
                                              height: 24,
                                              alignment: Alignment.center,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                qty.toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                item['quantity']++;
                                                itemsTotal += price;
                                              }),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF009688),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.add,
                                                    color: Colors.white,
                                                    size: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// TOTAL + PAYMENT BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Total: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        "\$${effectiveItemsTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitReservation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  cartItems.isEmpty ? "Reserve" : "Payment",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

  /// DATE GRID WIDGET
  Widget _buildDateGrid() {
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = selectedDate.year == day.year &&
            selectedDate.month == day.month &&
            selectedDate.day == day.day;
        final isToday = today.year == day.year &&
            today.month == day.month &&
            today.day == day.day;

        return GestureDetector(
          onTap: () => setState(() => selectedDate = day),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF009688) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF009688)
                    : const Color(0xFF009688).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isToday ? "Today" : "",
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
                Text(
                  day.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  monthNames[day.month],
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
