// NEW FILE | Extends: flutter_app/lib/screens/worker/task_detail_screen.dart
// Task Detail with Google Maps Navigation and Completion Form

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service_new.dart';
import '../../services/report_service_new.dart';

class TaskDetailScreenNew extends StatefulWidget {
  final dynamic task;
  const TaskDetailScreenNew({super.key, required this.task});

  @override
  State<TaskDetailScreenNew> createState() => _TaskDetailScreenNewState();
}

class _TaskDetailScreenNewState extends State<TaskDetailScreenNew> {
  File? _proofFile;
  bool _isLoading = false;
  final _remarksController = TextEditingController();

  final Color primaryColor = const Color(0xFF77B6EA);

  Future<void> _openNavigation() async {
    final lat = widget.task['latitude'];
    final lng = widget.task['longitude'];
    final url = "google.navigation:q=$lat,$lng&mode=d";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Fallback to web maps
      await launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"));
    }
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  Future<void> _completeTask() async {
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proof photo required")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageUrl = await supabaseService.uploadImage(_proofFile!, bucket: 'report-images');
      final result = await reportApi.completeTask(
        reportId: widget.task['id'].toString(),
        proofUrl: imageUrl!,
        remarks: _remarksController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task Completed!")));
          Navigator.pop(context);
        }
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
      appBar: AppBar(title: const Text("Task Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Issue Info
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(widget.task['image_url'] ?? '', height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(widget.task['category'] ?? "Issue", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.task['description'] ?? "No description", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openNavigation,
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text("Start Navigation", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
            const Divider(height: 40),

            // Completion Form
            const Text("Completion Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickProof,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _proofFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_proofFile!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_a_photo, size: 40), Text("Add Proof Photo")],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: "Remarks", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeTask,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
