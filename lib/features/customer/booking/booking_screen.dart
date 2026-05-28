import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/auth_guard.dart';
import '../branch/branch_detail_screen.dart';
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
  final Set<int> selectedMenuItemIds = {};

  double get selectedItemsTotal {
    return selectedCartItems.fold(0.0, (sum, item) {
      final price =
          double.tryParse(item['menuItem']['price'].toString()) ?? 0.0;
      return sum + (price * item['quantity']);
    });
  }

  /// Effective items to send to the reservation API.
  /// Use explicitly selected items when present, otherwise fall back
  /// to all cart items for the selected branch so the deposit calculation
  /// doesn't collapse to the booking-only minimum after navigation.
  List get effectiveSelectedItems {
    final sel = selectedCartItems;
    if (sel.isNotEmpty) return sel;
    // If the user explicitly toggled selection (deselected all items),
    // treat as booking-only (no items) so deposit becomes the flat fee.
    if (selectionTouched) return [];
    return selectedBranchCartItems;
  }

  double get effectiveItemsTotal {
    return effectiveSelectedItems.fold(0.0, (sum, item) {
      final price =
          double.tryParse(item['menuItem']['price'].toString()) ?? 0.0;
      return sum + (price * item['quantity']);
    });
  }

  double get reservationChargeAmount {
    if (effectiveSelectedItems.isEmpty) {
      return 2.5;
    }

    return effectiveItemsTotal * 0.5;
  }

  String get reservationChargeLabel {
    if (effectiveSelectedItems.isEmpty) {
      return 'Booking fee';
    }

    return 'Food deposit (50%)';
  }

  int? selectedBranchId;
  int? selectedTableId;
  bool selectionTouched = false;

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

      setState(() {
        cartItems = items;
        selectedMenuItemIds
          ..clear()
          ..addAll(items.map(_menuItemId).whereType<int>());
      });
    } catch (e) {
      debugPrint("Cart error: $e");
    }
  }

  Future<void> fetchTables(int branchId) async {
    try {
      final response = await ApiService.get("/tables?branch_id=$branchId");
      final rawTables = response['data'];
      final normalizedTables = rawTables is Map
          ? (rawTables['tables'] ?? rawTables['data'] ?? [])
          : rawTables;

      setState(() {
        tables = (normalizedTables as List? ?? [])
            .whereType<Map>()
            .map((table) => Map<String, dynamic>.from(table))
            .toList()
          ..sort((left, right) {
            final leftLabel = _tableDisplayLabel(left);
            final rightLabel = _tableDisplayLabel(right);
            return leftLabel.compareTo(rightLabel);
          });
        _syncSelectedTableWithAvailableTables(preferFirst: true);
      });
    } catch (e) {
      debugPrint("Tables error: $e");
    }
  }

  List get availableTables {
    return tables.where((table) {
      final seatCapacity = _tableSeatCapacity(table);
      final matchesGuestCount = seatCapacity >= guestCount;
      return matchesGuestCount;
    }).toList();
  }

  List get selectableTables {
    return availableTables
        .where((table) => _tableStatus(table) == 'available')
        .toList();
  }

  List get selectedBranchCartItems {
    if (selectedBranchId == null) return [];

    return cartItems
        .where((item) => _itemBranchId(item) == selectedBranchId)
        .toList();
  }

  int _tableSeatCapacity(dynamic table) {
    final seatCapacity = table['seat_capacity'];
    if (seatCapacity is int) return seatCapacity;
    return int.tryParse(seatCapacity?.toString() ?? '') ?? 0;
  }

  int? _itemBranchId(dynamic item) {
    final branch = item['menuItem']?['branch'];
    final branchId = branch?['id'];
    if (branchId is int) return branchId;
    return int.tryParse(branchId?.toString() ?? '');
  }

  String _selectedBranchName() {
    if (selectedBranchId == null) return 'this branch';

    for (final branch in branches) {
      if (branch['id'] == selectedBranchId) {
        return branch['branch_name']?.toString() ?? 'this branch';
      }
    }

    return 'this branch';
  }

  Future<void> _openBranchMenu() async {
    if (selectedBranchId == null) return;

    final allowed = await ensureLoggedIn(context);
    if (!allowed) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(
          branchId: selectedBranchId!,
          branchName: _selectedBranchName(),
        ),
      ),
    );

    if (!mounted) return;

    await fetchCart();
    setState(() {
      selectionTouched = false;
    });
  }

  String _tableStatus(dynamic table) {
    final status = table['status']?.toString().trim().toLowerCase();
    if (status == null || status.isEmpty) {
      return 'available';
    }
    return status;
  }

  String _tableDisplayLabel(dynamic table) {
    final candidates = [
      table['table_number'],
      table['table_no'],
      table['name'],
      table['code'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    final tableId = _tableId(table);
    return tableId != null ? 'T$tableId' : 'Table';
  }

  String _tableStatusLabel(dynamic table) {
    switch (_tableStatus(table)) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'occupied':
        return 'Occupied';
      case 'maintenance':
      case 'unavailable':
        return 'Unavailable';
      default:
        return 'Unknown';
    }
  }

  Color _tableStatusColor(dynamic table) {
    switch (_tableStatus(table)) {
      case 'available':
        return const Color(0xFF2EAD65);
      case 'reserved':
        return const Color(0xFFF0A500);
      case 'occupied':
        return const Color(0xFFE85D5D);
      case 'maintenance':
      case 'unavailable':
        return const Color(0xFF7A869A);
      default:
        return const Color(0xFF4D6B6B);
    }
  }

  Map<String, int> get tableStatusCounts {
    final counts = <String, int>{
      'available': 0,
      'reserved': 0,
      'occupied': 0,
      'unavailable': 0,
    };

    for (final table in availableTables) {
      final status = _tableStatus(table);
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      } else {
        counts['unavailable'] = counts['unavailable']! + 1;
      }
    }

    return counts;
  }

  int? _tableId(dynamic table) {
    final tableId = table['id'];
    if (tableId is int) return tableId;
    return int.tryParse(tableId?.toString() ?? '');
  }

  void _syncSelectedTableWithAvailableTables({bool preferFirst = false}) {
    final tableIds = selectableTables.map(_tableId).whereType<int>().toList();

    if (tableIds.isEmpty) {
      selectedTableId = null;
      return;
    }

    if (preferFirst ||
        selectedTableId == null ||
        !tableIds.contains(selectedTableId)) {
      selectedTableId = tableIds.first;
    }
  }

  String _selectedTableLabel() {
    if (selectedTableId == null) return '--';

    for (final table in selectableTables) {
      if (_tableId(table) == selectedTableId) {
        return _tableDisplayLabel(table);
      }
    }

    for (final table in availableTables) {
      if (_tableId(table) == selectedTableId) {
        return _tableDisplayLabel(table);
      }
    }

    return '--';
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List get selectedCartItems {
    return selectedBranchCartItems.where(_isCartItemSelected).toList();
  }

  int? _menuItemId(dynamic item) {
    final menuItemId = item['menuItem']?['id'];
    if (menuItemId is int) return menuItemId;
    return int.tryParse(menuItemId?.toString() ?? '');
  }

  bool _isCartItemSelected(dynamic item) {
    final menuItemId = _menuItemId(item);
    return menuItemId != null && selectedMenuItemIds.contains(menuItemId);
  }

  void _toggleCartItemSelection(dynamic item) {
    final menuItemId = _menuItemId(item);
    if (menuItemId == null) return;

    setState(() {
      if (selectedMenuItemIds.contains(menuItemId)) {
        selectedMenuItemIds.remove(menuItemId);
      } else {
        selectedMenuItemIds.add(menuItemId);
      }
      selectionTouched = true;
    });
  }

  Future<void> submitReservation() async {
    final allowed = await ensureLoggedIn(context);
    if (!allowed) return;

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

    final hasFoodItems = effectiveSelectedItems.isNotEmpty;
    final itemsTotal = hasFoodItems ? effectiveItemsTotal : 0.0;

    final payload = {
      "branch_id": selectedBranchId,
      "table_id": selectedTableId,
      "reservation_date": selectedDate.toIso8601String().split("T")[0],
      "reservation_time": selectedTime.substring(0, 5),
      "number_of_people": guestCount,
      "special_requests": remarksController.text,
      "booking_type": hasFoodItems ? "WITH_FOOD" : "TABLE_ONLY",
      "items_total": itemsTotal,
    };

    if (hasFoodItems) {
      payload["items"] = effectiveSelectedItems.map((item) {
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed:
                          selectedBranchId == null ? null : _openBranchMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon:
                          const Icon(Icons.restaurant_menu_outlined, size: 18),
                      label: const Text(
                        "Choose items from this branch",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
                                  _syncSelectedTableWithAvailableTables(
                                    preferFirst: true,
                                  );
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
                          _syncSelectedTableWithAvailableTables(
                            preferFirst: true,
                          );
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

                  Text(
                    "Tables are loaded from the selected branch. Tap an available table to book it.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(
                        'Available',
                        tableStatusCounts['available'] ?? 0,
                        const Color(0xFF2EAD65),
                      ),
                      _buildStatusChip(
                        'Reserved',
                        tableStatusCounts['reserved'] ?? 0,
                        const Color(0xFFF0A500),
                      ),
                      _buildStatusChip(
                        'Occupied',
                        tableStatusCounts['occupied'] ?? 0,
                        const Color(0xFFE85D5D),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (availableTables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "No tables match the current branch, guest count, or seat filter.",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availableTables.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, index) {
                        final table = availableTables[index];
                        final tableId = _tableId(table);
                        final status = _tableStatus(table);
                        final isSelected = selectedTableId == tableId;
                        final isSelectable = status == 'available';
                        final statusColor = _tableStatusColor(table);

                        return GestureDetector(
                          onTap: isSelectable && tableId != null
                              ? () => setState(() => selectedTableId = tableId)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF009688)
                                    : statusColor.withOpacity(0.25),
                                width: isSelected ? 1.8 : 1.0,
                              ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _tableDisplayLabel(table),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelectable
                                            ? const Color(0xFF1F2A2A)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF009688),
                                        size: 20,
                                      ),
                                  ],
                                ),
                                Text(
                                  '${_tableSeatCapacity(table)} seats',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    _tableStatusLabel(table),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!isSelectable)
                                  Text(
                                    'Not selectable',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),

                  Text(
                    selectedTableId == null
                        ? 'No table selected yet'
                        : 'Selected table: ${_selectedTableLabel()}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
                        else if (selectedBranchCartItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              "No items from this branch selected. Tap the button above to choose items for ${_selectedBranchName()}.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          ...selectedBranchCartItems.map((item) {
                            final menu = item['menuItem'];
                            final qty = item['quantity'];
                            final price =
                                double.tryParse(menu['price'].toString()) ??
                                    0.0;
                            final isSelected = _isCartItemSelected(item);

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
                                  GestureDetector(
                                    onTap: () => _toggleCartItemSelection(item),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      margin: const EdgeInsets.only(right: 10),
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
                                        size: 17,
                                      ),
                                    ),
                                  ),
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
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.red
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// TOTAL + PAYMENT BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "$reservationChargeLabel: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        "\$${reservationChargeAmount.toStringAsFixed(2)}",
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
                                  effectiveSelectedItems.isEmpty
                                      ? "Reserve"
                                      : "Payment",
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
