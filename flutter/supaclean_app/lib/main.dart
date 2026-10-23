
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'firebase_options.dart';
import 'services/order_api.dart';
import 'services/push_notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/splash_screen.dart';

/// Allows notifications to navigate without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and push notifications.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await PushNotificationService.instance.init(navigatorKey);
  } catch (error) {
    debugPrint('Push notifications unavailable: $error');
  }

  // Initialize Supabase.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  // Register this device's FCM token with ASP.NET when possible.
  PushNotificationService.instance.onTokenReady = (token) async {
    final api = OrderApi();

    if (!api.isConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      debugPrint(
        'Push: token not registered. '
        'API unavailable or user not signed in.',
      );
      return;
    }

    await api.registerDevice(token);
  };

  // Request permission and obtain the FCM token.
  // If the user is not signed in yet, register it after sign-in as well.
  try {
    await PushNotificationService.instance.registerDevice();
  } catch (error) {
    debugPrint('Push device registration failed: $error');
  }

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
      navigatorKey: navigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 13,
          ),
          hintStyle: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
