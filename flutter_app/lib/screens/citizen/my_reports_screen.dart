// NEW FILE — My Reports Screen
// Displays citizen's reports with status filtering and detail navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReportModel> _reports = [];
  bool _loading = true;

  final _tabs = const ['All', 'Pending', 'Assigned', 'In Progress', 'Completed'];
  final _statusMap = const {
    'All': null,
    'Pending': 'pending',
    'Assigned': 'assigned',
    'In Progress': 'in_progress',
    'Completed': 'completed',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadReports();
    });
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final currentTab = _tabs[_tabController.index];
      final status = _statusMap[currentTab];

      final response = await api.getReports(status: status);

      if (response['success'] == true) {
        setState(() {
          _reports = (response['reports'] as List).map((r) => ReportModel.fromJson(r)).toList();
        });
      }
    } catch (e) {
      debugPrint('Reports load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Reports'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox, size: 64, color: AppTheme.textLight.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No reports found', style: TextStyle(color: AppTheme.textLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) {
                      final report = _reports[i];
                      return _ReportListItem(
                        report: report,
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)));
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _ReportListItem({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(report.status);
    final catColor = AppTheme.getCategoryColor(report.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Image if available
            if (report.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  report.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: catColor.withOpacity(0.1),
                    child: Icon(AppTheme.getCategoryIcon(report.category), size: 36, color: catColor),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.categoryLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: catColor),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              report.statusLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (report.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      report.description!,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppTheme.textLight.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${report.latitude.toStringAsFixed(3)}, ${report.longitude.toStringAsFixed(3)}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.6)),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(report.createdAt),
                        style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
