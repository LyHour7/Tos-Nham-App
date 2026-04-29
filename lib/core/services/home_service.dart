import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../config/api_config.dart';

class HomeService {
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

  static Future<List<dynamic>> fetchMenuItems() async {
    final response = await http.get(
      Uri.parse("$baseUrl/menu/items"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['menuItems'];
    } else {
      throw Exception("Failed to load menu items");
    }
  }
   // 🔥 ADD TO CART
  static Future<void> addToCart(int menuItemId) async {
    await ApiService.post("/cart", {
      "menu_item_id": menuItemId,
      "quantity": 1
    });
  }
}