import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      // Supabase restores the saved session, so returning users skip login.
      final loggedIn = context.read<AuthViewModel>().isLoggedIn;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              loggedIn ? const MainShell() : const LoginScreen(),
        ),
      );
    });
  }

  static const _subtitleStyle = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: Color(0xFF5B6475),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    const AppLogo(fontSize: 40),
                    const SizedBox(height: 4),
                    const Text(
                      'DRY CLEANERS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF5B6475),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Dry Clean made simple.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text.rich(
                        TextSpan(
                          style: _subtitleStyle,
                          children: [
                            TextSpan(
                              text: 'We pick up, clean and deliver to you.\n'
                                  'Right here in ',
                            ),
                            TextSpan(
                              text: 'Bloemfontein',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    // The PNG has its own rounded corners and a transparent
                    // margin, so it spans the full screen width.
                    Image.asset(
                      'assets/images/illustration-container.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    const Spacer(),
                    const Text(
                      'CLEAN. FAST. RELIABLE.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
