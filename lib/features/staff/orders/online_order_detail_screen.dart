import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';

class OnlineOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OnlineOrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OnlineOrderDetailScreen> createState() =>
      _OnlineOrderDetailScreenState();
}

class _OnlineOrderDetailScreenState extends State<OnlineOrderDetailScreen> {
  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  late Map<String, dynamic> currentOrder;
  bool isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    currentOrder = Map<String, dynamic>.from(widget.order);
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    try {
      final orderId = currentOrder['id'];
      if (orderId == null) {
        setState(() => isLoadingDetail = false);
        return;
      }

      final response = await ApiService.get('/orders');
      final orders = response['data']?['orders'];

      if (orders is List) {
        for (final item in orders) {
          if (item is Map && item['id'] == orderId) {
            setState(() {
              currentOrder = {
                ...currentOrder,
                ...Map<String, dynamic>.from(item),
              };
            });
            break;
          }
        }
      }
    } catch (_) {
      // Keep using passed-in order on failure
    } finally {
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(value).toLocal();
      return DateFormat('MMM dd, yyyy  hh:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
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
    switch ((status ?? '').toLowerCase()) {
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

  String _pickText(List<dynamic> values, {String fallback = 'N/A'}) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty && t.toLowerCase() != 'null') return t;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final order = currentOrder;
    final user = (order['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final branch = (order['branch'] as Map?)?.cast<String, dynamic>() ?? {};
    final items = (order['orderItems'] as List?) ?? [];

    final status = order['order_status']?.toString();
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);
    final paymentStatus = order['payment_status']?.toString() ?? 'N/A';

    final customerName = _pickText(
        [user['name'], order['customer_name'], order['delivery_name']]);
    final customerEmail =
        _pickText([user['email'], order['customer_email'], order['email']]);
    final customerPhone =
        _pickText([user['phone'], order['delivery_phone'], order['phone']]);
    final branchName = _pickText([
      branch['branch_name'],
      branch['name'],
      order['branch_name'],
    ]);

    final lat = order['delivery_lat']?.toString();
    final lng = order['delivery_lng']?.toString();
    final coordinate =
        (lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty)
            ? '$lat, $lng'
            : 'N/A';

    final paymentMethod =
        _pickText([order['payment_method']]).replaceAll('_', ' ');
    final notes = _pickText(
        [order['notes'], order['note'], order['special_instructions']],
        fallback: '-');

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
                      Expanded(
                        child: Text(
                          'Order #${order['id'] ?? 'N/A'}',
                          style: const TextStyle(
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
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.receipt_long,
                            color: teal,
                            size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// ============================
          /// BODY
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Loading bar
                  if (isLoadingDetail) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        color: teal,
                        backgroundColor: tealLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  /// STATUS SUMMARY CARD
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
                      children: [
                        // Order ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '#${order['id'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: tealDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status + payment status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Order status badge
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
                                  Icon(statusIcon,
                                      size: 13, color: statusColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    status != null
                                        ? '${status[0].toUpperCase()}${status.substring(1)}'
                                        : 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Payment status chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (paymentStatus.toLowerCase() == 'paid'
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (paymentStatus.toLowerCase() == 'paid'
                                          ? Colors.green
                                          : Colors.orange)
                                      .withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 11,
                                    color: paymentStatus.toLowerCase() == 'paid'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    paymentStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          paymentStatus.toLowerCase() == 'paid'
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// CUSTOMER INFO
                  _section(
                    icon: Icons.person_outline,
                    title: 'Customer Information',
                    children: [
                      _row('Name', customerName),
                      _row('Email', customerEmail),
                      _row('Phone', customerPhone),
                    ],
                  ),

                  /// ORDER INFO
                  _section(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order Information',
                    children: [
                      _row('Branch', branchName),
                      _row('Order Type',
                          order['order_type']?.toString() ?? 'N/A'),
                      _row('Payment Method', paymentMethod),
                      _row(
                        'Total Amount',
                        '\$${order['total_amount'] ?? '0.00'}',
                        valueStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _row('Created',
                          _formatDateTime(order['createdAt']?.toString())),
                      _row('Updated',
                          _formatDateTime(order['updatedAt']?.toString())),
                    ],
                  ),

                  /// DELIVERY INFO
                  _section(
                    icon: Icons.delivery_dining_outlined,
                    title: 'Delivery Information',
                    children: [
                      _row('Receiver',
                          _pickText([order['delivery_name'], customerName])),
                      _row('Phone',
                          _pickText([order['delivery_phone'], customerPhone])),
                      _row('Address', _pickText([order['delivery_address']])),
                      _row('Coordinates', coordinate),
                      if (notes != '-') _row('Notes', notes),
                    ],
                  ),

                  /// ORDER ITEMS
                  _section(
                    icon: Icons.fastfood_outlined,
                    title: 'Order Items (${items.length})',
                    children: items.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  'No items found',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ]
                        : [
                            ...items.map((item) {
                              final menuItem = (item['menuItem'] as Map?)
                                      ?.cast<String, dynamic>() ??
                                  {};
                              final hasNote = item['special_instructions']
                                      ?.toString()
                                      .isNotEmpty ??
                                  false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: teal.withOpacity(0.12)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Qty badge
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: tealLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                            menuItem['name']?.toString() ??
                                                'Unknown Item',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                        // Subtotal
                                        Text(
                                          '\$${item['subtotal'] ?? item['price'] ?? '0.00'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Unit price
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 40, top: 4),
                                      child: Text(
                                        'Unit price: \$${item['price'] ?? '0.00'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                    if (hasNote) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.amber
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.note_alt_outlined,
                                                size: 13, color: Colors.amber),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item['special_instructions']
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade700,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),

                            // Order total footer
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: tealLight.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order Total',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    '\$${order['total_amount'] ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: tealDark, size: 14),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: tealDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// Label + value row
  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
