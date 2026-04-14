// NEW FILE — Report Issue Screen
// Category selection, image capture, GPS location, and submit

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../app_config.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  final _descriptionController = TextEditingController();
  bool _loading = false;
  bool _gettingLocation = false;
  String? _locationText;

  final _imagePicker = ImagePicker();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location: $e'), backgroundColor: AppTheme.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConfig.maxImageWidth,
        maxHeight: AppConfig.maxImageHeight,
        imageQuality: AppConfig.imageQuality,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image error: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable GPS location')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);

      String? imageBase64;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final response = await api.submitReport(
        category: _selectedCategory!,
        latitude: _latitude!,
        longitude: _longitude!,
        description: _descriptionController.text.trim(),
        imageBase64: imageBase64,
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
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
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category selection
            const Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConfig.categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                final color = AppTheme.getCategoryColor(cat['value']!);
                return ChoiceChip(
                  selected: isSelected,
                  label: Text('${cat["icon"]} ${cat["label"]}'),
                  selectedColor: color.withOpacity(0.2),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? color : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? color : AppTheme.cardColor,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat['value']),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Image capture
            const Text('Capture Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardColor, width: 2, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 48, color: AppTheme.textLight.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to capture or select photo',
                            style: TextStyle(color: AppTheme.textLight.withOpacity(0.6), fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // GPS location
            const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _latitude != null ? Icons.location_on : Icons.location_searching,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _gettingLocation
                        ? const Text('Getting location...', style: TextStyle(fontSize: 13))
                        : Text(
                            _locationText ?? 'Location not available',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                  ),
                  IconButton(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.refresh, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Description
            const Text('Description (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
              ),
            ),

            const SizedBox(height: 36),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_loading ? 'Submitting...' : 'Submit Report'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
