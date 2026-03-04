import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../branch/all_branch_screen.dart';
import '../booking/booking_screen.dart';
import '../menu/cart_screen.dart';
import '../profile/profile_screen.dart';

class CustomerBottomNavBar extends StatefulWidget {
  const CustomerBottomNavBar({super.key});

  @override
  State<CustomerBottomNavBar> createState() =>
      _CustomerBottomNavBarState();
}

class _CustomerBottomNavBarState
    extends State<CustomerBottomNavBar> {

  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AllBranchScreen(),
    CartScreen(),
    BookingFormScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _navItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 20),
        child: Row(
          children: [

            /// 🔵 Main Nav Container
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(Icons.home, 0),
                    _navItem(Icons.store, 1),
                    _navItem(Icons.shopping_cart, 2),
                    _navItem(Icons.book_online, 3),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 15),

            /// 👤 Profile Floating Button
            GestureDetector(
              onTap: () => _onItemTapped(4),
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}