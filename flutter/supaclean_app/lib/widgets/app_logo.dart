import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  const AppLogo({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Supa',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Clean',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
