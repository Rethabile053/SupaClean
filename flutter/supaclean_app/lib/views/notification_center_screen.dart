import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/app_notification.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

/// Opened from the bell in [AppHeader] and from Profile.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = sampleNotifications();

    return Scaffold(
      // The bell is hidden here since we are already on its page.
      appBar: const AppHeader(
        title: 'Notification',
        showNotifications: false,
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              message: 'Order updates will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s8,
                AppSpace.s16,
                AppSpace.s24,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.s12),
              itemBuilder: (context, index) =>
                  _NotificationCard(notification: notifications[index]),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final status = notification.status;
    final tone = status.tone;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.background,
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: tone.foreground, size: 22),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figures(AppText.bodyStrong),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(notification.timeAgo, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          StatusBadge(label: status.label, tone: tone),
        ],
      ),
    );
  }
}
