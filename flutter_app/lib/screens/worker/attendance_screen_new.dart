// NEW FILE | Extends: flutter_app/lib/screens/worker/attendance_screen.dart
// Attendance Capture (Photo + GPS)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service_new.dart';

class AttendanceScreenNew extends StatefulWidget {
  const AttendanceScreenNew({super.key});

  @override
  State<AttendanceScreenNew> createState() => _AttendanceScreenNewState();
}

class _AttendanceScreenNewState extends State<AttendanceScreenNew> {
  File? _imageFile;
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between Login/Logout

  final Color primaryColor = const Color(0xFF77B6EA);
  final Color bgColor = const Color(0xFFE8EEF2);

  Future<void> _capturePhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitAttendance() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo required")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final imageUrl = await supabaseService.uploadImage(_imageFile!, bucket: 'attendance-photos');
      
      // Call backend API (Mocked for now)
      // await workerApi.logAttendance(type: _isLogin ? 'login' : 'logout', ...);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_isLogin ? 'Login' : 'Logout'} Successful!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text("Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Punch In"),
                  selected: _isLogin,
                  onSelected: (val) => setState(() => _isLogin = true),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("Punch Out"),
                  selected: !_isLogin,
                  onSelected: (val) => setState(() => _isLogin = false),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Photo Preview
            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 4),
                ),
                child: _imageFile != null
                    ? ClipOval(child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Icon(Icons.camera_front, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Capture Face Photo", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? "Confirm Punch In" : "Confirm Punch Out", style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
