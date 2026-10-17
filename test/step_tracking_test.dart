import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/activity/step_health_provider.dart';
import 'package:nutrify/activity/step_models.dart';
import 'package:nutrify/activity/step_strings.dart';
import 'package:nutrify/activity/step_tracker.dart';
import 'package:nutrify/activity/step_widgets.dart';
import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/main.dart' show BnyadApp;
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';

class MemoryStepStore extends StepSettingsStore {
  final values = <String, String>{};
  bool failWrite = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage locked');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class FakeHealth extends StepHealthProvider {
  HealthAccess permissions = const HealthAccess(
    HealthAvailability.available,
    HealthPermission.granted,
  );
  bool allowed = true;
  int requests = 0, reads = 0, accesses = 0;
  int? count = 6420;
  Future<List<StepDay>> Function(List<StepWindow>)? reader;
  @override
  Future<HealthAccess> access() async {
    accesses++;
    return permissions;
  }

  @override
  Future<bool> requestAccess() async {
    requests++;
    return allowed;
  }

  @override
  Future<List<StepDay>> readDays(List<StepWindow> windows) async {
    reads++;
    return reader?.call(windows) ?? [StepDay(windows.first.date, count)];
  }

  @override
  Future<void> openSettings() async {}
}

UserProfile profile([Map<String, dynamic> extra = const {}]) =>
    UserProfile.fromMap({
      'uid': 'fictional',
      'age': 30,
      'height': 175,
      'weight': 70,
      'activityLevel': 'moderatelyActive',
      ...extra,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var now = DateTime(2026, 10, 16, 12);
  late FakeHealth health;
  late MemoryStepStore store;
  late StepTracker tracker;
  setUp(() {
    now = DateTime(2026, 10, 16, 12);
    health = FakeHealth();
    store = MemoryStepStore();
    tracker = StepTracker(
      provider: health,
      store: store,
      profile: () => profile(),
      clock: () => now,
    );
  });
  tearDown(() => tracker.dispose());

  List<StepDay> history(int count) => [
    for (final window in stepWindows(now).skip(1)) StepDay(window.date, count),
  ];
  int? suggest(
    List<StepDay> days, {
    Set<String>? confirmed,
    int goal = 5000,
    DateTime? accepted,
    bool gentle = false,
  }) => suggestedStepGoal(
    days: days,
    confirmedDays: confirmed ?? days.map((d) => d.date).toSet(),
    currentGoal: goal,
    now: now,
    lastAccepted: accepted,
    gentle: gentle,
  );

  test('conservative starting goals follow existing activity keys', () {
    expect(initialStepGoal(profile({'activityLevel': 'sedentary'})), 3000);
    expect(initialStepGoal(profile({'activityLevel': 'lightlyActive'})), 4000);
    expect(initialStepGoal(profile()), 5000);
    expect(initialStepGoal(profile({'activityLevel': 'veryActive'})), 6000);
    expect(initialStepGoal(profile({'activityLevel': 'extraActive'})), 6500);
    expect(initialStepGoal(null), 3000);
  });
  test('gentle profiles never receive automatic increases', () {
    for (final extra in [
      {
        'disabilities': ['limitedMobility'],
      },
      {'age': 15},
      {'age': 70},
      {'pregnancyStatus': 'pregnant'},
      {'pregnancyStatus': 'breastfeeding'},
    ]) {
      expect(needsGentleStepGoals(profile(extra)), isTrue);
      expect(initialStepGoal(profile(extra)), 1000);
    }
    expect(suggest(history(9000), gentle: true), isNull);
  });
  test('missing records and today never count as complete days', () {
    final days = history(5000).take(6).toList()
      ..add(StepDay(stepDateKey(now), 90000))
      ..add(StepDay(stepWindows(now).last.date, null));
    expect(suggest(days), isNull);
    expect(suggest(history(5000), confirmed: {}), isNull);
  });
  test(
    'at least seven explicitly confirmed days, no duplicate day weighting',
    () {
      final six = history(5000).take(6).toList();
      expect(suggest([...six, six.first]), isNull);
      expect(suggest(history(5000).take(7).toList()), 5250);
    },
  );
  test(
    'median resists outliers and gradual increase is capped at 5 percent',
    () {
      expect(
        suggest([
          ...history(4800).take(8),
          StepDay(stepWindows(now).last.date, 95000),
        ]),
        5040,
      );
      expect(suggest(history(30000)), 5250);
      expect(suggest(history(30000), goal: 12000), isNull);
      expect(suggest(history(2000)), 4750);
      expect(suggest(history(5000), goal: 100), isNull);
    },
  );
  test('confirmed true zero is distinct from missing and does not crash', () {
    expect(suggest(history(0)), 4750);
    expect(
      suggest([for (final d in history(0)) StepDay(d.date, null)]),
      isNull,
    );
  });
  test('future, too-old and corrupt days are excluded', () {
    expect(suggest([for (final d in history(0)) StepDay(d.date, -1)]), isNull);
    expect(
      suggest([for (final d in history(0)) StepDay(d.date, 100001)]),
      isNull,
    );
    expect(
      suggest([
        for (var i = 20; i < 30; i++)
          StepDay(
            stepDateKey(DateTime(now.year, now.month, now.day - i)),
            5000,
          ),
      ]),
      isNull,
    );
  });
  test('accepted suggestions have a full seven-day cooldown', () {
    expect(
      suggest(history(9000), accepted: now.subtract(const Duration(days: 6))),
      isNull,
    );
    expect(
      suggest(history(9000), accepted: now.subtract(const Duration(days: 7))),
      5250,
    );
    expect(
      suggest(history(9000), accepted: now.add(const Duration(days: 1))),
      isNull,
    );
  });
  test(
    'walking estimate uses weight and conservative stride, no resting energy',
    () {
      final value = estimateWalking(steps: 6420, weightKg: 70, heightCm: 175)!;
      expect(value.kilometers, closeTo(4.494, .0001));
      expect(value.calories, 141);
      expect(
        estimateWalking(steps: 0, weightKg: 70, heightCm: 175)!.calories,
        0,
      );
      expect(
        estimateWalking(steps: 10000, weightKg: 70, heightCm: 250)!.kilometers,
        7.5,
      );
    },
  );
  test('optional distance can only reduce a step-based calorie estimate', () {
    expect(
      estimateWalking(
        steps: 6420,
        weightKg: 70,
        heightCm: 175,
        distanceMeters: 2000,
      )!.calories,
      63,
    );
    expect(
      estimateWalking(
        steps: 6420,
        weightKg: 70,
        heightCm: 175,
        distanceMeters: 200000,
      )!.calories,
      141,
    );
    expect(
      estimateWalking(
        steps: 6420,
        weightKg: 70,
        heightCm: 175,
        distanceMeters: double.nan,
      )!.calories,
      141,
    );
  });
  test(
    'most recent valid existing weigh-in is used without altering the profile',
    () {
      final person = profile();
      expect(
        latestWalkingWeight(
          {
            '2026-10-15': 68,
            '2026-10-14': 69,
            '2026-10-17': 120,
            '2026-10-16': double.nan,
            'invalid': 100,
          },
          now,
          person.weight,
        ),
        68,
      );
      expect(person.weight, 70);
      expect(latestWalkingWeight({}, now, person.weight), 70);
      expect(latestWalkingWeight({}, now, null), isNull);
    },
  );
  test('missing or invalid personal data never invents calorie estimates', () {
    for (final weight in [
      null,
      -1.0,
      0.0,
      400.0,
      double.nan,
      double.infinity,
    ]) {
      expect(
        estimateWalking(steps: 5000, weightKg: weight, heightCm: 175),
        isNull,
      );
    }
    expect(estimateWalking(steps: null, weightKg: 70, heightCm: 175), isNull);
    expect(estimateWalking(steps: -1, weightKg: 70, heightCm: 175), isNull);
    expect(estimateWalking(steps: 5000, weightKg: 70, heightCm: null), isNull);
  });
  test('manual numeric input supports Arabic and Kurdish digits', () {
    expect(parseStepGoal('٦٤٢٠'), 6420);
    expect(parseStepGoal('۸۰۰۰'), 8000);
    expect(parseStepGoal(' 1 '), 1);
    for (final text in ['0', '-1', '20001', '5.5', 'NaN', '1e4', '']) {
      expect(parseStepGoal(text), isNull);
    }
  });
  test(
    'daily windows are local calendar dates and exclude today from history',
    () {
      final windows = stepWindows(now);
      expect(windows, hasLength(15));
      expect(windows.first.start, DateTime(2026, 10, 16));
      expect(windows.first.end, now);
      expect(windows[1].start, DateTime(2026, 10, 15));
      expect(windows[1].end, DateTime(2026, 10, 16));
    },
  );
  test(
    'no permissions or health reads without explicit account connection',
    () async {
      await tracker.attach('staging|user-a');
      await tracker.refresh(force: true);
      expect(health.requests, 0);
      expect(health.reads, 0);
      expect(tracker.todaySteps, isNull);
      await tracker.connect();
      expect(health.requests, 1);
      expect(health.reads, 1);
      expect(tracker.todaySteps, 6420);
      expect(tracker.goal, 5000);
    },
  );
  test('denied permissions never read health data', () async {
    health.allowed = false;
    await tracker.attach('a');
    await tracker.connect();
    expect(tracker.status, StepStatus.denied);
    expect(tracker.connected, isFalse);
    expect(health.reads, 0);
  });
  test(
    'revocation on resume clears previously displayed totals immediately',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      health.permissions = const HealthAccess(
        HealthAvailability.available,
        HealthPermission.denied,
      );
      tracker.setForeground(false);
      tracker.setForeground(true);
      await Future<void>.delayed(Duration.zero);
      expect(tracker.status, StepStatus.denied);
      expect(tracker.todaySteps, isNull);
      expect(tracker.walking, isNull);
      expect(health.reads, 1);
    },
  );
  test(
    'iOS unknown read status and no data do not falsely claim permission',
    () async {
      health.permissions = const HealthAccess(
        HealthAvailability.available,
        HealthPermission.unknown,
      );
      health.count = null;
      await tracker.attach('a');
      await tracker.connect();
      expect(tracker.status, StepStatus.emptyOrPrivate);
      expect(tracker.todaySteps, isNull);
    },
  );
  test('explicit native zero remains zero, unlike empty data', () async {
    health.count = 0;
    await tracker.attach('a');
    await tracker.connect();
    expect(tracker.status, StepStatus.ready);
    expect(tracker.todaySteps, 0);
  });
  for (final availability in [
    HealthAvailability.unavailable,
    HealthAvailability.installRequired,
  ]) {
    test('unavailable platform: $availability fails safely', () async {
      health.permissions = HealthAccess(availability, HealthPermission.unknown);
      await tracker.attach('a');
      await tracker.connect();
      expect(health.requests, 0);
      expect(health.reads, 0);
      expect(tracker.connected, isFalse);
    });
  }
  test(
    'late sync and health corrections replace totals, never add them',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      health.count = 5900;
      now = now.add(const Duration(minutes: 2));
      await tracker.refresh(force: true);
      expect(tracker.todaySteps, 5900);
      health.count = 6800;
      now = now.add(const Duration(minutes: 2));
      await tracker.refresh(force: true);
      expect(tracker.todaySteps, 6800);
      expect(tracker.progress, 1);
    },
  );
  test(
    'one native aggregate is used, not a manual sum of source records',
    () async {
      health.reader = (windows) async => [StepDay(windows.first.date, 7000)];
      await tracker.attach('a');
      await tracker.connect();
      expect(health.reads, 1);
      expect(tracker.todaySteps, 7000);
    },
  );
  test(
    'restart/device restart reloads preferences but never cached step totals',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      await tracker.setManualGoal(4200);
      final fresh = StepTracker(
        provider: FakeHealth()..count = 25,
        store: store,
        profile: () => profile(),
        clock: () => now,
      );
      addTearDown(fresh.dispose);
      expect(fresh.todaySteps, isNull);
      await fresh.attach('a');
      expect(fresh.goal, 4200);
      expect(fresh.automatic, isFalse);
      expect(fresh.todaySteps, 25);
      final data = jsonDecode(store.values.values.single) as Map;
      expect(data.keys, isNot(contains('steps')));
      expect(data.keys, isNot(contains('distanceMeters')));
      expect(data.keys, isNot(contains('calories')));
    },
  );
  test(
    'manual override pauses recommendations and restoring never changes the goal',
    () async {
      health.reader = (windows) async => [
        StepDay(windows.first.date, 1234),
        ...history(7000),
      ];
      await tracker.attach('a');
      await tracker.connect();
      await tracker.confirmHistory(tracker.pastDays.map((d) => d.date).toSet());
      expect(tracker.recommendation, 5250);
      expect(tracker.goal, 5000);
      await tracker.acceptRecommendation();
      expect(tracker.goal, 5250);
      expect(tracker.recommendation, isNull);
      await tracker.setManualGoal(250);
      expect(tracker.goal, 250);
      expect(tracker.automatic, isFalse);
      await tracker.setAutomatic(true);
      expect(tracker.goal, 250);
      expect(tracker.automatic, isTrue);
    },
  );
  test(
    'account and backend scopes do not share settings, consent or totals',
    () async {
      await tracker.attach('production|a');
      await tracker.connect();
      await tracker.setManualGoal(4000);
      await tracker.attach('staging|a');
      expect(tracker.connected, isFalse);
      expect(tracker.todaySteps, isNull);
      expect(tracker.goal, 5000);
      await tracker.attach('production|b');
      expect(tracker.connected, isFalse);
      await tracker.attach('production|a');
      expect(tracker.connected, isTrue);
      expect(tracker.goal, 4000);
    },
  );
  test(
    'an old account read cannot leak data after switching accounts',
    () async {
      final result = Completer<List<StepDay>>();
      health.reader = (_) => result.future;
      await tracker.attach('a');
      final connecting = tracker.connect();
      await Future<void>.delayed(Duration.zero);
      await tracker.attach('b');
      result.complete([StepDay(stepDateKey(now), 99999)]);
      await connecting;
      expect(tracker.owner, 'b');
      expect(tracker.todaySteps, isNull);
      expect(tracker.connected, isFalse);
    },
  );
  test(
    'disconnect cancels old reads and stays disconnected after restart',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      await tracker.disconnect();
      now = now.add(const Duration(minutes: 2));
      await tracker.refresh();
      expect(health.reads, 1);
      expect(tracker.days, isEmpty);
      await tracker.attach('b');
      await tracker.attach('a');
      expect(tracker.connected, isFalse);
    },
  );
  test('account deletion erases this account settings only', () async {
    await tracker.attach('a');
    await tracker.setManualGoal(4000);
    await tracker.attach('b');
    await tracker.setManualGoal(6000);
    await tracker.eraseAccount();
    expect(store.values, hasLength(1));
    await tracker.attach('a');
    expect(tracker.goal, 4000);
  });
  test(
    'provider failure clears stale health totals without losing the selected goal',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      health.reader = (_) async => throw StateError('locked database');
      now = now.add(const Duration(minutes: 2));
      await tracker.refresh(force: true);
      expect(tracker.status, StepStatus.error);
      expect(tracker.todaySteps, isNull);
      expect(tracker.goal, 5000);
    },
  );
  test(
    'storage failure prevents connection; disconnect removes stale opt-in',
    () async {
      await tracker.attach('a');
      store.failWrite = true;
      await tracker.connect();
      expect(tracker.connected, isFalse);
      expect(health.reads, 0);
      store.failWrite = false;
      await tracker.connect();
      store.failWrite = true;
      await tracker.disconnect();
      expect(store.values, isEmpty);
      expect(tracker.days, isEmpty);
    },
  );
  test(
    'refresh throttling has no polling and background refresh does not query',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      await tracker.refresh(force: true);
      await tracker.refresh();
      expect(health.reads, 1);
      tracker.setForeground(false);
      now = now.add(const Duration(hours: 1));
      await tracker.refresh(force: true);
      expect(health.reads, 1);
    },
  );
  test(
    'new day drops old steps even before a delayed native response',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      final pending = Completer<List<StepDay>>();
      health.reader = (_) => pending.future;
      now = DateTime(2026, 10, 17, 0, 1);
      final read = tracker.refresh(force: true);
      expect(tracker.todaySteps, isNull);
      pending.complete([StepDay(stepDateKey(now), 2)]);
      await read;
      expect(tracker.todaySteps, 2);
    },
  );
  testWidgets('local midnight timer resets and reads a new day', (
    tester,
  ) async {
    tracker.dispose();
    final anchor = tester.binding.clock.now();
    tracker = StepTracker(
      provider: health,
      store: store,
      profile: () => profile(),
      clock: () => DateTime(
        2026,
        10,
        16,
        23,
        59,
        59,
      ).add(tester.binding.clock.now().difference(anchor)),
    );
    await tracker.attach('a');
    await tracker.connect();
    health.count = 0;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(health.reads, 2);
    expect(tracker.todaySteps, 0);
    tracker.setForeground(false);
  });
  test('timezone/significant clock event rereads native boundaries', () async {
    await tracker.attach('a');
    await tracker.connect();
    now = now.add(const Duration(hours: 3));
    health.onTimeChanged?.call();
    await Future<void>.delayed(Duration.zero);
    expect(health.reads, 2);
  });

  test(
    'failed goal persistence restores the prior goal and recommendation setting',
    () async {
      await tracker.attach('a');
      store.failWrite = true;
      await tracker.setManualGoal(9000);
      expect(tracker.goal, 5000);
      expect(tracker.automatic, isTrue);
      expect(tracker.status, StepStatus.error);
    },
  );
  test(
    'a changed suggestion is never applied under an older confirmation',
    () async {
      health.reader = (windows) async => history(9000);
      await tracker.attach('a');
      await tracker.connect();
      await tracker.confirmHistory(tracker.pastDays.map((d) => d.date).toSet());
      expect(tracker.recommendation, 5250);
      await tracker.acceptRecommendation(expected: 6000);
      expect(tracker.goal, 5000);
    },
  );
  test(
    'a query crossing midnight is discarded and a new local-day query follows',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      final pending = Completer<List<StepDay>>();
      var queries = 0;
      health.reader = (windows) async {
        queries++;
        if (queries == 1) return pending.future;
        return [StepDay(windows.first.date, 3)];
      };
      now = now.add(const Duration(minutes: 2));
      final read = tracker.refresh(force: true);
      await Future<void>.delayed(Duration.zero);
      final oldDate = stepDateKey(now);
      now = DateTime(2026, 10, 17, 0, 1);
      pending.complete([StepDay(oldDate, 9999)]);
      await read;
      await Future<void>.delayed(Duration.zero);
      expect(queries, 2);
      expect(tracker.todaySteps, 3);
    },
  );
  test(
    'calendar windows account for timezone offsets and DST when present',
    () {
      for (final date in [
        DateTime(2026, 3, 9, 12),
        DateTime(2026, 11, 2, 12),
      ]) {
        for (final window in stepWindows(date).skip(1)) {
          expect(window.start.hour, 0);
          expect(window.end.hour, 0);
          expect(
            window.end.difference(window.start),
            const Duration(hours: 24) -
                window.end.timeZoneOffset +
                window.start.timeZoneOffset,
          );
        }
      }
    },
  );
  test(
    'permission revoked during a native read has an explicit denied status',
    () async {
      await tracker.attach('a');
      await tracker.connect();
      now = now.add(const Duration(minutes: 2));
      health.reader = (_) async =>
          throw PlatformException(code: 'health_permission_denied');
      await tracker.refresh(force: true);
      expect(tracker.status, StepStatus.denied);
      expect(tracker.todaySteps, isNull);
    },
  );

  group('native channel contract (mocked, not physical-device verification)', () {
    const channel = MethodChannel('test.bnyad.health');
    late NativeStepHealthProvider native;
    dynamic response;
    final calls = <MethodCall>[];
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      native = NativeStepHealthProvider(channel: channel);
      calls.clear();
      response = [
        {'date': stepDateKey(now), 'steps': 5000, 'distanceMeters': null},
      ];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'access' => {
                'availability': 'available',
                'permission': 'unknown',
              },
              'requestAccess' => true,
              'readDays' => response,
              _ => null,
            };
          });
    });
    tearDown(() {
      native.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    test(
      'only bounded local-day windows cross the bridge, no profile or credentials',
      () async {
        expect((await native.access()).permission, HealthPermission.unknown);
        expect(await native.requestAccess(), isTrue);
        expect((await native.readDays(stepWindows(now))).single.steps, 5000);
        final args = calls.last.arguments as Map;
        expect(args.keys, ['windows']);
        expect((args['windows'] as List), hasLength(15));
        expect(
          (args['windows'] as List).first['start'],
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
        );
      },
    );
    for (final value in [-1, 100001, 1.5, double.nan, 'five']) {
      test('malformed aggregate $value is rejected', () async {
        response = [
          {'date': stepDateKey(now), 'steps': value},
        ];
        await expectLater(
          native.readDays(stepWindows(now)),
          throwsFormatException,
        );
      });
    }
    test(
      'duplicates, unknown dates and invalid distance are rejected',
      () async {
        response = [...response as List, ...response as List];
        await expectLater(
          native.readDays(stepWindows(now)),
          throwsFormatException,
        );
        response = [
          {'date': '2020-01-01', 'steps': 5},
        ];
        await expectLater(
          native.readDays(stepWindows(now)),
          throwsFormatException,
        );
        response = [
          {'date': stepDateKey(now), 'steps': 5, 'distanceMeters': -1},
        ];
        await expectLater(
          native.readDays(stepWindows(now)),
          throwsFormatException,
        );
      },
    );
  });

  for (final width in [280.0, 320.0, 375.0, 430.0, 1024.0]) {
    for (final locale in ['en', 'ar', 'ku']) {
      for (final dark in [false, true]) {
        testWidgets('activity layout $width $locale dark=$dark at large text', (
          tester,
        ) async {
          tracker.dispose();
          tracker = StepTracker(
            provider: health,
            store: store,
            profile: () => profile(),
            clock: () => now,
          );
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tracker.attach('a');
          await tracker.connect();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: Directionality(
                  textDirection: StepStrings(locale).rtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(38),
                      child: DailyActivityWidget(
                        tracker: tracker,
                        locale: locale,
                        isDark: dark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final card = tester.getRect(
            find.byKey(const ValueKey('daily-activity')),
          );
          final count = tester.getRect(
            find.byKey(const ValueKey('step-count')),
          );
          expect(count.left, greaterThanOrEqualTo(card.left));
          expect(count.right, lessThanOrEqualTo(card.right));
          expect(
            find.byKey(const ValueKey('walking-calories')),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
          tracker.setForeground(false);
        });
      }
    }
  }
  for (final width in [320.0, 430.0]) {
    for (final locale in ['en', 'ar', 'ku']) {
      for (final dark in [false, true]) {
        testWidgets(
          'activity details $width $locale dark=$dark keeps controls accessible',
          (tester) async {
              tracker.dispose();
              tracker = StepTracker(
                provider: health,
                store: store,
                profile: () => profile(),
                clock: () => now,
              );
            tester.view.physicalSize = Size(width, 850);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tracker.attach('a');
            await tracker.connect();
            final strings = StepStrings(locale);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 850),
                    textScaler: const TextScaler.linear(1.6),
                  ),
                  child: StepDetailsScreen(
                    tracker: tracker,
                    locale: locale,
                    isDark: dark,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(strings.text('revoke')), findsNothing);
            expect(find.text(strings.text('algorithm')), findsNothing);
            expect(find.text(strings.text('connected')), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.text(strings.text('healthConnection')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text(strings.text('healthConnection')));
            await tester.pumpAndSettle();
            expect(find.text(strings.text('revoke')), findsOneWidget);
            await tester.ensureVisible(
              find.byKey(const ValueKey('disconnect-steps')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(tracker.connected, true);
            expect(tracker.todaySteps, 6420);
            await tester.pumpWidget(const SizedBox());
            tracker.setForeground(false);
          },
        );
      }
    }
  }
  testWidgets(
    'health explanation must be accepted before any native permission request',
    (tester) async {
      tracker.dispose();
      tracker = StepTracker(
        provider: health,
        store: store,
        profile: () => profile(),
        clock: () => now,
      );
      await tracker.attach('a');
      await tester.pumpWidget(
        MaterialApp(
          home: StepDetailsScreen(
            tracker: tracker,
            locale: 'en',
            isDark: false,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('connect-steps')));
      await tester.pumpAndSettle();
      expect(health.requests, 0);
      expect(find.text(StepStrings.en['privacy']!), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(health.requests, 0);
      await tester.tap(find.byKey(const ValueKey('connect-steps')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to permissions'));
      await tester.pumpAndSettle();
      expect(health.requests, 1);
      expect(tracker.todaySteps, 6420);
      await tester.pumpWidget(const SizedBox());
      tracker.setForeground(false);
    },
  );
  testWidgets(
    'manual goal UI validates, persists and pauses automatic suggestions',
    (tester) async {
      tracker.dispose();
      tracker = StepTracker(
        provider: health,
        store: store,
        profile: () => profile(),
        clock: () => now,
      );
      await tracker.attach('a');
      await tester.pumpWidget(
        MaterialApp(
          home: StepDetailsScreen(
            tracker: tracker,
            locale: 'en',
            isDark: false,
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('manual-step-goal')),
        300,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-step-goal')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-step-goal')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('step-goal-input')),
        '0',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(tracker.goal, 5000);
      await tester.enterText(
        find.byKey(const ValueKey('step-goal-input')),
        '٦٤٢٠',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(tracker.goal, 6420);
      expect(tracker.automatic, isFalse);
      expect(store.values, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('all feature labels have English, Arabic and Sorani translations', () {
    expect(StepStrings.ar.keys.toSet(), StepStrings.en.keys.toSet());
    expect(StepStrings.ku.keys.toSet(), StepStrings.en.keys.toSet());
    expect(
      const StepStrings('ckb').text('steps'),
      const StepStrings('ku').text('steps'),
    );
  });
  testWidgets(
    'mounting the app with connected steps never notifies a provider during build',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final api = ApiService(
        baseUrl: 'https://fictional.invalid/api',
        client: MockClient((_) async => http.Response('{}', 503)),
      );
      final state = AppState(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        stepHealthProvider: FakeHealth(),
        stepSettingsStore: MemoryStepStore(),
      );
      addTearDown(state.dispose);
      final visible = ValueNotifier(false);
      addTearDown(visible.dispose);
      await state.steps.attach('fictional|account');
      await state.steps.connect();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: Consumer<AppState>(
            builder: (context, current, _) => ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, shown, _) => shown
                  ? const KeyedSubtree(
                      key: ValueKey('mounted-app'),
                      child: BnyadApp(),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      visible.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.steps.setForeground(false);
      // Drain the original splash screen's initial delayed animation callback
      // after disposal; its mounted check prevents it from starting animations.
      await tester.pump(const Duration(milliseconds: 250));
    },
  );
}
