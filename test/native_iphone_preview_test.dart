import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/activity/step_health_provider.dart';
import 'package:nutrify/activity/step_models.dart';
import 'package:nutrify/activity/step_widgets.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_guard.dart';
import 'package:nutrify/demo/demo_steps.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/main.dart' show BnyadApp;
import 'package:nutrify/main_iphone_preview.dart' as preview;
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/services/food_barcode_service.dart';
import 'step_tracking_test.dart' show MemoryStepStore, profile, FakeHealth;
import 'package:nutrify/activity/step_tracker.dart';
import 'package:nutrify/activity/step_strings.dart';

class ForegroundHealth extends FakeHealth {
  bool? nativeForeground;
  VoidCallback? duringPermission;
  @override
  Future<bool?> foreground() async => nativeForeground;
  @override
  Future<bool> requestAccess() async {
    duringPermission?.call();
    return super.requestAccess();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'permission-sheet lifecycle cannot strand Refreshing; native foreground resumes safely',
    () async {
      final provider = ForegroundHealth();
      final tracker = StepTracker(
        provider: provider,
        store: MemoryStepStore(),
        profile: () => profile(),
      );
      await tracker.attach('fictional-lifecycle-test');
      provider.duringPermission = () => tracker.setForeground(false);
      await tracker.connect();
      expect(tracker.connected, true);
      expect(tracker.busy, false);
      expect(tracker.status, StepStatus.waitingForForeground);
      expect(provider.reads, 0);
      // UIKit is active/inactive while Flutter has not delivered resumed yet.
      provider.nativeForeground = true;
      await tracker.refresh(force: true);
      expect(tracker.status, StepStatus.ready);
      expect(tracker.todaySteps, 6420);
      expect(provider.requests, 1);
      tracker.setForeground(false);
      provider.nativeForeground = false;
      await tracker.refresh(force: true);
      expect(
        provider.reads,
        1,
      ); // Genuine background never starts another read.
      expect(tracker.status, StepStatus.waitingForForeground);
      tracker.dispose();
    },
  );
  const health = MethodChannel('com.bnyad.app/steps');
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const purchases = MethodChannel('purchases_flutter');
  late Map<String, String> keychain;
  late List<String> calls;
  late bool nativeAllowed;
  late int count;
  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
    keychain = {};
    calls = [];
    nativeAllowed = true;
    count = 6420;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(health, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'foreground':
              return true;
            case 'offlinePreviewAllowed':
              return nativeAllowed;
            case 'access':
              return {'availability': 'available', 'permission': 'unknown'};
            case 'requestAccess':
              return true;
            case 'readDays':
              final windows = (call.arguments as Map)['windows'] as List;
              return [
                {'date': (windows.first as Map)['date'], 'steps': count},
              ];
            default:
              throw PlatformException(code: 'unexpected');
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (call) async {
          final args = call.arguments as Map;
          if (call.method == 'read') return keychain[args['key']];
          if (call.method == 'write') keychain[args['key']] = args['value'];
          if (call.method == 'delete') keychain.remove(args['key']);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(purchases, (call) async {
          fail('Offline preview called store SDK: ${call.method}');
        });
  });
  tearDown(() {
    HttpOverrides.global = null;
    FoodBarcodeService.clientOverride = null;
    debugDefaultTargetPlatformOverride = null;
    SharedPreferences.resetStatic();
    for (final channel in [health, secure, purchases]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  test(
    'native preview runtime rejects release, web, wrong platform/bundle',
    () {
      for (final release in [true, false]) {
        for (final web in [true, false]) {
          for (final platform in TargetPlatform.values) {
            for (final allowed in [true, false]) {
              expect(
                isAllowedNativePreview(
                  release: release,
                  web: web,
                  platform: platform,
                  nativeAllowed: allowed,
                ),
                !release && !web && platform == TargetPlatform.iOS && allowed,
              );
            }
          }
        }
      }
    },
  );
  test(
    'native handshake fails closed and never permits browser fake steps',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      nativeAllowed = false;
      await expectLater(authorizeNativePreview(), throwsStateError);
      expect(requireNativePreview, throwsStateError);
      nativeAllowed = true;
      await authorizeNativePreview();
      expect(requireNativePreview, returnsNormally);
      expect(DemoStepHealthProvider.new, throwsStateError);
      expect(requireDemoRuntime, throwsStateError);
    },
  );
  test(
    'accidental Dart HTTP is blocked before DNS/socket connection',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        await expectLater(
          http.get(Uri.parse('https://nutrify-api-lovat.vercel.app/api')),
          throwsUnsupportedError,
        );
      }, preview.OfflinePreviewHttpOverrides());
    },
  );
  test(
    'entrypoint separation and exact native bundle guards remain explicit',
    () {
      final source = File('lib/main_iphone_preview.dart').readAsStringSync();
      expect(source, contains('child: const BnyadApp()'));
      expect(source, contains('NativeStepHealthProvider()'));
      expect(source, isNot(contains('demo_steps.dart')));
      expect(source, contains('aiEnabled: false'));
      for (final entry in ['main.dart', 'main_development.dart']) {
        final text = File('lib/$entry').readAsStringSync();
        expect(text, isNot(contains('main_iphone_preview')));
        expect(text, isNot(contains('demo/')));
      }
      final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(
        swift,
        contains('Bundle.main.bundleIdentifier == "com.nutrify.bnyad.dev"'),
      );
      expect(swift, contains('forInfoDictionaryKey: "BNYADOfflinePreview"'));
    },
  );

  test(
    'full AppState uses local fixtures, real-provider wiring and isolated profile',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await authorizeNativePreview();
      SharedPreferences.setPrefix('bnyad_iphone_preview.');
      final prefs = await SharedPreferences.getInstance();
      final backend = DemoBackend(prefs);
      final api = ApiService(
        baseUrl: DemoBackend.baseUrl,
        aiEnabled: false,
        storage: DemoStorage(prefs),
        client: backend.client,
      );
      final settings = MemoryStepStore();
      UserProfile? personal;
      AppState makeState() => AppState(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
        stepSettingsStore: settings,
        stepHealthProvider: NativeStepHealthProvider(),
        stepProfile: () => personal,
      );
      var state = makeState();
      await state.initializeSession();
      expect(
        await state.loginWithPassword('+9647700000010', 'fictional-only'),
        isNull,
      );
      expect(state.isAuthenticated, true);
      expect(state.steps.simulated, false);
      expect(state.supportsOptionalDeviceServices, false);
      await Future<void>.delayed(Duration.zero);
      state.steps.setForeground(true);
      final allowance = state.goals!.calories;
      await state.steps.connect();
      expect(state.steps.todaySteps, 6420);
      expect(
        state.steps.walking,
        isNull,
      ); // Never use the fictional 75kg profile.
      personal = profile({'weight': 70});
      state.steps.refreshProfilePresentation();
      expect(state.steps.walking!.calories, 141);
      await state.steps.setManualGoal(4500);
      expect(state.goals!.calories, allowance);
      expect(await state.updateWater(1750), true);
      expect(
        await state.addLogEntry(
          LogEntry(
            id: 'local',
            foodId: 'local-apple',
            name: 'Fictional test apple',
            amount: 100,
            calories: 52,
            protein: .3,
            carbs: 14,
            fat: .2,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            mealId: 'snacks',
          ),
        ),
        true,
      );
      await state.recordTodayWeight(
        80,
      ); // Fictional nutrition weigh-in is separate.
      expect(state.steps.walking!.calories, 141);
      expect(await state.purchasePremium(), false);
      await state.syncPremiumFromRevenueCat();
      expect(
        await state.restorePurchases(),
        true,
      ); // Local subscription fixture only.
      expect(await state.checkConnectivity(), true);
      expect(await api.generateAi('daily', {}), isNull);
      expect(api.aiErrorCode, 'unavailable');
      final serialized = backend.data.toString();
      expect(serialized, isNot(contains('6420')));
      expect(settings.values.toString(), isNot(contains('6420')));
      expect(
        backend.profile['weight'],
        75,
      ); // Personal body data never enters fixture.
      state.dispose();
      count = 6500;
      state = makeState();
      await state.initializeSession();
      await Future<void>.delayed(Duration.zero);
      state.steps.setForeground(true);
      await Future<void>.delayed(Duration.zero);
      expect(state.isAuthenticated, true);
      expect(state.steps.goal, 4500);
      expect(state.steps.todaySteps, 6500);
      expect(state.waterIntake, 1750);
      expect(state.dailyLog.any((e) => e.name == 'Fictional test apple'), true);
      expect(state.goals!.calories, allowance);
      state.dispose();
      api.dispose();
    },
  );

  testWidgets(
    'complete native preview mounts BnyadApp, dashboard and navigation without billing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await preview.main();
      await tester.pump();
      // Original dashboard has a continuously repeating animation. Use
      // bounded frames, not pumpAndSettle, and advance each splash delay.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BnyadApp), findsOneWidget);
      expect(find.textContaining('OFFLINE DEMO'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.byKey(const ValueKey('daily-activity')), findsOneWidget);
      expect(find.byKey(const ValueKey('simulated-steps')), findsNothing);
      final state = Provider.of<AppState>(
        tester.element(find.byType(BnyadApp)),
        listen: false,
      );
      await state.steps.connect();
      await tester.pump(const Duration(milliseconds: 500));
      expect(state.steps.todaySteps, 6420);
      expect(state.steps.walking, isNull);
      state.setActiveTab(1);
      await tester.pump(const Duration(milliseconds: 500));
      state.setActiveTab(0);
      await tester.pump(const Duration(milliseconds: 500));
      final context = tester.element(find.byType(BnyadApp));
      showPremiumPaywall(context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
      state.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'saved connection with empty today survives cold restart without another permission prompt',
    (tester) async {
      final settings = MemoryStepStore();
      final fake = FakeHealth();
      fake.reader = (windows) async => [
        StepDay(windows.first.date, null),
        StepDay(windows[1].date, 2850),
      ];
      StepTracker makeTracker() => StepTracker(
        provider: fake,
        store: settings,
        profile: () => profile(),
      );
      var tracker = makeTracker();
      await tracker.attach('local-test-account');
      await tracker.connect();
      await tracker.setManualGoal(4200);
      expect(tracker.connected, true);
      expect(tracker.status, StepStatus.emptyOrPrivate);
      tracker.dispose();
      tracker = makeTracker();
      await tracker.attach('local-test-account');
      expect(fake.requests, 1);
      expect(tracker.connected, true);
      expect(tracker.goal, 4200);
      expect(tracker.todaySteps, isNull);
      expect(tracker.pastDays.single.steps, 2850);
      await tester.pumpWidget(
        MaterialApp(
          home: StepDetailsScreen(
            tracker: tracker,
            locale: 'en',
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('connect-steps')), findsNothing);
      expect(find.text(StepStrings.en['connected']!), findsOneWidget);
      expect(find.text(StepStrings.en['connectionSaved']!), findsNothing);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.textContaining('Today:'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('health-connection-details')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(StepStrings.en['healthConnection']!));
      await tester.pumpAndSettle();
      expect(find.text(StepStrings.en['connectionSaved']!), findsOneWidget);
      expect(find.byKey(const ValueKey('disconnect-steps')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tracker.dispose();
    },
  );
}
