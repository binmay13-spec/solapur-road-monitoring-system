// NEW FILE — App Configuration
// Backend URL and app-wide constants

class AppConfig {
  // Backend API URL — change this to your deployed server
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator localhost
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator
  // static const String baseUrl = 'https://your-api.com'; // Production

  // App Info
  static const String appName = 'Smart Road Monitor';
  static const String appVersion = '1.0.0';

  // Map defaults (Solapur, Maharashtra)
  static const double defaultLatitude = 17.6599;
  static const double defaultLongitude = 75.9064;
  static const double defaultZoom = 13.0;

  // Report categories
  static const List<Map<String, String>> categories = [
    {'value': 'pothole', 'label': 'Pothole', 'icon': '🕳️'},
    {'value': 'road_obstruction', 'label': 'Road Obstruction', 'icon': '🚧'},
    {'value': 'water_logging', 'label': 'Water Logging', 'icon': '🌊'},
    {'value': 'broken_streetlight', 'label': 'Broken Streetlight', 'icon': '💡'},
    {'value': 'garbage', 'label': 'Garbage', 'icon': '🗑️'},
  ];

  // Report statuses
  static const List<String> statuses = [
    'pending',
    'assigned',
    'in_progress',
    'completed',
  ];

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;

  // Image constraints
  static const double maxImageWidth = 1024;
  static const double maxImageHeight = 1024;
  static const int imageQuality = 80;
}
