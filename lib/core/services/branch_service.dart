import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BranchService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<dynamic>> fetchBranches() async {
    final response = await http.get(
      Uri.parse("$baseUrl/branches"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['branches'];
    } else {
      throw Exception("Failed to load branches");
    }
  }
}