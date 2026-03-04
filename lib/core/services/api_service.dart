import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, dynamic body) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();

    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception("Invalid server response");
    }

    if (response.statusCode == 401) {
      throw Exception("Unauthorized - Please login again");
    }

    if (response.statusCode == 404) {
      throw Exception("Endpoint not found (404)");
    }

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? "Server Error");
    }

    return data;
  }
}