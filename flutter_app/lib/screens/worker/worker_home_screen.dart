// NEW FILE — Worker Home Screen
// Bottom nav shell with dashboard, tasks, and attendance tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../main.dart';
import 'worker_tasks_screen.dart';
import 'attendance_screen.dart';
import '../citizen/profile_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _WorkerDashboardTab(),
    WorkerTasksScreen(),
    AttendanceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.task_rounded), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================================
// WORKER DASHBOARD TAB
// ============================================================

class _WorkerDashboardTab extends StatefulWidget {
  const _WorkerDashboardTab();

  @override
  State<_WorkerDashboardTab> createState() => _WorkerDashboardTabState();
}

class _WorkerDashboardTabState extends State<_WorkerDashboardTab> {
  int _assigned = 0;
  int _inProgress = 0;
  int _completed = 0;
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getWorkerTasks();

      if (response['success'] == true) {
        final summary = response['summary'] ?? {};
        setState(() {
          _assigned = summary['assigned'] ?? 0;
          _inProgress = summary['in_progress'] ?? 0;
          _completed = summary['completed'] ?? 0;
        });
      }

      // Check attendance
      try {
        final attResponse = await api.getAttendanceHistory();
        if (attResponse['success'] == true && (attResponse['attendance'] as List).isNotEmpty) {
          final today = AttendanceModel.fromJson((attResponse['attendance'] as List).first);
          setState(() => _loggedIn = today.isLoggedIn);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Worker dashboard error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final name = appState.user?.name ?? 'Worker';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $name 👷', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Ready to make roads better', style: TextStyle(color: AppTheme.textLight.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.engineering, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Attendance status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _loggedIn
                          ? [AppTheme.success.withOpacity(0.1), AppTheme.success.withOpacity(0.05)]
                          : [AppTheme.warning.withOpacity(0.1), AppTheme.warning.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _loggedIn ? AppTheme.success.withOpacity(0.2) : AppTheme.warning.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _loggedIn ? Icons.check_circle : Icons.schedule,
                        color: _loggedIn ? AppTheme.success : AppTheme.warning,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loggedIn ? 'Checked In' : 'Not Checked In',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: _loggedIn ? AppTheme.success : AppTheme.warning,
                            ),
                          ),
                          Text(
                            _loggedIn ? 'You are currently on duty' : 'Please mark your attendance',
                            style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _WorkerStatCard(label: 'Assigned', value: '$_assigned', color: AppTheme.info, icon: Icons.assignment),
                    const SizedBox(width: 10),
                    _WorkerStatCard(label: 'Active', value: '$_inProgress', color: const Color(0xFFA78BFA), icon: Icons.engineering),
                    const SizedBox(width: 10),
                    _WorkerStatCard(label: 'Done', value: '$_completed', color: AppTheme.success, icon: Icons.check_circle),
                  ],
                ),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _WorkerStatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
