// NEW FILE — API Service
// HTTP client for communicating with Flask backend

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;

  ApiService(this._authService);

  // ============================================================
  // HTTP HELPERS
  // ============================================================

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? 'Request failed',
    );
  }

  Future<Map<String, dynamic>> _retryRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    Exception? lastError;

    for (int i = 0; i < AppConfig.maxRetries; i++) {
      try {
        final response = await requestFn().timeout(AppConfig.apiTimeout);
        return await _handleResponse(response);
      } on SocketException {
        lastError = ApiException(message: 'No internet connection');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (i < AppConfig.maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }

    throw lastError ?? ApiException(message: 'Request failed');
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String idToken,
    required String role,
    String? name,
    String? fcmToken,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    return _retryRequest(() => http.post(
          Uri.parse('${AppConfig.baseUrl}/auth/login'),
          headers: headers,
          body: jsonEncode({
            'id_token': idToken,
            'role': role,
            'name': name,
            'fcm_token': fcmToken,
          }),
        ));
  }

  Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    return _retryRequest(
        () => http.get(Uri.parse('${AppConfig.baseUrl}/auth/profile'), headers: headers));
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.put(
          Uri.parse('${AppConfig.baseUrl}/auth/profile'),
          headers: headers,
          body: jsonEncode(updates),
        ));
  }

  // ============================================================
  // REPORTS
  // ============================================================

  Future<Map<String, dynamic>> submitReport({
    required String category,
    required double latitude,
    required double longitude,
    String? description,
    String? imageBase64,
    String? address,
  }) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.post(
          Uri.parse('${AppConfig.baseUrl}/report'),
          headers: headers,
          body: jsonEncode({
            'category': category,
            'latitude': latitude,
            'longitude': longitude,
            'description': description ?? '',
            'image_base64': imageBase64,
            'address': address,
          }),
        ));
  }

  Future<Map<String, dynamic>> getReports({
    String? status,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (category != null) params['category'] = category;
    params['limit'] = limit.toString();
    params['offset'] = offset.toString();

    final uri = Uri.parse('${AppConfig.baseUrl}/reports')
        .replace(queryParameters: params);
    return _retryRequest(() => http.get(uri, headers: headers));
  }

  Future<Map<String, dynamic>> getReport(String reportId) async {
    final headers = await _getHeaders();
    return _retryRequest(
        () => http.get(Uri.parse('${AppConfig.baseUrl}/reports/$reportId'), headers: headers));
  }

  // ============================================================
  // WORKER TASKS
  // ============================================================

  Future<Map<String, dynamic>> getWorkerTasks({String? status}) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;

    final uri = Uri.parse('${AppConfig.baseUrl}/worker/tasks')
        .replace(queryParameters: params.isEmpty ? null : params);
    return _retryRequest(() => http.get(uri, headers: headers));
  }

  Future<Map<String, dynamic>> startTask(String taskId) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.put(
          Uri.parse('${AppConfig.baseUrl}/worker/tasks/$taskId/start'),
          headers: headers,
        ));
  }

  Future<Map<String, dynamic>> completeTask(
    String taskId, {
    String? remarks,
    String? imageBase64,
  }) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.put(
          Uri.parse('${AppConfig.baseUrl}/worker/tasks/$taskId/complete'),
          headers: headers,
          body: jsonEncode({
            'remarks': remarks ?? '',
            'image_base64': imageBase64,
          }),
        ));
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  Future<Map<String, dynamic>> logAttendance({
    required String type,
    String? photo,
    double? latitude,
    double? longitude,
  }) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.post(
          Uri.parse('${AppConfig.baseUrl}/attendance'),
          headers: headers,
          body: jsonEncode({
            'type': type,
            'photo': photo,
            'latitude': latitude,
            'longitude': longitude,
          }),
        ));
  }

  Future<Map<String, dynamic>> getAttendanceHistory() async {
    final headers = await _getHeaders();
    return _retryRequest(() =>
        http.get(Uri.parse('${AppConfig.baseUrl}/attendance/history'), headers: headers));
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (unreadOnly) params['unread_only'] = 'true';

    final uri = Uri.parse('${AppConfig.baseUrl}/notifications')
        .replace(queryParameters: params.isEmpty ? null : params);
    return _retryRequest(() => http.get(uri, headers: headers));
  }

  Future<Map<String, dynamic>> markNotificationRead(String notifId) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.put(
          Uri.parse('${AppConfig.baseUrl}/notifications/$notifId/read'),
          headers: headers,
        ));
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  Future<Map<String, dynamic>> submitSupportTicket(String message) async {
    final headers = await _getHeaders();
    return _retryRequest(() => http.post(
          Uri.parse('${AppConfig.baseUrl}/support'),
          headers: headers,
          body: jsonEncode({'message': message}),
        ));
  }

  Future<Map<String, dynamic>> getSupportTickets() async {
    final headers = await _getHeaders();
    return _retryRequest(
        () => http.get(Uri.parse('${AppConfig.baseUrl}/support/tickets'), headers: headers));
  }
}

// ============================================================
// EXCEPTIONS
// ============================================================

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() => message;
}
