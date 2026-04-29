import '../../core/services/api_service.dart';
import '../../models/menu_model.dart';

class MenuService {
  static Future<List<MenuItem>> fetchMenuItemsByBranch(int branchId) async {
    final data = await ApiService.get("/menu/items?branch_id=$branchId");

    if (data['success'] == true && data['data'] != null && data['data']['menuItems'] != null) {
      final menuItems = data['data']['menuItems'] as List;
      return menuItems.map((item) => MenuItem.fromJson(item)).toList();
    }

    return [];
  }

  static Future<bool> updateMenuItemStatus(int itemId, String status) async {
    try {
      // some backends update item via /menu/items/{id} instead of /status endpoint
      final data = await ApiService.put("/menu/items/$itemId", {
        "status": status
      });

      return data['success'] == true;
    } catch (e) {
      // if specific status endpoint is required, retry once
      try {
        final data = await ApiService.put("/menu/items/$itemId/status", {
          "status": status
        });
        return data['success'] == true;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCategoriesByBranch(int branchId) async {
    final data = await ApiService.get('/menu/categories?branch_id=$branchId');

    if (data['success'] != true || data['data'] == null) {
      return [];
    }

    final payload = data['data'];
    List raw = [];

    if (payload is List) {
      raw = payload;
    } else if (payload is Map && payload['categories'] is List) {
      raw = payload['categories'];
    }

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<bool> updateMenuItem({
    required int itemId,
    required String name,
    required int categoryId,
    required double price,
    required String status,
    required String description,
  }) async {
    final data = await ApiService.put('/menu/items/$itemId', {
      'name': name,
      'category_id': categoryId,
      'price': price,
      'status': status,
      'description': description,
    });

    return data['success'] == true;
  }
}