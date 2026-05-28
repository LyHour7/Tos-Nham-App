import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==================== CONFIGURATION ====================
  // Use API_URL when you need the full backend URL.
  // Example: --dart-define=API_URL=http://192.168.1.50:5000/api
  static const String _apiUrl =
      String.fromEnvironment('API_URL', defaultValue: '');

  // Machine LAN IP for real device testing.
  // Example: --dart-define=API_HOST=192.168.1.50
  static const String _machineIp =
      String.fromEnvironment('API_HOST', defaultValue: '10.2.1.198');
  static const int _backendPort = 5000;

  // Android emulators reach the host machine through 10.0.2.2.
  // Pass --dart-define=USE_ANDROID_EMULATOR=false for a physical phone.
  static const bool _useAndroidEmulator =
      bool.fromEnvironment('USE_ANDROID_EMULATOR', defaultValue: true);

  // ==================== AUTO DETECTION ====================
  static String get baseUrl {
    if (_apiUrl.isNotEmpty) {
      return _apiUrl;
    }

    if (kIsWeb) {
      // Web: use localhost or your server
      return "http://localhost:$_backendPort/api";
    } else if (Platform.isAndroid) {
      // Android emulator cannot access host localhost directly.
      if (_useAndroidEmulator) {
        return "http://10.0.2.2:$_backendPort/api";
      } else {
        return "http://$_machineIp:$_backendPort/api";
      }
    } else if (Platform.isIOS) {
      // iOS: use machine IP for both simulator and real device
      return "http://$_machineIp:$_backendPort/api";
    } else {
      // fallback
      return "http://localhost:$_backendPort/api";
    }
  }

  // ==================== UPDATE SETTINGS ====================
  /// Call this to update the machine IP for real device testing
  static void setMachineIp(String ip) {
    // You can extend this to save to SharedPreferences if needed
    debugPrint('ApiConfig: Machine IP updated to $ip');
  }

  /// Print the current API URL being used
  static void printApiUrl() {
    debugPrint('ApiConfig.baseUrl: $baseUrl');
    if (_apiUrl.isNotEmpty) {
      debugPrint('ApiConfig.apiUrl override: $_apiUrl');
    }
    if (kIsWeb) {
      debugPrint('Platform: web');
    } else {
      debugPrint('Platform: ${Platform.operatingSystem}');
      debugPrint('ApiConfig.machineIp: $_machineIp');
      if (Platform.isAndroid) {
        debugPrint('ApiConfig.useAndroidEmulator: $_useAndroidEmulator');
      }
    }
  }
}
