import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/reservation_service.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  late Map<String, dynamic> currentReservation;
  bool isUpdating = false;

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  final List<String> availableStatuses = [
    'Pending Payment',
    'Confirmed',
    'Arrived',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    currentReservation = Map<String, dynamic>.from(widget.reservation);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isUpdating = true);

    final success = await ReservationService.updateReservationStatus(
      currentReservation['id'],
      newStatus,
    );

    if (!mounted) return;
    setState(() => isUpdating = false);

    if (success) {
      setState(() => currentReservation['status'] = newStatus);
      _showSnack('Status updated to $newStatus', Colors.green);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.update, size: 16, color: tealDark),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Update Reservation Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Current: ${currentReservation['status'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...availableStatuses.map((status) {
                final isCurrent = status == currentReservation['status'];
                final color = _getStatusColor(status);
                return GestureDetector(
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(context);
                          _updateStatus(status);
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? color.withOpacity(0.1)
                          : color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? color : color.withOpacity(0.25),
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(status), color: color, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Icon(Icons.check_circle, color: color, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending Payment':
        return Icons.payment;
      case 'Confirmed':
        return Icons.check_circle_outline;
      case 'Arrived':
        return Icons.person_pin_circle;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
      case 'pending payment':
        return Colors.orange;
      case 'arrived':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return teal;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $ampm';
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentReservation['user'] ?? {};
    final branch = currentReservation['branch'] ?? {};
    final order = currentReservation['order'] ?? {};
    final orderItems = order['orderItems'] ?? [];
    final status = currentReservation['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// ============================
          /// HEADER — overlapping logo style
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
                  decoration: const BoxDecoration(color: teal),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Reservation Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
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
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.event_note, color: teal, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          /// ============================
          /// SCROLLABLE BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ID + STATUS + UPDATE CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: teal.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ID block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reservation ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${currentReservation['id']}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: tealDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status + Update
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    size: 13,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Update button
                            GestureDetector(
                              onTap: isUpdating ? null : _showStatusBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: teal,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: teal.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isUpdating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        children: [
                                          Icon(Icons.update,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 5),
                                          Text(
                                            'Update',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// CUSTOMER INFO
                  _buildSection(
                    icon: Icons.person_outline,
                    title: 'Customer Information',
                    children: [
                      _buildRow('Name', user['name'] ?? 'N/A'),
                      _buildRow('Email', user['email'] ?? 'N/A'),
                      _buildRow('Phone', user['phone'] ?? 'N/A'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// RESERVATION INFO
                  _buildSection(
                    icon: Icons.calendar_today_outlined,
                    title: 'Reservation Details',
                    children: [
                      _buildRow('Date',
                          formatDate(currentReservation['reservation_date'])),
                      _buildRow('Time',
                          formatTime(currentReservation['reservation_time'])),
                      _buildRow('Guests',
                          '${currentReservation['number_of_people'] ?? 0} people'),
                      _buildRow('Booking Type',
                          currentReservation['booking_type'] ?? 'N/A'),
                      _buildRow('Branch', branch['branch_name'] ?? 'N/A'),
                      _buildRow('Table',
                          '#${currentReservation['table_id'] ?? 'N/A'}'),
                      if (currentReservation['special_requests'] != null &&
                          currentReservation['special_requests']
                              .toString()
                              .isNotEmpty)
                        _buildRow(
                          'Special Requests',
                          currentReservation['special_requests'],
                          isHighlight: true,
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// PAYMENT INFO
                  _buildSection(
                    icon: Icons.payments_outlined,
                    title: 'Payment Information',
                    children: [
                      _buildRow(
                        'Total Amount',
                        '\$${currentReservation['total_amount'] ?? '0.00'}',
                        valueStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      _buildRow(
                        'Deposit Amount',
                        '\$${currentReservation['deposit_amount'] ?? '0.00'}',
                      ),
                      _buildRow(
                          'Payment Method', order['payment_method'] ?? 'N/A'),
                      _buildRow(
                          'Payment Status', order['payment_status'] ?? 'N/A',
                          isHighlight: (order['payment_status'] ?? '')
                                  .toString()
                                  .toLowerCase() ==
                              'paid'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// ORDER ITEMS (WITH_FOOD)
                  if (currentReservation['booking_type'] == 'WITH_FOOD')
                    _buildSection(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Order Items',
                      children: orderItems.isEmpty
                          ? [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'No items in this order',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            ]
                          : orderItems.map<Widget>((item) {
                              final menuItem = item['menuItem'] ?? {};
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: teal.withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    // Qty badge
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: tealLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '×${item['quantity'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: tealDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        menuItem['name'] ?? 'Unknown Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${item['price'] ?? '0.00'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),

                  if (currentReservation['booking_type'] == 'WITH_FOOD')
                    const SizedBox(height: 14),

                  /// QR INFO
                  _buildSection(
                    icon: Icons.qr_code_outlined,
                    title: 'QR Code Information',
                    children: [
                      _buildRow(
                        'QR Generated',
                        currentReservation['qr_generated_at'] != null
                            ? formatDate(currentReservation['qr_generated_at'])
                            : 'Not Generated',
                      ),
                      _buildRow(
                        'QR Status',
                        currentReservation['qr_used'] == true
                            ? 'Used'
                            : 'Not Used',
                        isHighlight: currentReservation['qr_used'] == true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// TIMESTAMPS
                  _buildSection(
                    icon: Icons.access_time_outlined,
                    title: 'Timestamps',
                    children: [
                      _buildRow('Created At',
                          formatDate(currentReservation['createdAt'])),
                      _buildRow('Updated At',
                          formatDate(currentReservation['updatedAt'])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section card with tealLight header strip
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: tealDark, size: 15),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: tealDark,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// Label + value row
  Widget _buildRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isHighlight ? teal : const Color(0xFF1A1A1A),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
