import 'package:flutter/material.dart';

import 'menu/staff_menu_screen.dart';
import 'scanner/qr_scanner_screen.dart';
import 'reservations/staff_reservations_screen.dart';
import 'orders/staff_online_orders_screen.dart';
import 'profile/staff_profile_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int selectedIndex = 0;

  static const Color teal = Color(0xFF008F99);

  final List<Widget> pages = const [
    StaffMenuScreen(),
    QRScannerScreen(),
    StaffReservationsScreen(),
    StaffOnlineOrdersScreen(),
    StaffProfileScreen(),
  ];

  final List<IconData> _mainIcons = const [
    Icons.grid_view_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.table_restaurant_rounded,
    Icons.receipt_long_rounded,
  ];

  void onTap(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfileSelected = selectedIndex == 4;

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _mainIcons.length,
                      (index) => _buildNavItem(index),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onTap(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: teal,
                    shape: BoxShape.circle,
                    border: isProfileSelected
                        ? Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: teal.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isProfileSelected
                            ? Colors.white.withOpacity(0.25)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      );
  }

  Widget _buildNavItem(int index) {
    final bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          _mainIcons[index],
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}