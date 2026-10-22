import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';

/// The single bottom navigation bar used by the main tabs.
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.access_time, 'Orders'),
    (Icons.calendar_month_outlined, 'Schedule'),
    (Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (index) {
              final active = index == selectedIndex;
              final color = active ? AppColors.primary : AppColors.textGrey;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[index].$1, color: color, size: 24),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        _items[index].$2,
                        style: (active ? AppText.captionStrong : AppText.caption)
                            .copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
