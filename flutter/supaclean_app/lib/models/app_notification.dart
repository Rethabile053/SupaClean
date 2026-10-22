import 'package:flutter/material.dart';

/// The stage of an order that a notification is about.
enum NotificationStatus {
  confirmed('Confirmed', Icons.check_circle_outline, Color(0xFF1565C0), Color(0xFFE3F2FD)),
  pickedUp('Picked up', Icons.local_shipping_outlined, Color(0xFFEF6C00), Color(0xFFFFF3E0)),
  inCleaning('In cleaning', Icons.local_laundry_service_outlined, Color(0xFFE53935), Color(0xFFFFEEEE)),
  delivered('Delivered', Icons.done_all, Color(0xFF2E7D32), Color(0xFFE7F5E8));

  const NotificationStatus(this.label, this.icon, this.color, this.background);

  final String label;
  final IconData icon;

  /// Badge text and icon colour.
  final Color color;

  /// Badge and icon circle fill.
  final Color background;
}

class AppNotification {
  final String orderId;
  final String title;
  final NotificationStatus status;
  final DateTime time;

  const AppNotification({
    required this.orderId,
    required this.title,
    required this.status,
    required this.time,
  });

  /// "10 min ago", "2 hours ago", "Yesterday", "3 days ago".
  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

/// Placeholder notifications, newest first. Replace with real data once
/// order updates are connected.
List<AppNotification> sampleNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      orderId: '1024',
      title: 'Your order #1024 is now in cleaning',
      status: NotificationStatus.inCleaning,
      time: now.subtract(const Duration(minutes: 10)),
    ),
    AppNotification(
      orderId: '1024',
      title: 'Order #1024 is being picked up',
      status: NotificationStatus.pickedUp,
      time: now.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      orderId: '1024',
      title: 'New order #1024 confirmed',
      status: NotificationStatus.confirmed,
      time: now.subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      orderId: '1018',
      title: 'Your order #1018 has been delivered',
      status: NotificationStatus.delivered,
      time: now.subtract(const Duration(days: 1)),
    ),
  ];
}
