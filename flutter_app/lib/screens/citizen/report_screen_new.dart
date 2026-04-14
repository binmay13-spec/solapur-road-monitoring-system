// NEW FILE | Extends: flutter_app/lib/screens/citizen/report_issue_screen.dart
// New Report Submission Screen with Category Picker and Camera

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service_new.dart';
import '../../services/report_service_new.dart';

class ReportScreenNew extends StatefulWidget {
  const ReportScreenNew({super.key});

  @override
  State<ReportScreenNew> createState() => _ReportScreenNewState();
}

class _ReportScreenNewState extends State<ReportScreenNew> {
  String? _selectedCategory;
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    "Pothole",
    "Road Obstruction",
    "Water Logging",
    "Broken Streetlight",
    "Garbage"
  ];

  final Color primaryColor = const Color(0xFF77B6EA);
  final Color bgColor = const Color(0xFFE8EEF2);
  final Color textColor = const Color(0xFF37393A);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null || _imageFile == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields and enable location.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Upload to Supabase
      final imageUrl = await supabaseService.uploadImage(_imageFile!);
      
      // 2. Submit to Flask API
      final result = await reportApi.submitReport(
        category: _selectedCategory!,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reported Successfully! AI is analyzing...")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Submit New Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Image Picker Area
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: primaryColor),
                          const Text("Tap to take photo"),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select Category"),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
