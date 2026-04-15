// NEW FILE — Task Detail Screen (Worker)
// View task details, start work, or navigate to completion screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'task_completion_screen.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final ReportModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late ReportModel _task;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _startTask() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.startTask(_task.id);

      if (response['success'] == true) {
        setState(() {
          _task = ReportModel.fromJson({..._task.toJson(), 'id': _task.id, 'status': 'in_progress', 'created_at': _task.createdAt.toIso8601String(), 'updated_at': DateTime.now().toIso8601String()});
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Task started!'), backgroundColor: AppTheme.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.getCategoryColor(_task.category);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (_task.imageUrl != null)
              Image.network(_task.imageUrl!, width: double.infinity, height: 220, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 150, color: catColor.withOpacity(0.1), child: Center(child: Icon(AppTheme.getCategoryIcon(_task.category), size: 48, color: catColor))),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Row(
                    children: [
                      Icon(AppTheme.getCategoryIcon(_task.category), color: catColor, size: 24),
                      const SizedBox(width: 10),
                      Text(_task.categoryLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (_task.description?.isNotEmpty == true) ...[
                    const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                    const SizedBox(height: 6),
                    Text(_task.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Location card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                              Text('${_task.latitude.toStringAsFixed(5)}, ${_task.longitude.toStringAsFixed(5)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions, color: AppTheme.primary),
                          onPressed: () async {
                            final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_task.latitude},${_task.longitude}');
                            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppTheme.info),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reported', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                            Text(DateFormat('MMM d, yyyy • h:mm a').format(_task.createdAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action buttons
                  if (_task.isAssigned)
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _startTask,
                        icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow_rounded),
                        label: Text(_loading ? 'Starting...' : 'Start Work'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA78BFA)),
                      ),
                    ),

                  if (_task.isInProgress)
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskCompletionScreen(task: _task)));
                          // ignore: use_build_context_synchronously
                          if (result == true && mounted) Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      ),
                    ),

                  if (_task.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
                          const SizedBox(width: 12),
                          const Text('Task Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.success)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
