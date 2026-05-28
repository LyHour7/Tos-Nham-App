import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/login_screen.dart';

Future<bool> ensureLoggedIn(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token != null && token.isNotEmpty) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return false;
}
