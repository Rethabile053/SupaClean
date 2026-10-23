import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../views/notification_center_screen.dart';

/// Runs in a separate isolate when a push arrives while the app is in the
/// background or closed. Android already shows messages that carry a
/// notification payload, so this only makes sure Firebase is ready.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Receives pushes sent by the ASP.NET admin through Firebase (FCM).
///
/// ASP.NET -> Firebase -> this phone. Use [init] once at start-up, then
/// [registerDevice] after the user is signed in.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// Must match default_notification_channel_id in AndroidManifest.xml and
  /// the channel id ASP.NET sends in its Android notification settings.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'orders',
    'Order updates',
    description: 'Updates about your orders and payments',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _ready = false;

  /// This phone's Firebase address. ASP.NET needs it to send pushes here.
  String? token;

  /// Called whenever the token is first obtained or changes. Assign this to
  /// upload the token to the backend (see the setup steps for the API).
  Future<void> Function(String token)? onTokenReady;

  /// Call once, right after Firebase.initializeApp.
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      // Tapped a notification we showed while the app was open.
      onDidReceiveNotificationResponse: (_) => _openNotificationCenter(),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // App open: Firebase shows nothing by itself, so show it ourselves.
    FirebaseMessaging.onMessage.listen(_showWhileOpen);

    // Tapped a notification while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp
        .listen((_) => _openNotificationCenter());

    // Tapped a notification that started the app from closed.
    final launchMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (launchMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openNotificationCenter());
    }

    // Deprecated in favour of register()/onRegistered, which return a
    // Firebase Installation ID. ASP.NET's FirebaseAdmin sends to the classic
    // FCM token, so keep using it.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleToken);

    _ready = true;
  }

  /// Asks permission (Android 13+ shows a dialog) and gets this phone's
  /// token. Does nothing when Firebase failed to start.
  Future<void> registerDevice() async {
    if (!_ready) return;

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push: notification permission denied.');
      return;
    }

    // ignore: deprecated_member_use
    await _handleToken(await FirebaseMessaging.instance.getToken());
  }

  Future<void> _handleToken(String? newToken) async {
    if (newToken == null || newToken.isEmpty) return;
    token = newToken;
    debugPrint('Push: FCM token = $newToken');
    try {
      await onTokenReady?.call(newToken);
    } catch (error) {
      // The server may be down or not have the endpoint yet; the app must
      // keep working. The token is sent again next time the app starts.
      debugPrint('Push: could not send the token to the server: $error');
    }
  }

  Future<void> _showWhileOpen(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['orderId'],
    );
  }

  void _openNotificationCenter() {
    _navigatorKey?.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
  }
}
