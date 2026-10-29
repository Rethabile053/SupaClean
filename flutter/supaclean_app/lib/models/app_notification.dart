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
  delivered('Delivered', Icons.done_all, StatusTone.success),
  payment('Payment', Icons.payments_outlined, StatusTone.success),
  update('Update', Icons.notifications_none_outlined, StatusTone.neutral);

  const NotificationStatus(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;

  /// Colours for the badge and the icon circle.
  final StatusTone tone;
}

class AppNotification {
  /// The server's notificationId; remembers which ones were read.
  final String id;
  final bool isRead;
  final String orderId;
  final String title;
  final NotificationStatus status;
  final DateTime time;

  const AppNotification({
    this.id = '',
    this.isRead = false,
    required this.orderId,
    required this.title,
    required this.status,
    required this.time,
  });

  /// Builds one from the API's NotificationDto:
  /// `{ notificationId, title, message, orderId, isRead, sentAt }`.
  /// The API has no stage, so it is worked out from the wording.
  factory AppNotification.fromApi(Map<String, dynamic> json) {
    final title = (json['title'] as String?) ?? '';
    final message = (json['message'] as String?) ?? '';
    final text = '$title $message'.toLowerCase();

    NotificationStatus status;
    if (text.contains('payment')) {
      status = NotificationStatus.payment;
    } else if (text.contains('deliver')) {
      status = NotificationStatus.delivered;
    } else if (text.contains('clean') || text.contains('wash')) {
      status = NotificationStatus.inCleaning;
    } else if (text.contains('pick') || text.contains('collect')) {
      status = NotificationStatus.pickedUp;
    } else if (text.contains('confirm') || text.contains('accept')) {
      status = NotificationStatus.confirmed;
    } else {
      status = NotificationStatus.update;
    }

    final sent = (json['sentAt'] ?? json['createdAt']) as String?;

    // The server now puts the order number in every message. Older ones do
    // not, so take it from the title ("Order SC-1111 cancelled") instead.
    var shown = message.isEmpty ? title : message;
    final number = RegExp(r'^(?:Issue with order|Order) (\S+)', caseSensitive: false)
        .firstMatch(title)
        ?.group(1);
    if (number != null && !shown.contains(number)) {
      shown = 'Order $number: $shown';
    }

    return AppNotification(
      id: (json['notificationId'] as String?) ?? '',
      isRead: (json['isRead'] as bool?) ?? false,
      orderId: (json['orderId'] as String?) ?? '',
      title: shown,
      status: status,
      time: DateTime.tryParse(sent ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

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
