import 'package:flutter/material.dart';
import 'package:tos_nham_app/features/customer/reservation/reservation_qr_payment_screen.dart';
import 'routes/app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/staff/staff_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/customer/widgets/bottom_nav_bar.dart';
import 'features/customer/orders/order_online_screen.dart'; // ✅ ADD THIS
import 'features/customer/booking/booking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.customerHome: (context) => const CustomerBottomNavBar(),
        AppRoutes.staffDashboard: (context) => const StaffDashboardScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),

        // ✅ ADD THIS
        AppRoutes.booking: (context) => const BookingFormScreen(),

        AppRoutes.reservationQR: (context) => const ReservationQRPaymentScreen(
              qrString: "",
              md5: "",
              reservationId: 0,
              depositAmount: "",
            ),

        AppRoutes.orderOnline: (context) => const OrderOnlineScreen(),
      },
    );
  }
}
