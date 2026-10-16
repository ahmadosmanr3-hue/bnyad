import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/activity/step_strings.dart';
import 'package:nutrify/activity/step_tracker.dart';
import 'package:nutrify/activity/step_widgets.dart';
import 'package:nutrify/main_health_test.dart' as diagnostic;
import 'package:nutrify/theme/app_theme.dart';
import 'step_tracking_test.dart' show FakeHealth, MemoryStepStore, profile;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('incomplete diagnostic profile cannot invent body measurements', () {
    expect(diagnostic.parseHealthTestProfile({}), isNull);
    expect(diagnostic.parseHealthTestProfile({'weight': 70}), isNull);
    final valid = {
      'weight': 70,
      'height': 175,
      'age': 30,
      'activityLevel': 'sedentary',
      'disabilities': <String>[],
    };
    expect(diagnostic.parseHealthTestProfile(valid)?.weight, 70);
    expect(
      diagnostic.parseHealthTestProfile({...valid, 'weight': double.nan}),
      isNull,
    );
    expect(diagnostic.parseHealthTestProfile({...valid, 'height': 0}), isNull);
    expect(diagnostic.parseHealthTestProfile({...valid, 'age': 30.1}), isNull);
  });
  test(
    'diagnostic fails closed outside native non-release dedicated bundle',
    () {
      for (final release in [true, false]) {
        for (final web in [true, false]) {
          for (final platform in TargetPlatform.values) {
            for (final nativeAllowed in [true, false]) {
              expect(
                diagnostic.healthTestRuntimeAllowed(
                  release: release,
                  web: web,
                  platform: platform,
                  nativeAllowed: nativeAllowed,
                ),
                !release &&
                    !web &&
                    platform == TargetPlatform.iOS &&
                    nativeAllowed,
              );
            }
          }
        }
      }
    },
  );
  for (final locale in ['en', 'ar', 'ku']) {
    for (final dark in [false, true]) {
      testWidgets(
        'compact calories and information dialog $locale dark=$dark',
        (tester) async {
          final tracker = StepTracker(
            provider: FakeHealth(),
            store: MemoryStepStore(),
            profile: () => profile(),
          );
          addTearDown(tracker.dispose);
          await tracker.attach('fictional');
          await tracker.connect();
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var detailTaps = 0;
          final strings = StepStrings(locale);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: Directionality(
                textDirection: strings.rtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(38),
                    child: DailyActivityWidget(
                      tracker: tracker,
                      locale: locale,
                      isDark: dark,
                      onTap: () => detailTaps++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('≈141 ${strings.text('burned')}'), findsOneWidget);
          expect(find.text(strings.text('notAdded')), findsNothing);
          expect(find.text(strings.text('calorieInfo')), findsNothing);
          final info = find.byKey(const ValueKey('walking-calories-info'));
          expect(tester.getSize(info).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(info).height, greaterThanOrEqualTo(48));
          await tester.tap(info);
          await tester.pumpAndSettle();
          expect(detailTaps, 0);
          expect(find.text(strings.text('calorieInfo')), findsOneWidget);
          expect(
            Directionality.of(tester.element(find.byType(AlertDialog))),
            strings.rtl ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(strings.text('close')));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          await tester.tap(find.byKey(const ValueKey('step-count')));
          expect(detailTaps, 1);
          expect(tracker.walking!.calories, 141);
          expect(tracker.profile()!.dailyCalories, 2200);
          await tester.pumpWidget(const SizedBox());
          tracker.setForeground(false);
        },
      );
    }
  }
  testWidgets(
    'diagnostic uses mocked native responses, saves goals, restores preferences',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('com.bnyad.app/steps');
      const storage = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final prefs = <String, String>{};
      final methods = <String>[];
      var count = 1234;
      var authorized = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storage, (call) async {
            final args = call.arguments as Map;
            if (call.method == 'read') return prefs[args['key']];
            if (call.method == 'write') prefs[args['key']] = args['value'];
            if (call.method == 'delete') prefs.remove(args['key']);
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            methods.add(call.method);
            switch (call.method) {
              case 'healthDiagnosticAllowed':
                return true;
              case 'access':
                return {'availability': 'available', 'permission': 'unknown'};
              case 'requestAccess':
                authorized = true;
                return true;
              case 'readDays':
                expect(authorized, true);
                final windows = (call.arguments as Map)['windows'] as List;
                return [
                  {'date': (windows.first as Map)['date'], 'steps': count},
                ];
              default:
                throw PlatformException(code: 'unexpected');
            }
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(storage, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      await tester.pumpWidget(const diagnostic.HealthTestApp());
      await tester.pumpAndSettle();
      expect(
        find.text('BNYAD HEALTH TEST · REAL APPLE HEALTH'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('simulated-steps')), findsNothing);
      expect(methods, isEmpty);
      await tester.tap(find.byKey(const ValueKey('connect-steps')));
      await tester.pumpAndSettle();
      expect(authorized, false);
      await tester.tap(find.text(StepStrings.en['allow']!));
      await tester.pumpAndSettle();
      expect(find.text('1234 / 3000 steps'), findsOneWidget);
      expect(find.text('≈— kcal burned'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-step-goal')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-step-goal')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '4500');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(prefs.values.any((v) => v.contains('4500')), true);
      expect(prefs.values.any((v) => v.contains('1234')), false);
      await tester.tap(find.text('Set your profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '70');
      await tester.enterText(find.byType(TextFormField).at(1), '175');
      await tester.enterText(find.byType(TextFormField).at(2), '30.0');
      await tester.tap(find.text('Save on device'));
      await tester.pumpAndSettle();
      expect(find.text('≈27 kcal burned'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      count = 1300;
      await tester.pumpWidget(const diagnostic.HealthTestApp());
      await tester.pumpAndSettle();
      expect(find.text('1300 / 4500 steps'), findsOneWidget);
      expect(find.text('≈28 kcal burned'), findsOneWidget);
      expect(find.byKey(const ValueKey('simulated-steps')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('wrong native bundle never opens diagnostic or requests health', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('com.bnyad.app/steps');
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          return false;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await diagnostic.main();
    await tester.pumpAndSettle();
    expect(find.textContaining('Health diagnostic disabled'), findsOneWidget);
    expect(methods, ['healthDiagnosticAllowed']);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
