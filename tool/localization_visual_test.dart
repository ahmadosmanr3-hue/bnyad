// Opt-in Flutter widget test outside test/ to avoid generating PNGs on every unit-test run.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'package:nutrify/l10n/framework_localizations.dart';
import 'package:nutrify/l10n/localized_time_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/main_iphone_preview.dart'
    show OfflinePreviewHttpOverrides;
import 'package:nutrify/activity/step_health_provider.dart';
import 'package:nutrify/activity/step_models.dart';
import 'package:nutrify/activity/step_widgets.dart';
import 'package:nutrify/activity/step_tracker.dart';
import 'package:nutrify/screens/dashboard_screen.dart';
import 'package:nutrify/screens/food_log_screen.dart';
import 'package:nutrify/screens/settings_screen.dart';
import 'package:nutrify/screens/meal_plan_screen.dart';
import 'package:nutrify/screens/scanner_screen.dart';
import 'package:nutrify/screens/shopping_list_screen.dart';
import 'package:nutrify/screens/weekly_summary_screen.dart';
import 'package:nutrify/screens/body_fat_estimator_screen.dart';
import 'package:nutrify/screens/notifications_screen.dart';
import 'package:nutrify/screens/medical_citations_screen.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/screens/login_required_screen.dart';
import 'package:nutrify/screens/onboarding_screen.dart';
import 'package:nutrify/screens/splash_screen.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/app_bottom_nav.dart';

const evidence = String.fromEnvironment(
  'BNYAD_L10N_EVIDENCE',
  defaultValue: 'build/localization-evidence',
);

class AuditHealth extends StepHealthProvider {
  @override
  bool get simulated => true;
  @override
  Future<HealthAccess> access() async => const HealthAccess(
    HealthAvailability.available,
    HealthPermission.granted,
  );
  @override
  Future<bool> requestAccess() async => true;
  @override
  Future<void> openSettings() async {}
  @override
  Future<List<StepDay>> readDays(List<StepWindow> windows) async => [
    StepDay(windows.first.date, 12345),
  ];
}

final results = <Map<String, dynamic>>[];

class AuditStore extends StepSettingsStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    Directory(evidence).createSync(recursive: true);
    for (final family in ['NotoSans', 'NotoSansArabic', 'NotoSansSymbols']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('fonts/$family-Regular.ttf'));
      await loader.load();
    }
    // Flutter tests otherwise substitute Ahem for unspecified platform fonts.
    // Alias only in this audit harness; never infer device glyph behavior here.
    await (FontLoader(
      'Ahem',
    )..addFont(rootBundle.load('fonts/NotoSansArabic-Regular.ttf'))).load();
    // Button themes have no explicit family; stand in for the OS Arabic fallback.
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('fonts/NotoSansArabic-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  tearDownAll(
    () => File(
      '$evidence/render-results.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results)),
  );
  final factories = <String, Widget Function(AppState)>{
    'navigation': (s) => Align(
      alignment: Alignment.bottomCenter,
      child: AppBottomNav(
        selectedIndex: 2,
        onDestinationSelected: (_) {},
        t: s.t,
        isDark: s.isDark,
      ),
    ),
    'welcome': (_) => const LoginScreen(),
    'onboarding': (_) => const OnboardingScreen(),
    'dashboard': (_) => const DashboardScreen(),
    'food-log': (_) => const FoodLogScreen(),
    'settings': (_) => const SettingsScreen(),
    'daily-meals': (_) => const MealPlanScreen(),
    'food-scanner': (_) => const ScannerScreen(),
    'shopping': (_) => const ShoppingListScreen(),
    'progress-weight': (_) => const WeeklySummaryScreen(),
    'body-fat': (_) => const BodyFatEstimatorScreen(),
    'notifications': (_) => const NotificationsScreen(),
    'medical-sources': (_) => const MedicalCitationsScreen(),
    'login-required': (_) => const LoginRequiredScreen(),
    'steps': (s) =>
        StepDetailsScreen(tracker: s.steps, locale: s.lang, isDark: s.isDark),
    'splash': (s) => SplashScreen(
      isDark: s.isDark,
      tagline: s.t.splashTagline,
      subline: s.t.splashSubline,
      onComplete: () {},
    ),
  };
  for (final language in ['en', 'ar', 'ckb']) {
    for (final width in [320.0, 430.0]) {
      for (final entry in factories.entries) {
        testWidgets('localized render $language ${entry.key} $width', (
          tester,
        ) async {
          tester.binding.resetEpoch();
          SharedPreferences.resetStatic();
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final backend = DemoBackend(prefs);
          final api = ApiService(
            baseUrl: DemoBackend.baseUrl,
            aiEnabled: false,
            storage: DemoStorage(prefs),
            client: backend.client,
          );
          final state = AppState(
            authService: AuthService(api: api),
            apiService: api,
            initializeOnCreate: false,
            optionalDeviceServicesEnabled: false,
            stepHealthProvider: AuditHealth(),
            stepSettingsStore: AuditStore(),
          );
          await state.initializeSession();
          await state.loginWithPassword('+9647700000010', 'fictional');
          await state.setLang(language);
          await state.steps.connect();
          state.steps.setForeground(true);
          HttpOverrides.global = OfflinePreviewHttpOverrides();
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          final navigator = GlobalKey<NavigatorState>();
          Future<void> frames([int count = 8]) async {
            for (var i = 0; i < count; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          Future<void> capture(String name) async {
            await frames();
            final errors = <String>[];
            Object? error;
            while ((error = tester.takeException()) != null) {
              errors.add(error.toString());
            }
            expect(errors, isEmpty, reason: '$name at $width');
            final texts = tester
                .widgetList<Text>(find.byType(Text))
                .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
                .toList();
            final context = boundary.currentContext!;
            results.add({
              'name': name,
              'width': width,
              'locale': state.lang,
              'rtl': state.isRTL,
              'errors': errors,
              'texts': texts,
              'buttonFont': find
                  .text(state.t.login)
                  .evaluate()
                  .map(
                    (e) => {
                      'textStyle': (e.widget as Text).style.toString(),
                      'defaultStyle': DefaultTextStyle.of(e).style.toString(),
                    },
                  )
                  .toList(),
            });
            await tester.runAsync(() async {
              final image =
                  await (context.findRenderObject() as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1.5);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$evidence/$name-${width.toInt()}-${state.lang}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          Future<bool> tapLabel(String label) async {
            final finder = find.text(label);
            if (finder.evaluate().isEmpty) return false;
            await tester.ensureVisible(finder.first);
            await frames();
            await tester.tap(finder.first);
            await frames();
            return true;
          }

          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: ChangeNotifierProvider.value(
                value: state,
                child: MaterialApp(
                  navigatorKey: navigator,
                  locale: bnyadLocale(state.lang),
                  supportedLocales: bnyadLocales,
                  localizationsDelegates: bnyadDelegates,
                  theme: AppTheme.lightTheme,
                  builder: (context, child) => Directionality(
                    textDirection: state.isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  ),
                  home: Scaffold(body: entry.value(state)),
                ),
              ),
            ),
          );
          await capture(entry.key);
          if (entry.key == 'dashboard') {
            for (var i = 0; i < 2; i++) {
              await tester.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, -500),
              );
              await capture('dashboard-scroll-$i');
            }
            if (await tapLabel(state.t.nutrientsAndSupplements)) {
              await capture('supplements');
            }
          }
          if (entry.key == 'food-log') {
            if (await tapLabel(state.t.addFood)) {
              await capture('food-search');
              final fields = find.byType(TextField);
              if (fields.evaluate().isNotEmpty) {
                await tester.enterText(fields.first, 'دۆڵمە');
                await capture('food-search-sorani');
                await tester.enterText(fields.first, 'zzzz-no-such-food');
                await capture('food-search-empty');
              }
            }
          }
          if (entry.key == 'settings') {
            if (await tapLabel(state.t.deleteAccount)) {
              await capture('account-delete-confirmation');
              await tapLabel(state.t.cancel);
            }
            for (var i = 0; i < 3; i++) {
              final scroll = find.byType(SingleChildScrollView);
              if (scroll.evaluate().isEmpty) break;
              await tester.drag(scroll.first, const Offset(0, -550));
              await capture('settings-scroll-$i');
            }
          }
          if (entry.key == 'navigation') {
            showBnyadTimePicker(
              context: tester.element(find.byType(Scaffold).first),
              initialTime: const TimeOfDay(hour: 8, minute: 0),
            );
            await capture('localized-time-picker');
          }
          if (entry.key == 'welcome') {
            if (await tapLabel(state.t.login)) {
              await capture('login-password');
              await tapLabel(state.t.login);
              await capture('login-validation');
              await tapLabel(state.t.back);
              if (await tapLabel(state.t.signUp)) {
                await capture('registration-phone');
                await tapLabel(state.t.continueWithPhone);
                await capture('registration-phone-validation');
                await tester.enterText(
                  find.byType(TextField).first,
                  '7700000011',
                );
                await tapLabel(state.t.continueWithPhone);
                await capture('registration-form');
                await tapLabel(state.t.sendOtp);
                await capture('registration-validation');
                final fields = find.byType(TextField);
                if (fields.evaluate().length == 4) {
                  await tester.enterText(fields.at(1), 'کاربەری نموونە');
                  await tester.enterText(fields.at(2), 'fictional123');
                  await tester.enterText(fields.at(3), 'fictional123');
                  await tapLabel(state.t.sendOtp);
                  await capture('otp');
                  if (find
                      .byKey(const ValueKey('otp-step'))
                      .evaluate()
                      .isNotEmpty) {
                    await tester.enterText(
                      find.byType(TextField).last,
                      '١٢٣٤٥٦',
                    );
                    await capture('otp-sorani-digits');
                    await tapLabel(state.t.verifyOtp);
                    await capture('otp-validation');
                  }
                }
              }
            }
          }
          if (entry.key == 'onboarding') {
            for (var step = 2; step <= 5; step++) {
              if (await tapLabel(state.t.next)) {
                await capture('onboarding-step-$step');
              }
            }
            if (await tapLabel(state.t.generatePlan)) {
              await capture('onboarding-results');
            }
          }
          if (entry.key == 'body-fat') {
            final scroll = find.byType(SingleChildScrollView);
            if (scroll.evaluate().isNotEmpty) {
              await tester.drag(scroll.first, const Offset(0, -550));
              await capture('body-fat-scroll');
            }
          }
          if (entry.key == 'steps') {
            final info = find.byKey(const ValueKey('walking-calories-info'));
            if (info.evaluate().isNotEmpty) {
              await tester.tap(info);
              await capture('walking-calories-info');
              navigator.currentState!.pop();
              await frames();
            }
            if (await tapLabel('گۆڕینی دەستیی ئامانج')) {
              await capture('step-goal-dialog');
            }
          }
          if (entry.key == 'daily-meals') {
            if (await tapLabel(state.t.cookWithIngredients)) {
              await capture('ingredient-recipe');
            }
          }
          if (entry.key == 'shopping') {
            final fields = find.byType(TextField);
            if (fields.evaluate().isNotEmpty) {
              await tester.enterText(
                fields.first,
                'پێکهاتەیەکی نموونەیی زۆر درێژ بۆ تاقیکردنەوەی ڕووکار',
              );
              await tapLabel(state.t.addItem);
              await capture('shopping-long-name');
            }
          }
          if (entry.key == 'progress-weight') {
            final weightAction = find.byTooltip(state.t.weeklyUpdateWeight);
            if (weightAction.evaluate().isNotEmpty) {
              await tester.tap(weightAction);
              await capture('weight-input-dialog');
              await tester.enterText(find.byType(TextField).last, '٧٥.٥');
              await tapLabel(state.t.save);
              await capture('weight-sorani-digits');
            }
          }
          if (entry.key == 'notifications') {
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: SizedBox()),
              ),
            );
            await frames();
            showPremiumPaywall(tester.element(find.byType(Scaffold).last));
            await capture('premium-paywall');
          }
          if (entry.key == 'splash') await frames(60);
          await tester.pumpWidget(const SizedBox());
          await frames(2);
          state.dispose();
          api.dispose();
          HttpOverrides.global = null;
        });
      }
    }
  }
}
