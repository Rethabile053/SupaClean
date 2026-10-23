
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../widgets/empty_state.dart';
import 'main_shell.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key, this.load});

  final Future<List<AppNotification>> Function()? load;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends State<NotificationCenterScreen> {
  late Future<List<AppNotification>> _future = _load();

  final Set<int> _readNotifications = {};

  Future<List<AppNotification>> _load() async {
    if (widget.load != null) return widget.load!();

    final api = OrderApi();

    if (!api.isConfigured) return sampleNotifications();

    return api.notifications();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });

    await _future.catchError((_) => <AppNotification>[]);
  }

  void _markAllAsRead(int count) {
    setState(() {
      _readNotifications.addAll(
        List.generate(count, (index) => index),
      );
    });

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
            InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFFE5393D),
                  size: 21,
                ),
              ),
            ),
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

          final notifications =
              snapshot.data ?? <AppNotification>[];

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
                      final isRead =
                          _readNotifications.contains(index);

                      return _NotificationCard(
                        notification: notification,
                        isRead: isRead,
                        onTap: () {
                          setState(() {
                            _readNotifications.add(index);
                          });
                        },
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
                        _markAllAsRead(notifications.length),
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
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;

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
