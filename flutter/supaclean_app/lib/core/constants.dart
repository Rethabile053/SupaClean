import 'package:flutter/material.dart';

/// Colour tokens. Roughly 60% neutral (white and canvas), 30% near-black,
/// 10% brand red: primary buttons, the active nav item and one key
/// indicator per screen. Normal order statuses use the status tones in
/// status_badge.dart, never the brand red.
class AppColors {
  // Brand
  static const Color primary = Color(0xFFEC1B5B);

  /// Brand red at ~5% and ~8%: selected chips, secondary buttons, highlights.
  static const Color primarySoft = Color(0x0DEC1B5B);
  static const Color primaryTint = Color(0x14EC1B5B);

  // Neutrals
  static const Color background = Colors.white;
  static const Color surface = Colors.white;

  /// Light cool grey behind cards.
  static const Color canvas = Color(0xFFF6F7F9);
  static const Color border = Color(0xFFE5E7EB);

  // Text tiers: headings 100%, body ~80%, secondary ~65% (AA on white).
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textBody = Color(0xFF3D424D);
  static const Color textGrey = Color(0xFF6B7280);

  /// Soft backgrounds for service categories and illustrations only.
  static const List<Color> categoryTints = [
    Color(0xFFE6F4F7), // aqua
    Color(0xFFE8F0FB), // sky
    Color(0xFFE8F5EE), // mint
    Color(0xFFFFF4E0), // sand
    Color(0xFFEEF0FB), // lavender
  ];
}

class AppStrings {
  static const String appName = 'SupaClean';
  static const String welcomeBack = 'Welcome Back';
  static const String signInSubtitle = 'Sign in to your SupaClean account';
  static const String createAccount = 'Create Your Account';
  static const String joinToday = 'Join SupaClean today';
}
class SupabaseConfig {
  static const String url = 'https://anuayvbkxntskuuewxae.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFudWF5dmJreG50c2t1dWV3eGFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTI3MTAsImV4cCI6MjEwNzEyODcxMH0.LNf8BfKa0TxHXf_zRO1bwT7gZpyYFDHK8IAOMHYDHsc';
}
