import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../views/notification_center_screen.dart';

/// Runs in a separate isolate when a push arrives while the app is in the
/// background or closed. Android already shows messages that carry a
/// notification payload, so this makes sure Firebase is ready.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Receives pushes sent by the ASP.NET admin through Firebase (FCM).
///
/// ASP.NET -> Firebase -> this phone.
/// Use [init] once at startup, then [registerDevice] after sign-in.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  /// Must match the channel ID used in AndroidManifest.xml and by the server.
  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'orders',
    'Order updates',
    description: 'Updates about your orders and payments',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;

  bool _ready = false;

  /// This phone's Firebase Cloud Messaging token.
  String? token;

  /// Called when the token is obtained or refreshed.
  Future<void> Function(String token)? onTokenReady;

  /// Fires whenever a push arrives while the app is open, so the
  /// Notification Center can reload and show it straight away.
  final StreamController<void> arrivals = StreamController<void>.broadcast();

  /// Call once, right after Firebase.initializeApp.
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // flutter_local_notifications 18.0.1 uses a positional
    // InitializationSettings argument.
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) {
        _openNotificationCenter();
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // While the app is open, display incoming FCM notifications locally.
    FirebaseMessaging.onMessage.listen(_showWhileOpen);

    // Handle a notification tapped while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _openNotificationCenter();
    });

    // Handle a notification tap that launched the app from a closed state.
    final launchMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (launchMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationCenter();
      });
    }

    // Keep the classic FCM token for the ASP.NET Firebase Admin backend.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleToken);

    _ready = true;
  }

  /// Browsers need the project's "web push certificate" public key (Firebase
  /// console > Project settings > Cloud Messaging > Web Push certificates).
  /// It is public, so it is built in. --dart-define=FCM_VAPID_KEY=... can
  /// override it, for example to use a different Firebase project.
  static const String _webVapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue:
        'BBa9VO33Hyxy4khjnuxqVOKbCf9mkfMhOafEkNkmZoxrnMUAZ8PMydqeoJr69oKo3TBK_yZzkTipKkpbfBXg8-c',
  );

  /// Requests permission and obtains this device's FCM token.
  Future<void> registerDevice() async {
    if (!_ready) return;

    if (kIsWeb && _webVapidKey.isEmpty) {
      debugPrint(
        'Push: web push is off. Run with --dart-define=FCM_VAPID_KEY=... '
        'to turn it on.',
      );
      return;
    }

    final settings =
        await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push: notification permission denied.');
      return;
    }

    // ignore: deprecated_member_use
    final newToken = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    await _handleToken(newToken);
  }

  Future<void> _handleToken(String? newToken) async {
    if (newToken == null || newToken.isEmpty) return;

    token = newToken;

    debugPrint('Push: FCM token = $newToken');

    try {
      await onTokenReady?.call(newToken);
    } catch (error) {
      // The server may be unavailable; keep the app running.
      debugPrint(
        'Push: could not send the token to the server: $error',
      );
    }
  }

  /// Displays an FCM notification locally while the app is open.
  Future<void> _showWhileOpen(RemoteMessage message) async {
    arrivals.add(null);
    final notification = message.notification;

    if (notification == null) return;

    // flutter_local_notifications 18.0.1 expects these as positional
    // arguments: id, title, body, and notification details.
    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['orderId']?.toString(),
    );
  }

  /// Opens the notification centre screen.
  void _openNotificationCenter() {
    _navigatorKey?.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }
}
