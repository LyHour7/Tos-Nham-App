import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/user_model.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  User? currentUser;
  bool isLoadingUser = true;

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        currentUser = user;
        isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingUser = false);
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
    if (isLoadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// HEADER
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
                    left: 52,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  decoration: const BoxDecoration(color: teal),
                  child: const Text(
                    'Staff Profile',
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
                          Icons.restaurant,
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

          /// BODY
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCurrentUser,
              color: teal,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 20),
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: currentUser?.email ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: currentUser?.phone ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Branch ID',
                          value: currentUser?.branchId?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Work Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Position',
                          value: currentUser?.role ?? 'Staff',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Status',
                          value: 'Active',
                          valueColor: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'User ID',
                          value: currentUser?.id.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: logout,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    final displayName = currentUser?.name ?? 'Staff Member';
    final role = currentUser?.role ?? 'Staff';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: teal, width: 2.5),
              color: tealLight,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        currentUser?.email ?? 'N/A',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: tealLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF009688), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
