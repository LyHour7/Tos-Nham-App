import '../../core/services/api_service.dart';

class ProfileService {

  /* ===============================
     GET PROFILE
  =============================== */
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await ApiService.get("/auth/me");

    if (data['success'] == true &&
        data['data'] != null &&
        data['data']['user'] != null) {
      return data['data']['user'];
    }

    return {};
  }

  /* ===============================
     GET USER ORDERS
  =============================== */
  static Future<List<dynamic>> getOrders() async {
    final data = await ApiService.get("/orders");

    if (data['success'] == true &&
        data['data'] != null &&
        data['data']['orders'] != null) {
      return data['data']['orders'];
    }

    return [];
  }

  /* ===============================
     GET USER RESERVATIONS
  =============================== */
  static Future<List<dynamic>> getReservations() async {
    final data = await ApiService.get("/reservations");

    if (data['success'] == true &&
        data['data'] != null &&
        data['data']['reservations'] != null) {
      return data['data']['reservations'];
    }

    return [];
  }
}