// NEW FILE — Task Completion Screen
// Upload proof photo and add remarks to complete a task

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../app_config.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class TaskCompletionScreen extends StatefulWidget {
  final ReportModel task;
  const TaskCompletionScreen({super.key, required this.task});

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  File? _proofImage;
  final _remarksController = TextEditingController();
  bool _loading = false;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConfig.maxImageWidth,
        maxHeight: AppConfig.maxImageHeight,
        imageQuality: AppConfig.imageQuality,
      );
      if (picked != null) setState(() => _proofImage = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image error: $e')));
      }
    }
  }

  Future<void> _completeTask() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a proof photo'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final bytes = await _proofImage!.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final response = await api.completeTask(
        widget.task.id,
        remarks: _remarksController.text.trim(),
        imageBase64: imageBase64,
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Task completed successfully!'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(title: const Text('Complete Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(widget.task.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(AppTheme.getCategoryIcon(widget.task.category), color: AppTheme.getCategoryColor(widget.task.category)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.task.categoryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(widget.task.id.substring(0, 8), style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Proof photo
            const Text('Completion Proof Photo *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Take a photo showing the completed work', style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.6))),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                            title: const Text('Camera'),
                            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                            title: const Text('Gallery'),
                            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 2),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_proofImage!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 48, color: AppTheme.success.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text('Tap to capture proof photo', style: TextStyle(color: AppTheme.textLight.withOpacity(0.6))),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Remarks
            const Text('Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the work done...',
              ),
            ),

            const SizedBox(height: 36),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _completeTask,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_loading ? 'Submitting...' : 'Mark as Completed'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
