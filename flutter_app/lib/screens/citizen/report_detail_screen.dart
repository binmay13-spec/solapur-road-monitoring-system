// NEW FILE — Report Detail Screen
// Shows full report info with image, location, status timeline

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.getCategoryColor(report.category);
    final statusColor = AppTheme.getStatusColor(report.status);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Report Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (report.imageUrl != null)
              Image.network(
                report.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: catColor.withOpacity(0.1),
                  child: Center(child: Icon(AppTheme.getCategoryIcon(report.category), size: 48, color: catColor)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(AppTheme.getCategoryIcon(report.category), size: 16, color: catColor),
                            const SizedBox(width: 6),
                            Text(report.categoryLabel, style: TextStyle(fontWeight: FontWeight.w600, color: catColor)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(AppTheme.getStatusIcon(report.status), size: 16, color: statusColor),
                            const SizedBox(width: 6),
                            Text(report.statusLabel, style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (report.description?.isNotEmpty == true) ...[
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(report.description!, style: const TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5)),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  _InfoCard(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                    color: AppTheme.primary,
                  ),

                  const SizedBox(height: 12),

                  // Reported time
                  _InfoCard(
                    icon: Icons.schedule,
                    title: 'Reported',
                    value: DateFormat('MMM d, yyyy • h:mm a').format(report.createdAt),
                    color: AppTheme.info,
                  ),

                  if (report.assignedWorkerId != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.engineering,
                      title: 'Assigned Worker',
                      value: report.assignedWorkerId!,
                      color: const Color(0xFFA78BFA),
                    ),
                  ],

                  if (report.isCompleted && report.completedAt != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.check_circle,
                      title: 'Completed',
                      value: DateFormat('MMM d, yyyy • h:mm a').format(report.completedAt!),
                      color: AppTheme.success,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Timeline
                  const Text('Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _TimelineItem(label: 'Reported', isActive: true, icon: Icons.flag),
                  _TimelineItem(label: 'Assigned', isActive: report.isAssigned || report.isInProgress || report.isCompleted, icon: Icons.person_add),
                  _TimelineItem(label: 'In Progress', isActive: report.isInProgress || report.isCompleted, icon: Icons.engineering),
                  _TimelineItem(label: 'Completed', isActive: report.isCompleted, icon: Icons.check_circle, isLast: true),

                  if (report.completionRemarks?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    const Text('Completion Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(report.completionRemarks!, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData icon;
  final bool isLast;

  const _TimelineItem({required this.label, required this.isActive, required this.icon, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.primary : AppTheme.cardColor,
              ),
              child: Icon(icon, size: 16, color: isActive ? Colors.white : AppTheme.textLight),
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: isActive ? AppTheme.primary : AppTheme.cardColor),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.textColor : AppTheme.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
