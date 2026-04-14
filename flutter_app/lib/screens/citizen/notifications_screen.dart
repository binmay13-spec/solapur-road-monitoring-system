// NEW FILE — Notifications Screen
// Displays in-app notifications for status updates

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.getNotifications();

      if (response['success'] == true) {
        setState(() {
          _notifications = (response['notifications'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Notifications error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'assignment': return Icons.person_add_rounded;
      case 'status_update': return Icons.engineering_rounded;
      case 'completion': return Icons.check_circle_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'assignment': return AppTheme.info;
      case 'status_update': return const Color(0xFFA78BFA);
      case 'completion': return AppTheme.success;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notifications'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: AppTheme.textLight.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No notifications yet', style: TextStyle(color: AppTheme.textLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final notif = _notifications[i];
                      final color = _getColor(notif.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.isRead ? Colors.white : color.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: notif.isRead ? null : Border.all(color: color.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_getIcon(notif.type), color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(notif.body, style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.7))),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(notif.createdAt),
                                    style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.4)),
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
