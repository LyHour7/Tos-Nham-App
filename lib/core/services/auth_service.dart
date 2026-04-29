import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
      String email, String password,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      debugPrint('AuthService.login: sending request to $baseUrl/auth/login');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(timeout);

      debugPrint(
          'AuthService.login: received response (${response.statusCode})');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']['token'];
        final user = User.fromJson(data['data']['user']);

        // Save token + user + role
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user.toJson()));
        await prefs.setString('role', user.role);

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
    } on TimeoutException catch (e) {
      debugPrint('AuthService.login: timeout (${e.toString()})');
      return {
        "success": false,
        "message":
            "Request timed out. Check backend URL/IP and ensure phone + server are on the same Wi-Fi."
      };
    } on SocketException catch (e) {
      debugPrint('AuthService.login: network error ${e.toString()}');
      return {
        "success": false,
        "message":
            "Cannot reach server. Verify API host/IP in ApiConfig and that backend is running."
      };
    } on Exception catch (e) {
      debugPrint('AuthService.login: exception $e');
      return {
        "success": false,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      String phone) async {
    try {
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
    } catch (e) {
      debugPrint("AuthService.register error: $e");
      return {
        "success": false,
        "message": "Network error"
      };
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('role');
  }

  // ================= GET CURRENT USER =================
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }

    return null;
  }

  // ================= GET TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ================= CHECK AUTO LOGIN =================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      return true;
    }

    return false;
  }

  // ================= GET ROLE =================
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ================= CHANGE PASSWORD =================
  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          "success": false,
          "message": "Authentication required. Please login again."
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data['message'] ?? "Password changed successfully"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to change password"
        };
      }
    } catch (e) {
      debugPrint("AuthService.changePassword error: $e");
      return {
        "success": false,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  // ================= UPDATE PROFILE =================
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          "success": false,
          "message": "Authentication required. Please login again."
        };
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local user data
        if (data['data'] != null && data['data']['user'] != null) {
          final updatedUser = User.fromJson(data['data']['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(updatedUser.toJson()));
        }

        return {
          "success": true,
          "message": data['message'] ?? "Profile updated successfully"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to update profile"
        };
      }
    } catch (e) {
      debugPrint("AuthService.updateProfile error: $e");
      return {
        "success": false,
        "message": "Network error: ${e.toString()}"
      };
    }
  }
}