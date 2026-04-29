import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'routes/app_routes.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

import 'features/admin/admin_dashboard_screen.dart';
import 'features/staff/staff_home_screen.dart';
import 'features/customer/widgets/bottom_nav_bar.dart';
import 'features/customer/menu/cart_screen.dart';
import 'features/customer/orders/order_online_screen.dart';
import 'features/customer/booking/booking_screen.dart';
import 'features/customer/profile/edit_profile_screen.dart';
import 'features/customer/reservation/reservation_qr_payment_screen.dart';

import 'core/services/auth_service.dart';
import 'core/config/api_config.dart';
import 'models/user_model.dart';

void main() {
  ApiConfig.printApiUrl();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// allow changing language from anywhere
  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  /// default language
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// home widget with auth check
     home: FutureBuilder<User?>(
  future: AuthService.getCurrentUser(),
  builder: (context, snapshot) {

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasData && snapshot.data != null) {
      final user = snapshot.data!;

      if (user.role == 'admin') {
        return const AdminDashboardScreen();
      }

      if (user.role == 'staff') {
        return const StaffHomeScreen();
      }

      if (user.role == 'customer') {
        return const CustomerBottomNavBar();
      }
    }

    return const LoginScreen();
  },
),

      /// localization
      locale: _locale,

      supportedLocales: const [
        Locale('en'),
        Locale('km'),
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routes: {

        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),

        AppRoutes.customerHome: (context) => const CustomerBottomNavBar(),
AppRoutes.staffDashboard: (context) => const StaffHomeScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),

        /// Booking
        AppRoutes.booking: (context) => const BookingFormScreen(),

        /// Cart
        AppRoutes.cart: (context) => const CartScreen(),

        /// Profile
        AppRoutes.editProfile: (context) => const EditProfileScreen(),

        /// Reservation Payment
        AppRoutes.reservationQR: (context) => const ReservationQRPaymentScreen(
              qrString: "",
              md5: "",
              reservationId: 0,
              depositAmount: "",
            ),

        /// Online Order
        AppRoutes.orderOnline: (context) => const OrderOnlineScreen(),
      },
    );
  }
}