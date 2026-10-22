import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Semantic colours for statuses. None of these is the brand red, so a
/// normal status never reads as an alert.
enum StatusTone {
  /// Placed, confirmed, waiting.
  neutral(Color(0xFF475467), Color(0xFFEEF1F5)),

  /// Picked up, in cleaning, out for delivery.
  progress(Color(0xFF1D5FB8), Color(0xFFE6F0FB)),

  /// Needs attention but is not a failure.
  warning(Color(0xFF9A5B00), Color(0xFFFFF1D6)),

  /// Ready, delivered, completed, paid.
  success(Color(0xFF1E7B3A), Color(0xFFE4F4E9)),

  /// Cancelled or failed.
  danger(Color(0xFFC0262D), Color(0xFFFCE8E9));

  const StatusTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Maps an order status string (as used by LaundryOrder.status) to a tone.
StatusTone toneForOrderStatus(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'delivered':
    case 'ready for collection':
      return StatusTone.success;
    case 'cancelled':
    case 'failed':
      return StatusTone.danger;
    case 'order placed':
    case 'confirmed':
      return StatusTone.neutral;
    default:
      return StatusTone.progress;
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  /// Badge for an order status string, coloured from its meaning.
  StatusBadge.order(String status, {super.key})
      : label = status,
        tone = toneForOrderStatus(status);

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s12,
        vertical: AppSpace.s4 + 2,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.captionStrong.copyWith(color: tone.foreground),
      ),
    );
  }
}
