import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const SupaCleanApp(),
    ),
  );
}

class SupaCleanApp extends StatelessWidget {
  const SupaCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
