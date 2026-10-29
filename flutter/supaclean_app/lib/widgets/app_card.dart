import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import 'pressable.dart';

/// The one card style: white, 16px radius, 1px hairline, 16px padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.s16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );

    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}
