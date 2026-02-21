# Tos-Nham-App
lib/
│
├── main.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── api_constants.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── helpers.dart
│   │   └── date_formatter.dart
│   │
│   └── services/
│       ├── api_service.dart
│       ├── auth_service.dart
│       ├── qr_service.dart
│       └── storage_service.dart
│
├── models/
│   ├── user_model.dart
│   ├── branch_model.dart
│   ├── menu_model.dart
│   ├── reservation_model.dart
│   ├── order_model.dart
│   ├── order_item_model.dart
│   └── payment_model.dart
│
├── routes/
│   └── app_routes.dart
│
├── widgets/
│   ├── custom_button.dart
│   ├── custom_textfield.dart
│   ├── order_card.dart
│   ├── reservation_card.dart
│   ├── status_badge.dart
│   └── loading_widget.dart
│
├── features/
│
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   │
│   ├── customer/
│   │
│   │   ├── home/
│   │   │   └── customer_home_screen.dart
│   │   │
│   │   ├── branch/
│   │   │   └── branch_selection_screen.dart
│   │   │
│   │   ├── menu/
│   │   │   ├── menu_screen.dart
│   │   │   ├── menu_detail_screen.dart
│   │   │   └── cart_screen.dart
│   │   │
│   │   ├── booking/
│   │   │   ├── booking_form_screen.dart
│   │   │   ├── booking_summary_screen.dart
│   │   │   └── booking_qr_screen.dart
│   │   │
│   │   ├── orders/
│   │   │   ├── orders_screen.dart
│   │   │   └── order_detail_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── address_screen.dart
│   │   │
│   │   └── widgets/
│   │       └── bottom_nav_bar.dart
│   │
│   ├── staff/
│   │   ├── staff_dashboard_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── staff_orders_screen.dart
│   │   ├── staff_order_detail_screen.dart
│   │   └── staff_reservations_screen.dart
│   │
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── branch_management_screen.dart
│       ├── menu_management_screen.dart
│       ├── reservation_management_screen.dart
│       ├── order_management_screen.dart
│       └── reports_screen.dart
│
└── main_wrapper.dart
