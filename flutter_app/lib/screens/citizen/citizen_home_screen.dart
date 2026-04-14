// NEW FILE — Citizen Home Screen
// Bottom nav shell with dashboard, reports, map, notifications, profile tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../main.dart';
import 'report_issue_screen.dart';
import 'my_reports_screen.dart';
import 'live_map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const MyReportsScreen(),
    const LiveMapScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()));
        },
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Report'),
        backgroundColor: AppTheme.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB
// ============================================================

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<ReportModel> _recentReports = [];
  bool _loading = true;
  int _totalReports = 0;
  int _pendingReports = 0;
  int _completedReports = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getReports(limit: 5);

      if (response['success'] == true) {
        final reports = (response['reports'] as List)
            .map((r) => ReportModel.fromJson(r))
            .toList();

        setState(() {
          _recentReports = reports;
          _totalReports = response['count'] ?? reports.length;
          _pendingReports = reports.where((r) => r.isPending).length;
          _completedReports = reports.where((r) => r.isCompleted).length;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userName = appState.user?.name ?? 'Citizen';

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
                // Welcome header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName 👋',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep your city roads safe',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textLight.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.traffic, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Stats cards
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.file_copy_rounded,
                      label: 'Total',
                      value: '$_totalReports',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.schedule,
                      label: 'Pending',
                      value: '$_pendingReports',
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: 'Done',
                      value: '$_completedReports',
                      color: AppTheme.success,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Recent reports
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to reports tab
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (_recentReports.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 60, color: AppTheme.textLight.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No reports yet',
                            style: TextStyle(color: AppTheme.textLight.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Report your first road issue!',
                            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_recentReports.length, (i) {
                    final report = _recentReports[i];
                    return _ReportPreviewCard(report: report);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  final ReportModel report;
  const _ReportPreviewCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.getCategoryColor(report.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppTheme.getCategoryIcon(report.category),
            color: AppTheme.getCategoryColor(report.category),
          ),
        ),
        title: Text(
          report.categoryLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          report.description?.isNotEmpty == true
              ? report.description!
              : 'Reported ${_timeAgo(report.createdAt)}',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            report.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
