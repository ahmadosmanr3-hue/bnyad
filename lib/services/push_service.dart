import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/notification_service.dart';

/// Must be a top-level function for background FCM delivery.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final title = message.notification?.title ?? message.data['title'] ?? 'BNYAD';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (body.isEmpty) return;
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.showServerNotification(
      id: message.hashCode.abs() % 100000,
      title: title,
      body: body,
    );
  } catch (e) {
    debugPrint('Background FCM display error: $e');
  }
}

/// Firebase Cloud Messaging — delivers admin notifications when the app is closed.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;
  bool _listenersBound = false;
  bool _registering = false;
  VoidCallback? onNotificationOpened;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _ready = true;
      debugPrint('PushService: Firebase initialized');
    } catch (e) {
      debugPrint('PushService: Firebase not configured ($e). Push disabled.');
    }
  }

  /// Call after the user logs in and has an API token.
  Future<void> registerForUser(ApiService api) async {
    if (kIsWeb || !_ready || !api.hasToken || _registering) return;
    _registering = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.registerFcmToken(token);
        debugPrint('PushService: FCM token registered');
      }

      if (_listenersBound) return;
      _listenersBound = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        if (api.hasToken) api.registerFcmToken(t);
      });

      FirebaseMessaging.onMessage.listen((message) async {
        final title =
            message.notification?.title ?? message.data['title'] ?? 'BNYAD';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        if (body.isEmpty) return;
        await NotificationService.instance.showServerNotification(
          id: message.hashCode.abs() % 100000,
          title: title,
          body: body,
        );
      });

      // Handle notification taps when the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onNotificationOpened?.call();
      });

      // Handle notification taps when the app is opened from a terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          onNotificationOpened?.call();
        }
      });
    } catch (e) {
      debugPrint('PushService register error: $e');
    } finally {
      _registering = false;
    }
  }
}
