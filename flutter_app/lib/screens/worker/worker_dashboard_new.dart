// NEW FILE | Extends: flutter_app/lib/screens/worker/worker_home_screen.dart
// Worker Dashboard with tasks list and attendance status

import 'package:flutter/material.dart';
import '../../services/report_service_new.dart';
import 'attendance_screen_new.dart';
import 'task_detail_screen_new.dart';

class WorkerDashboardNew extends StatefulWidget {
  const WorkerDashboardNew({super.key});

  @override
  State<WorkerDashboardNew> createState() => _WorkerDashboardNewState();
}

class _WorkerDashboardNewState extends State<WorkerDashboardNew> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF77B6EA);
  final Color bgColor = const Color(0xFFE8EEF2);
  final Color textColor = const Color(0xFF37393A);

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    // In a real app, we'd call /worker/tasks. For now, using getMyReports as proxy
    final data = await reportApi.getMyReports(); 
    if (mounted) {
      setState(() {
        _tasks = data.where((t) => t['status'] != 'completed').toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Worker Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreenNew())),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
            tooltip: "Attendance",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Status Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.green, radius: 6),
                const SizedBox(width: 8),
                const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("On Duty", style: TextStyle(color: Colors.green)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text("Details"),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Assigned Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const Center(child: Text("No tasks assigned."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.location_on, color: primaryColor),
        title: Text(task['category'] ?? "Road Issue", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${task['latitude'].toStringAsFixed(2)}, ${task['longitude'].toStringAsFixed(2)}"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => TaskDetailScreenNew(task: task))
        ),
      ),
    );
  }
}
