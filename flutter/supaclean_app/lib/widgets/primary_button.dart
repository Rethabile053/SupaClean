import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'pressable.dart';

enum ButtonVariant {
  /// Solid brand red. One per screen, in the thumb zone.
  primary,

  /// Brand red text on a faint red tint.
  secondary,

  /// White with a hairline border.
  outline,
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;

  /// Full width by default; false sizes the button to its label.
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final Color background;
    final Color foreground;
    BorderSide? border;
    switch (variant) {
      case ButtonVariant.primary:
        background = enabled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.4);
        foreground = Colors.white;
      case ButtonVariant.secondary:
        background = AppColors.primaryTint;
        foreground = AppColors.primary;
      case ButtonVariant.outline:
        background = Colors.white;
        foreground = AppColors.textDark;
        border = const BorderSide(color: AppColors.border);
    }

    final label = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: AppSpace.s8),
              ],
              Text(
                text,
                style: AppText.bodyStrong.copyWith(color: foreground),
              ),
            ],
          );

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: expand ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 52, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: border == null ? null : Border.fromBorderSide(border),
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: label),
      ),
    );
  }
}
