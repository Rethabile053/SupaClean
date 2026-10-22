import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';

/// The stage of an order that a notification is about.
enum NotificationStatus {
  confirmed('Confirmed', Icons.check_circle_outline, StatusTone.neutral),
  pickedUp('Picked up', Icons.local_shipping_outlined, StatusTone.progress),
  inCleaning(
    'In cleaning',
    Icons.local_laundry_service_outlined,
    StatusTone.progress,
  ),
  delivered('Delivered', Icons.done_all, StatusTone.success);

  const NotificationStatus(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;

  /// Colours for the badge and the icon circle.
  final StatusTone tone;
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
