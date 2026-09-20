import 'package:http/http.dart' as http;

class AppConfig {
  static const String razorpayKey = 'rzp_live_TeE1OMffqcnQCD';

  // Server endpoints
  static const String newServerUrl = 'http://13.127.143.50:3000';
  static const String oldServerUrl = 'http://13.203.194.88:3000';

  // Active production server (default: New App server)
  static String activeServerUrl = newServerUrl;

  static String get serverUrl => activeServerUrl;
  static String get apiBaseUrl => '$serverUrl/api';

  /// Ping primary (New App) server. If unreachable within timeout, fallback to Old App server.
  static Future<String> checkAndSelectActiveServer() async {
    try {
      final response = await http
          .get(Uri.parse('$newServerUrl/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode < 500) {
        activeServerUrl = newServerUrl;
        return activeServerUrl;
      }
    } catch (_) {}

    // Fallback to Old App server
    activeServerUrl = oldServerUrl;
    return activeServerUrl;
  }
}

