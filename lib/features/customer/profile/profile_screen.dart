import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  List orders = [];
  List reservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      final profile = await ProfileService.getProfile();
      final orderData = await ProfileService.getOrders();
      final reservationData = await ProfileService.getReservations();

      setState(() {
        user = profile;
        orders = orderData;
        reservations = reservationData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Profile error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: loadProfileData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// USER INFO CARD
            _buildUserCard(),

            const SizedBox(height: 20),

            /// BOOKING HISTORY
            buildHistoryCard(
              title: "Booking History",
              count: reservations.length,
              onTap: showReservations,
            ),

            const SizedBox(height: 12),

            /// ONLINE ORDER HISTORY
            buildHistoryCard(
              title: "Online Order History",
              count: orders.length,
              onTap: showOrders,
            ),

            const SizedBox(height: 25),

            /// SETTINGS TITLE
            Text(
              "Settings",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Theme"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),

            const SizedBox(height: 30),

            /// LOGOUT BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text("Log out"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name'] ?? 'Unknown User',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(user?['email'] ?? ''),
                Text(
                  user?['role'] ?? 'Customer',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildHistoryCard({
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16)
              ],
            )
          ],
        ),
      ),
    );
  }

  void showOrders() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        if (orders.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text("No Orders Found")),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];

                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text("Order #${order['id']}"),
                  subtitle: Text(
                    "Total: \$${order['total_amount']}\n"
                    "Status: ${order['order_status']}\n"
                    "Payment: ${order['payment_status']}",
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void showReservations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        if (reservations.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text("No Reservations Found")),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: reservations.length,
              itemBuilder: (_, index) {
                final reservation = reservations[index];

                return ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text("Reservation #${reservation['id']}"),
                  subtitle: Text(
                    "${reservation['reservation_date']} "
                    "${reservation['reservation_time']}\n"
                    "Status: ${reservation['status']}",
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}