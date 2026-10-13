import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Inbox of notifications pushed from the admin panel via the server.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    // Pull anything new, then clear the unread badge.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await state.syncNotifications();
      await state.markNotificationsRead();
    });
  }

  String _title(String lang) {
    switch (lang) {
      case 'ar':
        return 'الإشعارات';
      case 'ku':
        return 'ئاگادارکردنەوەکان';
      default:
        return 'Notifications';
    }
  }

  String _empty(String lang) {
    switch (lang) {
      case 'ar':
        return 'لا توجد إشعارات بعد';
      case 'ku':
        return 'هیچ ئاگادارکردنەوەیەک نییە';
      default:
        return 'No notifications yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDark;
    final lang = state.lang;
    final items = state.notifications;

    final bg = isDark ? const Color(0xFF0E1018) : const Color(0xFFF7F8FB);
    final cardColor = isDark ? const Color(0xFF161A24) : Colors.white;
    final title = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final muted = isDark ? AppTheme.slate400 : AppTheme.slate500;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(_title(lang)),
        backgroundColor: bg,
        foregroundColor: title,
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 48, color: muted),
                  const SizedBox(height: 12),
                  Text(
                    _empty(lang),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => state.syncNotifications(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.slate700.withValues(alpha: 0.5) : AppTheme.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: AppTheme.brandGradient,
                                ),
                              ),
                              child: const Icon(Icons.campaign_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                n['title']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: title,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          n['body']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                          ),
                        ),
                        if ((n['createdAt']?.toString() ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _formatDate(n['createdAt'].toString()),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final local = d.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$day  $h:$min';
  }
}
