import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'primary_button.dart';

/// Friendly empty screen: soft tinted icon, a headline, one line of help
/// and an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpace.s24),
            Text(title, textAlign: TextAlign.center, style: AppText.title),
            const SizedBox(height: AppSpace.s8),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.s24),
              PrimaryButton(
                text: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Something went wrong: calm copy and a retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We could not load this. Please check your connection '
        'and try again.',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: title,
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
