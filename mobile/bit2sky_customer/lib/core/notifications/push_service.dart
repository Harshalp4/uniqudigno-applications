import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/dio_client.dart';

/// FCM background/terminated-isolate handler. Must be a top-level (or static)
/// function marked `@pragma('vm:entry-point')` — the isolate is spun up fresh,
/// so Firebase has to be re-initialised here. Notification-payload messages are
/// drawn by the system tray automatically; this exists so data-only messages
/// still wake a valid isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured in this build — nothing to handle.
  }
}

/// Wraps Firebase Cloud Messaging: initialisation, the runtime notification
/// permission, foreground display (FCM does NOT show notifications while the app
/// is foregrounded), and registering the device token with the backend.
///
/// Every entry point degrades to a no-op when Firebase is unavailable (no
/// `google-services.json`), so the app runs identically with push simply off.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _firebaseUp = false;
  bool _refreshSubscribed = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications',
    description: 'Order updates, reports, and account alerts.',
    importance: Importance.high,
  );

  /// Initialises Firebase + local notifications and wires foreground handling.
  /// Call once at startup, before `runApp`. Safe when Firebase isn't configured.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await Firebase.initializeApp();
      _firebaseUp = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[push] Firebase not configured — push disabled ($e)');
      }
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Prompts on Android 13+ / iOS. Harmless (returns current status) elsewhere.
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return; // data-only: nothing to draw
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Uploads this device's FCM token so the backend can target it. Call after a
  /// successful login (an auth token is required) and on startup when already
  /// signed in. Re-registers automatically when FCM rotates the token.
  Future<void> registerDevice(DioClient dio) async {
    if (!_firebaseUp) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(dio, token);

      if (!_refreshSubscribed) {
        _refreshSubscribed = true;
        FirebaseMessaging.instance.onTokenRefresh
            .listen((t) => _sendToken(dio, t));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[push] registerDevice failed: $e');
    }
  }

  Future<void> _sendToken(DioClient dio, String token) async {
    final platform = (!kIsWeb && Platform.isIOS) ? 'Ios' : 'Android';
    try {
      await dio.postData<dynamic>(
        '/devices/register',
        body: {'fcmToken': token, 'platform': platform},
      );
    } catch (e) {
      // A 401 here just means the session lapsed; the next login re-registers.
      if (kDebugMode) debugPrint('[push] token upload skipped: $e');
    }
  }
}
