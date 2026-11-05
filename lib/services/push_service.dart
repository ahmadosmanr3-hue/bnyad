import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/notification_service.dart';
import 'package:nutrify/services/push_policy.dart';

/// Must be a top-level function for background FCM delivery.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Visible notification payloads are displayed by iOS/Android themselves.
  if (!shouldDisplayBackgroundPush(
    hasSystemNotification: message.notification != null,
  )) {
    return;
  }
  final title = message.notification?.title ?? message.data['title'] ?? 'BNYAD';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (body.isEmpty) return;
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.showServerNotification(
      id:
          int.tryParse(message.data['notificationId'] ?? '') ??
          message.hashCode.abs() % 100000,
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
  ApiService? _api;
  String? _registeredToken;
  VoidCallback? onNotificationOpened;
  VoidCallback? onEntitlementsChanged;
  String? openedRoute;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      NotificationService.instance.onServerNotificationOpened = () {
        openedRoute = NotificationService.instance.lastServerRoute;
        onNotificationOpened?.call();
      };
      _ready = true;
      debugPrint('PushService: Firebase initialized');
    } catch (e) {
      debugPrint('PushService: Firebase not configured ($e). Push disabled.');
    }
  }

  /// Call after the user logs in and has an API token.
  Future<void> registerForUser(ApiService api) async {
    if (kIsWeb || !_ready || !api.hasToken || _registering) return;
    _api = api;
    _registering = true;

    try {
      _bindListeners();
      final owner = api.userId;
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        if (!await waitForApnsToken(FirebaseMessaging.instance.getAPNSToken)) {
          debugPrint(
            'PushService: APNs registration pending; retry on resume.',
          );
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && api.hasToken && api.userId == owner) {
        final saved = await api.registerFcmToken(token);
        if (saved) _registeredToken = token;
        debugPrint(
          'PushService: device registration ${saved ? 'saved' : 'pending'}',
        );
      }
    } catch (_) {
      debugPrint('PushService: registration unavailable; retry on resume.');
    } finally {
      _registering = false;
    }
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        final api = _api;
        if (api == null || !api.hasToken) return;
        if (await api.registerFcmToken(token)) _registeredToken = token;
      },
      onError: (Object _) {
        debugPrint('PushService: token refresh unavailable.');
      },
    );
    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data['route'] == 'premium-gifts') {
        onEntitlementsChanged?.call();
      }
      final title =
          message.notification?.title ?? message.data['title'] ?? 'BNYAD';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (body.isEmpty) return;
      await NotificationService.instance.init();
      await NotificationService.instance.showServerNotification(
        id:
            int.tryParse(message.data['notificationId'] ?? '') ??
            message.hashCode.abs() % 100000,
        title: title,
        body: body,
        route: message.data['route'] == 'premium-gifts'
            ? 'premium-gifts'
            : 'server-notifications',
      );
    });

    // Handle notification taps when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      openedRoute = message.data['route'];
      onNotificationOpened?.call();
    });

    // Handle notification taps when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        openedRoute = message.data['route'];
        onNotificationOpened?.call();
      }
    });
  }

  /// Remove only this device before revoking the authenticated session.
  Future<void> unregisterForUser(ApiService api) async {
    if (kIsWeb || !_ready) return;
    _api = null;
    try {
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await api.unregisterFcmToken(token);
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _registeredToken = null;
  }
}
