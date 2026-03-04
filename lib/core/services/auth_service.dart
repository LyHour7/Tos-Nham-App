import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {

      final token = data['data']['token'];
      final user = User.fromJson(data['data']['user']);

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return {
        "success": true,
        "user": user,
      };

    } else {
      return {
        "success": false,
        "message": data['message'] ?? "Login failed"
      };
    }
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      String phone) async {

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {"success": true};
    } else {
      return {
        "success": false,
        "message": data['message'] ?? "Register failed"
      };
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}