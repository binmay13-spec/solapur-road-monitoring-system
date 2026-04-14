// NEW FILE | Extends: flutter_app/lib/screens/citizen/my_reports_screen.dart
// My Reports List with Status Badges and Details

import 'package:flutter/material.dart';
import '../../services/report_service_new.dart';

class MyReportsScreenNew extends StatefulWidget {
  const MyReportsScreenNew({super.key});

  @override
  State<MyReportsScreenNew> createState() => _MyReportsScreenNewState();
}

class _MyReportsScreenNewState extends State<MyReportsScreenNew> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF77B6EA);
  final Color textColor = const Color(0xFF37393A);

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final data = await reportApi.getMyReports();
    if (mounted) {
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF2),
      appBar: AppBar(title: const Text("My Reports"), backgroundColor: Colors.transparent, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text("No submissions yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) => _buildReportCard(_reports[index]),
                ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    final status = report['status'] ?? "pending";
    Color statusColor;
    switch (status) {
      case 'completed': statusColor = Colors.green; break;
      case 'assigned': statusColor = Colors.blue; break;
      case 'in_progress': statusColor = Colors.orange; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image
          if (report['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(report['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(report['category'] ?? "Road Issue", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(report['description'] ?? "No description provided.", style: TextStyle(color: textColor.withOpacity(0.7))),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      "${report['latitude'].toStringAsFixed(4)}, ${report['longitude'].toStringAsFixed(4)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      report['created_at'].toString().split('T')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
