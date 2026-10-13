import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// v2 channel so Android picks up the custom sound (channels are immutable).
  static const _channelId = 'meal_reminders_v2';
  static const _channelName = 'Meal Reminders';
  static const _channelDesc = 'Daily meal reminder notifications';
  static const _soundResource = 'meal_chime';

  static const _weeklyChannelId = 'weekly_summary_v2';
  static const _weeklyChannelName = 'Weekly summary';
  static const _weeklyChannelDesc = 'Weekly nutrition digest';

  static const _supplementChannelId = 'supplement_reminders_v1';
  static const _supplementChannelName = 'Supplement Reminders';
  static const _supplementChannelDesc = 'Daily pill and supplement reminders';

  static const int weeklySummaryNotifId = 104;
  static const int _supplementNotifBaseId = 200;
  static const int _supplementNotifRange = 800;

  static const Map<String, int> mealNotifId = {
    'breakfast': 100,
    'lunch': 101,
    'dinner': 102,
    'snacks': 103,
  };

  static const _mealAndroidSound =
      RawResourceAndroidNotificationSound(_soundResource);
  static const _weeklyAndroidSound =
      RawResourceAndroidNotificationSound(_soundResource);

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _refreshLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local Notification tapped: id=${response.id}, payload=${response.payload}');
      },
    );

    await _requestPermissions();

    _initialized = true;
    debugPrint('NotificationService initialized (tz: ${tz.local.name})');
  }

  Future<void> _refreshLocalTimeZone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Timezone lookup failed ($e), using offset fallback');
      tz.setLocalLocation(tz.getLocation(_offsetFallbackTimeZone()));
    }
  }

  String _offsetFallbackTimeZone() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    if (minutes == 30 && hours == 5) return 'Asia/Kolkata';
    if (minutes == 30 && hours == 4) return 'Asia/Kabul';
    const knownZones = {
      3: 'Asia/Baghdad',
      4: 'Asia/Dubai',
      2: 'Europe/Istanbul',
      1: 'Europe/Paris',
      0: 'UTC',
      -5: 'America/New_York',
      -8: 'America/Los_Angeles',
      5: 'Asia/Karachi',
      9: 'Asia/Tokyo',
      8: 'Asia/Shanghai',
    };
    return knownZones[hours] ?? 'UTC';
  }

  Future<void> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          final granted = await android.requestNotificationsPermission();
          debugPrint('Android notification permission: $granted');
          await android.requestExactAlarmsPermission();
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('iOS notification permission: $granted');
        }
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  AndroidNotificationDetails _mealAndroidDetails(String body) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: _mealAndroidSound,
      audioAttributesUsage: AudioAttributesUsage.notification,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );
  }

  AndroidNotificationDetails _weeklyAndroidDetails(String body) {
    return AndroidNotificationDetails(
      _weeklyChannelId,
      _weeklyChannelName,
      channelDescription: _weeklyChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      sound: _weeklyAndroidSound,
      audioAttributesUsage: AudioAttributesUsage.notification,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
    );
  }

  AndroidNotificationDetails _supplementAndroidDetails(String body) {
    return AndroidNotificationDetails(
      _supplementChannelId,
      _supplementChannelName,
      channelDescription: _supplementChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: _mealAndroidSound,
      audioAttributesUsage: AudioAttributesUsage.notification,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );
  }

  /// Stable notification id for a supplement entry (200–999 range).
  static int supplementNotifId(String vitaminId) =>
      _supplementNotifBaseId + (vitaminId.hashCode.abs() % _supplementNotifRange);

  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  Future<void> scheduleMealReminder({
    required String mealId,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService not initialized, skipping schedule');
      return;
    }

    await _refreshLocalTimeZone();

    final id = mealNotifId[mealId];
    if (id == null) return;

    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: _mealAndroidDetails(body),
        iOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        'Scheduled [$mealId] at $hour:${minute.toString().padLeft(2, '0')} '
        '(next fire: $scheduled)');
  }

  Future<void> cancelMealReminder(String mealId) async {
    final id = mealNotifId[mealId];
    if (id == null) return;
    await _plugin.cancel(id);
    debugPrint('Cancelled $mealId reminder');
  }

  Future<void> scheduleSupplementReminder({
    required String vitaminId,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService not initialized, skipping supplement schedule');
      return;
    }

    await _refreshLocalTimeZone();

    final id = supplementNotifId(vitaminId);
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: _supplementAndroidDetails(body),
        iOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        'Scheduled supplement [$vitaminId] at $hour:${minute.toString().padLeft(2, '0')} '
        '(next fire: $scheduled)');
  }

  Future<void> cancelSupplementReminder(String vitaminId) async {
    await _plugin.cancel(supplementNotifId(vitaminId));
    debugPrint('Cancelled supplement reminder for $vitaminId');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Re-syncs timezone and re-schedules enabled reminders (call on app resume).
  Future<void> refreshSchedules({
    required Future<void> Function() rescheduleAll,
  }) async {
    if (!_initialized) return;
    await _refreshLocalTimeZone();
    await rescheduleAll();
  }

  /// Repeats every week on Sunday at [hour]:[minute] local time.
  Future<void> scheduleWeeklySummary({
    required String title,
    required String body,
    int hour = 10,
    int minute = 0,
  }) async {
    if (!_initialized) return;
    await _refreshLocalTimeZone();
    await _plugin.cancel(weeklySummaryNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      weeklySummaryNotifId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: _weeklyAndroidDetails(body),
        iOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    debugPrint('Weekly summary scheduled: next $scheduled');
  }

  Future<void> cancelWeeklySummary() async {
    await _plugin.cancel(weeklySummaryNotifId);
    debugPrint('Weekly summary notification cancelled');
  }

  /// Shows a notification pushed from the admin panel / server.
  Future<void> showServerNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      // Offset to avoid colliding with meal (100-104) / test (999) ids.
      200000 + id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: _mealAndroidSound,
          audioAttributesUsage: AudioAttributesUsage.notification,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        ),
        iOS: _darwinDetails,
      ),
    );
  }

  Future<void> showTestNotification() async {
    if (!_initialized) return;

    const body = 'Notifications are working!';
    await _plugin.show(
      999,
      'BNYAD',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: _mealAndroidSound,
          audioAttributesUsage: AudioAttributesUsage.notification,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: _darwinDetails,
      ),
    );
  }
}
