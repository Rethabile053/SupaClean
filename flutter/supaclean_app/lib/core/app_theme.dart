import 'package:flutter/material.dart';
import 'constants.dart';

/// 8-point spacing scale.
class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

class AppRadius {
  /// Text fields, small controls.
  static const double control = 12;

  /// Cards and sheets.
  static const double card = 16;
  static const double pill = 999;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}

/// Four sizes (12, 14, 18, 26) and two weights (regular, bold) app-wide.
class AppText {
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textGrey,
  );

  static const TextStyle captionStrong = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.textBody,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle display = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  /// Equal-width digits so prices, quantities, order numbers and times
  /// line up. Wrap any style that shows numbers.
  static TextStyle figures(TextStyle style) => style.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
