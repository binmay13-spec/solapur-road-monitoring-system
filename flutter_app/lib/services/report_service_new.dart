// NEW FILE | Extends: flutter_app/lib/services/report_service.dart
// API Client for reports with Firebase Authorization

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'firebase_auth_service_new.dart';

class ReportServiceNew {
  // Base URL for API requests
  final String _baseUrl = "https://solapur-road-monitoring-system.onrender.com";

  Future<Map<String, String>> _getHeaders() async {
    final token = await firebaseAuthService.getIdToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<Map<String, dynamic>> submitReport({
    required String category,
    required String description,
    String? imageUrl,
    required double lat,
    required double lng,
  }) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      "category": category,
      "description": description,
      "image_url": imageUrl,
      "latitude": lat,
      "longitude": lng,
    });

    final response = await http.post(
      Uri.parse("$_baseUrl/citizen/report"),
      headers: headers,
      body: body,
    );

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMyReports() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$_baseUrl/citizen/reports"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reports"] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> getMapData() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$_baseUrl/citizen/map"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reports"] ?? [];
    }
    return [];
  }

  // Worker task completion
  Future<Map<String, dynamic>> completeTask({
    required String reportId,
    required String proofUrl,
    required String remarks,
  }) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      "report_id": reportId,
      "proof_url": proofUrl,
      "remarks": remarks,
    });

    final response = await http.post(
      Uri.parse("$_baseUrl/worker/task/complete"),
      headers: headers,
      body: body,
    );

    return jsonDecode(response.body);
  }
}

// Global instance
final reportApi = ReportServiceNew();
