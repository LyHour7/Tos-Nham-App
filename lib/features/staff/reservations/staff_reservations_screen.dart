import 'package:flutter/material.dart';
import '../../../core/services/reservation_service.dart';
import 'reservation_detail_screen.dart';

class StaffReservationsScreen extends StatefulWidget {
  const StaffReservationsScreen({super.key});

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen> {
  List<dynamic> reservations = [];
  bool isLoading = true;
  String errorMessage = '';
  String _filterStatus = 'all';

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  final List<String> _filters = ['all', 'pending', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await ReservationService.getAllReservations();
      if (!mounted) return;
      setState(() {
        reservations = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load reservations: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int reservationId, String newStatus) async {
    final success = await ReservationService.updateReservationStatus(
        reservationId, newStatus);
    if (!mounted) return;

    if (success) {
      _showSnack('Status updated to $newStatus',
          newStatus == 'completed' ? Colors.green : Colors.red);
      _fetchReservations();
    } else {
      _showSnack('Failed to update status', Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStatusBottomSheet(int reservationId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Reservation Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: $currentStatus',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              _statusOption(
                label: 'Mark as Completed',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(reservationId, 'completed');
                },
              ),
              const SizedBox(height: 10),
              _statusOption(
                label: 'Mark as Cancelled',
                icon: Icons.cancel_outlined,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(reservationId, 'cancelled');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOption({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _filteredReservations {
    if (_filterStatus == 'all') return reservations;
    return reservations
        .where((r) =>
            (r['status'] ?? 'pending').toString().toLowerCase() ==
            _filterStatus)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return teal;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.event_available;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            /// ============================
            /// HEADER
            /// ============================
            Container(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(left: 36),
                    padding: const EdgeInsets.only(
                        left: 52, right: 16, top: 14, bottom: 14),
                    decoration: const BoxDecoration(color: teal),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Reservations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isLoading && errorMessage.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${reservations.length} total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                            Icons.event_note,
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

            /// ============================
            /// BODY
            /// ============================
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: teal, strokeWidth: 2.5))
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : reservations.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: [
                                /// FILTER CHIPS + STATS
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 14, 16, 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Stat chips row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _filters.map((f) {
                                            final count = f == 'all'
                                                ? reservations.length
                                                : reservations
                                                    .where((r) =>
                                                        (r['status'] ??
                                                                'pending')
                                                            .toString()
                                                            .toLowerCase() ==
                                                        f)
                                                    .length;
                                            final isSelected =
                                                _filterStatus == f;
                                            final color = f == 'all'
                                                ? teal
                                                : f == 'completed'
                                                    ? Colors.green
                                                    : f == 'cancelled'
                                                        ? Colors.red
                                                        : Colors.orange;

                                            return GestureDetector(
                                              onTap: () => setState(
                                                  () => _filterStatus = f),
                                              child: Container(
                                                margin: const EdgeInsets
                                                    .only(right: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? color
                                                      : color.withOpacity(
                                                          0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? color
                                                        : color.withOpacity(
                                                            0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      '${f[0].toUpperCase()}${f.substring(1)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : color,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 6,
                                                              vertical: 1),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: isSelected
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.3)
                                                            : color
                                                                .withOpacity(
                                                                    0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        '$count',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : color,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                /// LIST
                                Expanded(
                                  child: RefreshIndicator(
                                    color: teal,
                                    onRefresh: _fetchReservations,
                                    child: _filteredReservations.isEmpty
                                        ? ListView(
                                            children: [
                                              SizedBox(
                                                height: 200,
                                                child: Center(
                                                  child: Text(
                                                    'No $_filterStatus reservations',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ListView.builder(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                                    16, 4, 16, 20),
                                            itemCount:
                                                _filteredReservations.length,
                                            itemBuilder: (context, index) {
                                              return _buildReservationCard(
                                                  _filteredReservations[
                                                      index]);
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(dynamic reservation) {
    final status =
        (reservation['status'] ?? 'pending').toString().toLowerCase();
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);
    final customerName = reservation['user']?['name'] ??
        reservation['customer_name'] ??
        'N/A';
    final date = reservation['reservation_date'] ?? 'N/A';
    final time = reservation['reservation_time'] ?? 'N/A';
    final guests = (reservation['number_of_people'] ??
            reservation['number_of_guests'] ??
            'N/A')
        .toString();
    final id = reservation['id'].toString();
    final deposit = reservation['deposit_amount']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReservationDetailScreen(reservation: reservation),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: teal.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // TOP ROW — id + status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tealLight.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$id',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: tealDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Customer name
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: statusColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '${status[0].toUpperCase()}${status.substring(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DETAIL ROWS
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today_outlined, date, teal),
                      const SizedBox(width: 8),
                      _infoChip(Icons.access_time_outlined, time, teal),
                      const SizedBox(width: 8),
                      _infoChip(Icons.people_outline, '$guests guests',
                          Colors.blueGrey),
                    ],
                  ),

                  if (deposit != null && deposit.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoChip(Icons.payments_outlined, 'Deposit: \$$deposit',
                            Colors.green),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Action row
                  Row(
                    children: [
                      // Update status button (only if not terminal)
                      if (status != 'completed' && status != 'cancelled')
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showStatusBottomSheet(
                                reservation['id'], status),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: teal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.update,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Update Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (status != 'completed' && status != 'cancelled')
                        const SizedBox(width: 8),
                      // View details button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReservationDetailScreen(
                                    reservation: reservation),
                              ),
                            );
                          },
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: teal.withOpacity(0.45)),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    color: teal, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
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
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchReservations,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note, size: 48, color: teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Reservations Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New reservations from customers will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}