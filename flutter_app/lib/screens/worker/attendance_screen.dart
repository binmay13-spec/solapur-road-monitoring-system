// NEW FILE — Attendance Screen
// Worker login/logout with face photo and GPS capture

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../app_config.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = false;
  bool _isLoggedIn = false;
  List<AttendanceModel> _history = [];
  final _imagePicker = ImagePicker();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getAttendanceHistory();

      if (response['success'] == true) {
        final records = (response['attendance'] as List).map((a) => AttendanceModel.fromJson(a)).toList();
        setState(() {
          _history = records;
          if (records.isNotEmpty) {
            _isLoggedIn = records.first.isLoggedIn;
          }
        });
      }
    } catch (e) {
      debugPrint('Attendance history error: $e');
    }
  }

  Future<void> _markAttendance(String type) async {
    setState(() => _loading = true);

    try {
      // Step 1: Capture face photo
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: AppConfig.maxImageWidth,
        imageQuality: AppConfig.imageQuality,
      );

      if (picked == null) {
        setState(() => _loading = false);
        return;
      }

      // Step 2: Get GPS location
      final position = await _locationService.getCurrentLocation();

      // Step 3: Convert photo to base64
      final bytes = await File(picked.path).readAsBytes();
      final photoBase64 = base64Encode(bytes);

      // Step 4: Submit to backend
      // ignore: use_build_context_synchronously
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.logAttendance(
        type: type,
        photo: photoBase64,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (response['success'] == true && mounted) {
        setState(() => _isLoggedIn = type == 'login');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'login' ? '✅ Login recorded!' : '✅ Logout recorded!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Attendance'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoggedIn
                      ? [AppTheme.success.withOpacity(0.15), AppTheme.success.withOpacity(0.05)]
                      : [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLoggedIn ? AppTheme.success.withOpacity(0.3) : AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isLoggedIn ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                    size: 56,
                    color: _isLoggedIn ? AppTheme.success : AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoggedIn ? 'On Duty' : 'Off Duty',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: _isLoggedIn ? AppTheme.success : AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _markAttendance(_isLoggedIn ? 'logout' : 'login'),
                      icon: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isLoggedIn ? Icons.logout : Icons.login),
                      label: Text(_loading ? 'Processing...' : (_isLoggedIn ? 'Clock Out' : 'Clock In')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoggedIn ? AppTheme.danger : AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text('Requirements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
            const SizedBox(height: 8),
            _RequirementRow(icon: Icons.camera_front, text: 'Face photo (front camera)'),
            _RequirementRow(icon: Icons.location_on, text: 'GPS location capture'),
            _RequirementRow(icon: Icons.access_time, text: 'Timestamp recording'),

            const SizedBox(height: 28),

            // History
            const Text('Recent History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text('No attendance records', style: TextStyle(color: AppTheme.textLight.withOpacity(0.5))),
                ),
              )
            else
              ...List.generate(_history.length.clamp(0, 10), (i) {
                final att = _history[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: att.isLoggedOut ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today, size: 16, color: att.isLoggedOut ? AppTheme.success : AppTheme.warning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(att.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              'In: ${att.loginTime != null ? DateFormat('h:mm a').format(att.loginTime!) : "—"} | Out: ${att.logoutTime != null ? DateFormat('h:mm a').format(att.logoutTime!) : "—"}',
                              style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RequirementRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.7))),
        ],
      ),
    );
  }
}
