import 'dart:convert';
import 'package:http/http.dart' as http;

class BranchService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

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