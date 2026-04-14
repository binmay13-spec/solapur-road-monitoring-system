// NEW FILE | Extends: flutter_app/lib/services/supabase_service.dart
// Supabase Service for image uploads and data hydration

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseServiceNew {
  // Credentials from the user request
  static const String _url = "https://ujcbdvgqapkgkzjjzmik.supabase.co";
  static const String _anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqY2JkdmdxYXBrZ2t6amp6bWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNzI3MjksImV4cCI6MjA5MTc0ODcyOX0.wqUJFDjAReFHnsAIdsAnFm3JhxISim0YxMG5TZ6y7JE";

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  final SupabaseClient _client = Supabase.instance.client;

  // Fetch reports directly from Supabase (alternative to Flask if needed)
  Future<List<Map<String, dynamic>>> getReports(String userId) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Upload image to Supabase Storage and return public URL
  Future<String?> uploadImage(File file, {String bucket = 'report-images'}) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
      final filePath = "uploads/$fileName";

      await _client.storage.from(bucket).upload(filePath, file);
      
      final String publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print("Image Upload Error: $e");
      return null;
    }
  }
}

// Global instance
final supabaseService = SupabaseServiceNew();
