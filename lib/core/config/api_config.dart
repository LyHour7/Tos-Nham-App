import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==================== CONFIGURATION ====================
  // Machine LAN IP for real device testing.
  // Tip: override with --dart-define=API_HOST=YOUR_WIFI_IP
  static const String _machineIp =
      String.fromEnvironment('API_HOST', defaultValue: '10.2.1.198');
  static const int _backendPort = 5000;
  static const bool _useAndroidEmulator =
      bool.fromEnvironment('USE_ANDROID_EMULATOR', defaultValue: false);
  
  // ==================== AUTO DETECTION ====================
  static String get baseUrl {
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
    debugPrint('Platform: ${Platform.operatingSystem}');
    if (!kIsWeb) {
      debugPrint('ApiConfig.machineIp: $_machineIp');
    }
    if (!kIsWeb && Platform.isAndroid) {
      debugPrint('ApiConfig.useAndroidEmulator: $_useAndroidEmulator');
    }
  }
}
