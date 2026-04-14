// NEW FILE — Worker Tasks Screen
// View assigned/active/completed tasks with navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'task_detail_screen.dart';

class WorkerTasksScreen extends StatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  State<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReportModel> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getWorkerTasks();

      if (response['success'] == true) {
        setState(() {
          _tasks = (response['tasks'] as List).map((t) => ReportModel.fromJson(t)).toList();
        });
      }
    } catch (e) {
      debugPrint('Tasks load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ReportModel> get _filteredTasks {
    switch (_tabController.index) {
      case 0: return _tasks.where((t) => t.isAssigned).toList();
      case 1: return _tasks.where((t) => t.isInProgress).toList();
      case 2: return _tasks.where((t) => t.isCompleted).toList();
      default: return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: AppTheme.textLight.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No tasks here', style: TextStyle(color: AppTheme.textLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (_, i) {
                      final task = _filteredTasks[i];
                      return _TaskCard(
                        task: task,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                          );
                          if (result == true) _loadTasks();
                        },
                        onNavigate: () => _openMaps(task.latitude, task.longitude),
                      );
                    },
                  ),
      ),
    );
  }

  void _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _TaskCard extends StatelessWidget {
  final ReportModel task;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const _TaskCard({required this.task, required this.onTap, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.getCategoryColor(task.category);
    final statusColor = AppTheme.getStatusColor(task.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(AppTheme.getCategoryIcon(task.category), color: catColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.categoryLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${task.latitude.toStringAsFixed(3)}, ${task.longitude.toStringAsFixed(3)}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(task.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),

            if (task.description?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(task.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textLight), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Navigate', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
