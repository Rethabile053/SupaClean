import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'pressable.dart';

/// A selectable pill: service filters, time slots, instruction quick-picks.
/// At least 44pt tall. Selected: faint red fill, red border and text.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Disabled chips stay visible but dimmed (for unavailable slots).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color foreground = !enabled
        ? AppColors.textGrey.withValues(alpha: 0.5)
        : selected
            ? AppColors.primary
            : AppColors.textBody;

    return Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpace.s8),
            ],
            Text(
              label,
              style: (selected ? AppText.bodyStrong : AppText.body)
                  .copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
