import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../../core/services/profile_service.dart';
import '../../../models/user_model.dart';
import 'online_order_detail_screen.dart';

class StaffOnlineOrdersScreen extends StatefulWidget {
  const StaffOnlineOrdersScreen({super.key});

  @override
  State<StaffOnlineOrdersScreen> createState() =>
      _StaffOnlineOrdersScreenState();
}

class _StaffOnlineOrdersScreenState extends State<StaffOnlineOrdersScreen> {
  late Future<List<dynamic>> _ordersFuture;
  String _filterStatus = 'all';

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  final List<String> _filters = [
    'all',
    'pending',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadBranchOrders();
  }

  Future<List<dynamic>> _loadBranchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) throw Exception('User not found');

      final user = User.fromJson(jsonDecode(userJson));
      if (user.branchId == null) {
        throw Exception('Staff member has no assigned branch');
      }

      return await ProfileService.getBranchOrders(user.branchId!);
    } catch (e) {
      throw Exception('Failed to load orders: ${e.toString()}');
    }
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _loadBranchOrders();
    });
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return teal;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'processing':
        return Icons.autorenew;
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
                    child: const Text(
                      'Branch Orders',
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
                            Icons.receipt_long,
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
              child: FutureBuilder<List<dynamic>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: teal, strokeWidth: 2.5),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final orders = snapshot.data!;
                  final filtered = _filterStatus == 'all'
                      ? orders
                      : orders
                          .where((o) =>
                              (o['order_status'] ?? '')
                                  .toString()
                                  .toLowerCase() ==
                              _filterStatus)
                          .toList();

                  return Column(
                    children: [
                      /// FILTER CHIPS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((f) {
                              final count = f == 'all'
                                  ? orders.length
                                  : orders
                                      .where((o) =>
                                          (o['order_status'] ?? '')
                                              .toString()
                                              .toLowerCase() ==
                                          f)
                                      .length;
                              final isSelected = _filterStatus == f;
                              final color = f == 'all'
                                  ? teal
                                  : _statusColor(f);

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _filterStatus = f),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : color.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${f[0].toUpperCase()}${f.substring(1)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : color,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                                  .withOpacity(0.3)
                                              : color.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
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
                      ),

                      /// LIST
                      Expanded(
                        child: RefreshIndicator(
                          color: teal,
                          onRefresh: () async => _refresh(),
                          child: filtered.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: Text(
                                          'No $_filterStatus orders',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 20),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildOrderCard(filtered[index]),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderItems = order['orderItems'] as List<dynamic>? ?? [];
    final status = order['order_status']?.toString();
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);
    final hasQR = order['bakong_md5'] != null ||
        (order['payment'] != null && order['payment']['qr'] != null);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineOrderDetailScreen(
              order: Map<String, dynamic>.from(order),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER STRIP — order id + status
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
                      '#${order['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: tealDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order['delivery_name'] ?? 'N/A',
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
                      border: Border.all(
                          color: statusColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status != null
                              ? '${status[0].toUpperCase()}${status.substring(1)}'
                              : 'Unknown',
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

            /// DETAIL SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Info chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(Icons.phone_outlined,
                          order['delivery_phone'] ?? 'N/A', Colors.blueGrey),
                      _infoChip(Icons.location_on_outlined,
                          order['delivery_address'] ?? 'N/A', Colors.deepOrange,
                          maxWidth: 160),
                      if (order['createdAt'] != null)
                        _infoChip(Icons.calendar_today_outlined,
                            _formatDate(order['createdAt']), Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// ORDER ITEMS
                  if (orderItems.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: tealLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.fastfood,
                              size: 13, color: tealDark),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Order Items (${orderItems.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...orderItems
                        .map((item) => _buildOrderItemRow(item))
                        .toList(),
                    const SizedBox(height: 8),
                    Divider(color: teal.withOpacity(0.12), height: 1),
                    const SizedBox(height: 8),
                  ],

                  /// TOTAL + PAYMENT
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                            Text(
                              '\$${order['total_amount'] ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Payment method badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: tealLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined,
                                size: 13, color: tealDark),
                            const SizedBox(width: 5),
                            Text(
                              (order['payment_method'] ?? 'N/A')
                                  .toString()
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tealDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// PAYMENT STATUS
                  if (order['payment_status'] != null) ...[
                    const SizedBox(height: 6),
                    _infoChip(
                      Icons.verified_outlined,
                      'Payment: ${order['payment_status']}',
                      order['payment_status'].toString().toLowerCase() ==
                              'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],

                  /// NOTES
                  if (order['notes'] != null &&
                      (order['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note_outlined,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['notes'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  /// ACTION BUTTONS
                  Row(
                    children: [
                      if (hasQR) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showQRBottomSheet(order),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: teal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'View QR',
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
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OnlineOrderDetailScreen(
                                  order:
                                      Map<String, dynamic>.from(order),
                                ),
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

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(dynamic item) {
    final name = item['menu_item']?['name'] ??
        'Item #${item['menu_item_id'] ?? 'N/A'}';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teal.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.circular(6),
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
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${item['subtotal'] ?? item['price'] ?? '0.00'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showQRBottomSheet(dynamic order) {
    final qrString =
        (order['payment'] != null && order['payment']['qr'] != null)
            ? order['payment']['qr']
            : (order['bakong_md5'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Bakong branding
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC1F27),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAKONG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFCC1F27),
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Scan. Pay. Done.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Order ID + amount
              Text(
                'Order #${order['id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${order['total_amount']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 16),

              // QR code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrString,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // QR string (monospace)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  qrString,
                  style: const TextStyle(
                    fontSize: 8,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Copy + Close buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: teal.withOpacity(0.4)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: qrString));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(children: [
                              Icon(Icons.check, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('QR copied to clipboard'),
                            ]),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: teal.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Copy QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _infoChip(IconData icon, String label, Color color,
      {double? maxWidth}) {
    return Container(
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              error,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
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
              child: const Icon(Icons.receipt_long, size: 48, color: teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Online orders from customers will appear here.',
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