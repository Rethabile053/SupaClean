import 'package:flutter/material.dart';

/// The round pink back arrow used on every screen (as on Notifications).
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onTap});

  /// Defaults to going back one screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap ?? () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE9EA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xFFE5393D),
            size: 21,
          ),
        ),
      ),
    );
  }
}
