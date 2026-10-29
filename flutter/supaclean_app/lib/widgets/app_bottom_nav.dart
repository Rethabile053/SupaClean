import 'package:flutter/material.dart';
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (index) {
              final active = index == selectedIndex;
              final color = active ? AppColors.primary : Colors.blueGrey;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[index].$1, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        _items[index].$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                        ),
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
