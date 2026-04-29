import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

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

  static Future<dynamic> multipart(
  String endpoint, {
  Map<String, String>? fields,
  File? file,
  String? fileField,
}) async {

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri = Uri.parse("$baseUrl$endpoint");

  var request = http.MultipartRequest("PUT", uri);

  if (token != null) {
    request.headers['Authorization'] = "Bearer $token";
  }

  /// add text fields
  if (fields != null) {
    request.fields.addAll(fields);
  }

  /// add image file
  if (file != null && fileField != null) {
    request.files.add(
      await http.MultipartFile.fromPath(fileField, file.path),
    );
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  return _handleResponse(response);
}
}