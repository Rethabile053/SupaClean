import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/laundry_order.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../services/push_notification_service.dart';
import '../widgets/back_circle_button.dart';
import '../widgets/empty_state.dart';
import 'main_shell.dart';
import 'track_order_loader.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    this.load,
    this.markRead,
    this.markAllRead,
    this.remove,
    this.loadOrder,
  });

  final Future<List<AppNotification>> Function()? load;

  /// Replace the server calls (used by tests).
  final Future<void> Function(String id)? markRead;
  final Future<void> Function()? markAllRead;
  final Future<void> Function(String id)? remove;
  final Future<LaundryOrder> Function(String orderId)? loadOrder;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends State<NotificationCenterScreen> {
  late Future<List<AppNotification>> _future = _load();

  final Set<String> _readNotifications = {};

  /// Notifications the customer removed; hidden straight away while the
  /// server deletes them.
  final Set<String> _removed = {};
  StreamSubscription<void>? _arrivals;

  @override
  void initState() {
    super.initState();
    // A push arrived while this page is open: reload so it appears at once.
    _arrivals = PushNotificationService.instance.arrivals.stream
        .listen((_) => _reload());
  }

  @override
  void dispose() {
    _arrivals?.cancel();
    super.dispose();
  }

  /// Stable key for remembering that a notification was read.
  String _keyOf(AppNotification n) => n.id.isNotEmpty
      ? n.id
      : '${n.orderId}|${n.time.toIso8601String()}|${n.title}';

  Future<List<AppNotification>> _load() async {
    if (widget.load != null) return widget.load!();

    final api = OrderApi();

    // No server address yet: nothing to show (never made-up notifications).
    if (!api.isConfigured) return <AppNotification>[];

    return api.notifications();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });

    await _future.catchError((_) => <AppNotification>[]);
  }

  /// The server keeps what was read, so it is still read after leaving this
  /// page and coming back. A failure is ignored: the page shows it as read
  /// now and the server's answer wins the next time it loads.
  Future<void> _saveRead(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }

  void _markAsRead(AppNotification n) {
    if (_readNotifications.contains(_keyOf(n)) || n.isRead) return;
    setState(() => _readNotifications.add(_keyOf(n)));
    if (n.id.isEmpty) return;
    _saveRead(() => widget.markRead != null
        ? widget.markRead!(n.id)
        : OrderApi().markNotificationRead(n.id));
  }

  /// Tapping a notification marks it as seen and opens the order it is about,
  /// on its Track Your Order screen. Coming back shows it as read.
  Future<void> _open(AppNotification n) async {
    _markAsRead(n);
    if (n.orderId.isEmpty) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TrackOrderLoader(
          orderId: n.orderId,
          load: widget.loadOrder,
        ),
      ),
    );

    // The order may have moved on while it was open: look again.
    if (mounted) await _reload();
  }

  Future<void> _remove(AppNotification n) async {
    final key = _keyOf(n);
    setState(() => _removed.add(key));
    if (n.id.isEmpty) return;
    try {
      if (widget.remove != null) {
        await widget.remove!(n.id);
      } else {
        await OrderApi().deleteNotification(n.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _removed.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the notification. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _markAllAsRead(List<AppNotification> all) {
    setState(() {
      _readNotifications.addAll(all.map(_keyOf));
    });
    _saveRead(() => widget.markAllRead != null
        ? widget.markAllRead!()
        : OrderApi().markAllNotificationsRead());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            const SizedBox(width: 40, child: BackCircleButton()),
            const SizedBox(width: 16),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5393D),
              ),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;

            return ErrorState(
              message: error is ApiException
                  ? error.message
                  : 'We could not load your notifications. Please try again.',
              onRetry: _reload,
            );
          }

          final notifications = [
            for (final n in snapshot.data ?? <AppNotification>[])
              if (!_removed.contains(_keyOf(n))) n,
          ];

          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              message: 'Order updates will show up here.',
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFE5393D),
                  onRefresh: _reload,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      24,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification.isRead ||
                          _readNotifications.contains(_keyOf(notification));

                      return _NotificationCard(
                        notification: notification,
                        isRead: isRead,
                        onTap: () => _open(notification),
                        onRemove: () => _remove(notification),
                      );
                    },
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  14,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEAEAEA)),
                  ),
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        _markAllAsRead(notifications),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5393D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: _NotificationBottomNavigation(),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
    required this.onRemove,
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final status = notification.status;
    final tone = status.tone;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: !isRead
                  ? const Color(0xFFF4CED2)
                  : const Color(0xFFE7E8EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.icon,
                  color: const Color(0xFFE5393D),
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92969C),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (!isRead)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5393D),
                    shape: BoxShape.circle,
                  ),
                ),

              // Tapping opens the order this is about.
              if (notification.orderId.isNotEmpty)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF92969C),
                ),

              IconButton(
                tooltip: 'Remove notification',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFF92969C),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBottomNavigation extends StatelessWidget {
  const _NotificationBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => MainShell.switchTab(
                  context,
                  MainShell.homeTab,
                ),
              ),
              _NavItem(
                icon: Icons.access_time,
                label: 'Orders',
                onTap: () => MainShell.switchTab(
                  context,
                  MainShell.ordersTab,
                ),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Schedule',
                onTap: () => MainShell.switchTab(
                  context,
                  MainShell.scheduleTab,
                ),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: true,
                onTap: () => MainShell.switchTab(
                  context,
                  MainShell.profileTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFFE5393D)
        : const Color(0xFF555B63);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
