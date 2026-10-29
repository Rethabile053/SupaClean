import 'package:flutter/material.dart';

/// The app's original colours (same as `develop`), plus a few extras used by
/// the notification and confirmation screens. Order statuses use the tones
/// in status_badge.dart rather than the brand red.
class AppColors {
  static const Color primary = Color(0xFFEC1B5B);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF8A8A8A);
  static const Color border = Color(0xFFE5E5E5);
  static const Color background = Colors.white;

  static const Color surface = Colors.white;
  static const Color textBody = Color(0xFF3D424D);

  /// Brand red at ~8%: soft icon backgrounds.
  static const Color primaryTint = Color(0x14EC1B5B);
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
