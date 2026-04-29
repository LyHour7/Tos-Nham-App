import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReservationDetailScreen extends StatelessWidget {

  final Map reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Reservation #${reservation['id']}"),
        backgroundColor: Color(0xFF008F99),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// Reservation Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Booking Details",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Text("Branch: ${reservation['branch'] != null ? reservation['branch']['branch_name'] : 'N/A'}"),
                  const SizedBox(height: 8),

                  Text("User: ${reservation['user'] != null ? reservation['user']['name'] ?? 'N/A' : 'N/A'}"),
                  const SizedBox(height: 8),

                  Text("Table: ${reservation['table'] != null ? '${reservation['table']['table_number']} (${reservation['table']['seat_capacity']} seats)' : 'Table #${reservation['table_id']}'}"),
                  const SizedBox(height: 8),

                  Text("Date: ${reservation['reservation_date']}"),
                  const SizedBox(height: 8),

                  Text("Time: ${reservation['reservation_time']}"),
                  const SizedBox(height: 8),

                  Text("Number of People: ${reservation['number_of_people']}"),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount:"),
                      Text(
                        "\$${reservation['total_amount']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Deposit Required:"),
                      Text(
                        "\$${reservation['deposit_amount']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Status:"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: reservation['status'] == 'Pending Payment'
                              ? Colors.orange[100]
                              : reservation['status'] == 'Confirmed'
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservation['status'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: reservation['status'] == 'Pending Payment'
                                ? Colors.orange[800]
                                : reservation['status'] == 'Confirmed'
                                    ? Colors.green[800]
                                    : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// QR Code Section for Staff Scanning
          if (reservation['qr_token'] != null)
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "QR Code for Check-in",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: reservation['qr_token'] ?? '',
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          /// Order Items if present
          if (reservation['order'] != null && reservation['order']['orderItems'] != null && reservation['order']['orderItems'].isNotEmpty)
            ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Order Items",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Name",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Qty",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Price",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Subtotal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          ...reservation['order']['orderItems'].map<TableRow>((item) {
                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(item['menuItem']['name']),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    item['quantity'].toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    "\$${item['price']}",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    "\$${item['subtotal']}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "No items ordered",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
