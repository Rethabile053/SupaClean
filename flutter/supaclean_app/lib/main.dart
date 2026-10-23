import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'services/order_api.dart';
import 'services/push_notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/splash_screen.dart';

/// Lets push notifications open screens without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app still works without push if Firebase fails to start.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.instance.init(navigatorKey);
  } catch (error) {
    debugPrint('Push notifications unavailable: $error');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  // Tell the server where to send this phone's push notifications.
  // Does nothing until the app is signed in and the API address is set.
  PushNotificationService.instance.onTokenReady = (token) async {
    final api = OrderApi();
    if (!api.isConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      return;
    }
    await api.registerDevice(token);
  };

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
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
