import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../branch/all_branch_screen.dart';
import '../booking/booking_screen.dart';
import '../menu/cart_screen.dart';
import '../profile/profile_screen.dart';

class CustomerBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const CustomerBottomNavBar({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CustomerBottomNavBar> createState() => _CustomerBottomNavBarState();
}

class _CustomerBottomNavBarState extends State<CustomerBottomNavBar> {
  static const Color _primaryNavColor = Color(0xFF008F99);

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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

  Widget _navItem(String assetPath, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)
              : null,
        ),
        child: Center(
          child: ImageIcon(
            AssetImage(assetPath),
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfileSelected = _selectedIndex == 4;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 🔵 Main Nav Pill Container
              Expanded(
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: _primaryNavColor,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryNavColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem('lib/Asset/icon/home.png', 0),
                      _navItem('lib/Asset/icon/restaurant.png', 1),
                      _navItem('lib/Asset/icon/order.png', 2),
                      _navItem('lib/Asset/icon/booking.png', 3),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// 👤 Profile Floating Circle Button
              GestureDetector(
                onTap: () => _onItemTapped(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: _primaryNavColor,
                    shape: BoxShape.circle,
                    border: isProfileSelected
                        ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryNavColor.withOpacity(0.4),
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
                      child: const Center(
                        child: ImageIcon(
                          AssetImage('lib/Asset/icon/profile.png'),
                          size: 28,
                          color: Colors.white,
                        ),
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
}