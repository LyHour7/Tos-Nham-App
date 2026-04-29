import '../../core/services/api_service.dart';

class ReservationService {
  /// send token scanned from QR into API and return reservation details
  static Future<Map<String, dynamic>?> scanReservation(String token) async {
    try {
      final data = await ApiService.post('/reservations/scan', {
        'token': token,
      });
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// get all reservations (for staff)
  static Future<List<dynamic>> getAllReservations() async {
    final data = await ApiService.get("/reservations");

    if (data['success'] == true &&
        data['data'] != null &&
        data['data']['reservations'] != null) {
      return data['data']['reservations'];
    }

    return [];
  }

  /// update reservation status
  static Future<bool> updateReservationStatus(int reservationId, String status) async {
    try {
      final data = await ApiService.put("/reservations/$reservationId/status", {
        "status": status
      });
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}