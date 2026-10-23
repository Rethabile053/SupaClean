import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/app_notification.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

/// Opened from the bell in [AppHeader] and from Profile. Lists what
/// SupaClean has sent: order updates and payment confirmations.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, this.load});

  /// Replaces the server call (used by tests).
  final Future<List<AppNotification>> Function()? load;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<List<AppNotification>> _future = _load();

  Future<List<AppNotification>> _load() async {
    if (widget.load != null) return widget.load!();

    final api = OrderApi();
    // Without a server address (development builds) show sample cards so the
    // screen can still be designed and demoed.
    if (!api.isConfigured) return sampleNotifications();
    return api.notifications();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future.catchError((_) => <AppNotification>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The bell is hidden here since we are already on its page.
      appBar: const AppHeader(
        title: 'Notification',
        showNotifications: false,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorState(
              message: error is ApiException
                  ? error.message
                  : 'We could not load your notifications. Please try '
                      'again.',
              onRetry: _reload,
            );
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              message: 'Order updates will show up here.',
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
        },
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
                  maxLines: 3,
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
