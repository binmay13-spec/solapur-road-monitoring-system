// NEW FILE — Live Map Screen
// Shows issues on a map with category/status filters

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../app_config.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<ReportModel> _reports = [];
  bool _loading = true;
  String? _categoryFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getReports(
        category: _categoryFilter,
        status: _statusFilter,
        limit: 200,
      );

      if (response['success'] == true) {
        setState(() {
          _reports = (response['reports'] as List).map((r) => ReportModel.fromJson(r)).toList();
        });
      }
    } catch (e) {
      debugPrint('Map reports error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Live Map'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude),
              initialZoom: AppConfig.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartroad.monitor',
              ),
              MarkerLayer(
                markers: _reports.map((r) => _buildMarker(r)).toList(),
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Legend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...['pothole', 'road_obstruction', 'water_logging', 'broken_streetlight', 'garbage'].map((cat) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.getCategoryColor(cat))),
                          const SizedBox(width: 6),
                          Text(cat.replaceAll('_', ' '), style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(ReportModel report) {
    final color = AppTheme.getCategoryColor(report.category);
    return Marker(
      point: LatLng(report.latitude, report.longitude),
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showReportPopup(report),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
          ),
          child: Icon(AppTheme.getCategoryIcon(report.category), color: Colors.white, size: 16),
        ),
      ),
    );
  }

  void _showReportPopup(ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppTheme.getCategoryIcon(report.category), color: AppTheme.getCategoryColor(report.category)),
                const SizedBox(width: 10),
                Text(report.categoryLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(report.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getStatusColor(report.status))),
                ),
              ],
            ),
            if (report.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(report.description!, style: const TextStyle(color: AppTheme.textLight)),
            ],
            const SizedBox(height: 12),
            Text('📍 ${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryFilter,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...AppConfig.categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))),
              ],
              onChanged: (v) => _categoryFilter = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...['pending', 'assigned', 'in_progress', 'completed'].map((s) =>
                  DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))),
              ],
              onChanged: (v) => _statusFilter = v,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadReports();
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
