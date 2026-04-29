import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {

    final items = order['orderItems'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order['id']}"),
        backgroundColor: Color(0xFF008F99),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// ORDER INFO
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Branch: ${order['branch']['branch_name']}"),
                  const SizedBox(height: 5),

                  Text("Order Type: ${order['order_type']}"),
                  const SizedBox(height: 5),

                  Text("Payment Method: ${order['payment_method']}"),
                  const SizedBox(height: 5),

                  Text("Payment Status: ${order['payment_status']}"),
                  const SizedBox(height: 5),

                  Text("Order Status: ${order['order_status']}"),
                  const SizedBox(height: 5),

                  Text("Total: \$${order['total_amount']}"),

                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Items",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// ORDER ITEMS
          ...items.map<Widget>((item) {
            return Card(
              child: ListTile(
                title: Text(item['menuItem']['name']),
                subtitle: Text(
                  "Price: \$${item['price']}\n"
                  "Quantity: ${item['quantity']}",
                ),
                trailing: Text("\$${item['subtotal']}"),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}