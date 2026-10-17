import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/l10n/framework_localizations.dart';
import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/dashboard_screen.dart';
import 'package:nutrify/screens/meal_plan_screen.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/theme/app_theme.dart';

class RatioState extends AppState {
  RatioState(
    ApiService api,
    this.language,
    this.dark,
    this.values,
    this.targets,
  ) : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
      );
  final String language;
  final bool dark;
  final List<int> values;
  final List<int> targets;
  @override
  AppLocalizations get t => AppLocalizations(language);
  @override
  bool get isDark => dark;
  @override
  bool get hasPremiumFeatures => true;
  @override
  bool get isLoggedIn => true;
  @override
  NutritionalGoals get goals => NutritionalGoals(
    calories: 2200,
    protein: targets[0],
    carbs: targets[1],
    fat: targets[2],
  );
  @override
  Map<String, int> get consumedStats => {
    'calories': 844,
    'protein': values[0],
    'carbs': values[1],
    'fat': values[2],
  };
  @override
  MealPlanData get currentMealPlan => MealPlanData.fromMap({
    for (final slot in ['breakfast', 'lunch', 'dinner', 'snacks'])
      slot: {
        'name': 'Fixture',
        'calories': 100,
        'protein': 10,
        'carbs': 20,
        'fat': 5,
      },
  });
}

void assertLeftToRightGlyphs(WidgetTester tester, Finder finder, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.textDirection, TextDirection.ltr);
  double? previous;
  for (var i = 0; i < text.length; i++) {
    final box = paragraph
        .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
        .single;
    // Glyph advances may overhang fractional layout rounding by <1 logical px.
    expect(box.left, greaterThanOrEqualTo(-1));
    expect(box.right, lessThanOrEqualTo(paragraph.size.width + 1));
    if (previous != null) expect(box.left, greaterThanOrEqualTo(previous));
    previous = box.left;
  }
}

void main() {
  setUpAll(() async {
    for (final family in ['NotoSans', 'NotoSansArabic', 'NotoSansSymbols']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('fonts/$family-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final lang in ['en', 'ar', 'ckb', 'ku']) {
    testWidgets('related nutrient and daily-plan ratios $lang', (tester) async {
      final api = ApiService(
        baseUrl: 'https://no-network.invalid/api',
        aiEnabled: false,
        client: MockClient((_) async => http.Response('{}', 503)),
      );
      final state = RatioState(api, lang, false, [30, 136, 20], [120, 268, 72]);
      addTearDown(() {
        state.dispose();
        api.dispose();
      });
      Future<void> mount(Widget screen) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
              locale: bnyadLocale(lang),
              supportedLocales: bnyadLocales,
              localizationsDelegates: bnyadDelegates,
              theme: AppTheme.lightTheme,
              home: Directionality(
                textDirection: state.t.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(body: screen),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
      }

      await mount(const DashboardScreen());
      final nutrients = find.text(state.t.nutrientsAndSupplements);
      await tester.ensureVisible(nutrients);
      await tester.tap(nutrients);
      await tester.pump(const Duration(milliseconds: 500));
      final microRatios = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'^\d+(\.\d+)? / \d+(\.\d+)? ').hasMatch(w.data ?? ''),
      );
      expect(microRatios, findsWidgets);
      for (final element in microRatios.evaluate()) {
        final text = element.widget as Text;
        expect(text.textDirection, TextDirection.ltr);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await mount(const MealPlanScreen());
      for (final value in [
        '400 / 2200',
        '40g / 120g',
        '80g / 268g',
        '20g / 72g',
      ]) {
        final ratio = find.text(value);
        expect(ratio, findsOneWidget);
        await tester.ensureVisible(ratio);
        await tester.pump();
        assertLeftToRightGlyphs(tester, ratio, value);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    for (final width in [280.0, 320.0, 390.0, 430.0, 1024.0]) {
      for (final dark in [false, true]) {
        testWidgets('macro glyph order $lang $width dark=$dark', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = ApiService(
            baseUrl: 'https://no-network.invalid/api',
            aiEnabled: false,
            client: MockClient((_) async => http.Response('{}', 503)),
          );
          addTearDown(api.dispose);
          final scenarios = [
            ([0, 0, 0], [0, 1, 9]),
            ([30, 136, 20], [120, 268, 72]),
            ([220, 450, 150], [180, 350, 120]),
          ];
          for (var scenario = 0; scenario < scenarios.length; scenario++) {
            final (values, targets) = scenarios[scenario];
            final state = RatioState(api, lang, dark, values, targets);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              ChangeNotifierProvider<AppState>.value(
                value: state,
                child: MaterialApp(
                  locale: bnyadLocale(lang),
                  supportedLocales: bnyadLocales,
                  localizationsDelegates: bnyadDelegates,
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 900),
                      textScaler: TextScaler.linear(
                        scenario == 2 && width >= 390 ? 1.6 : 1,
                      ),
                    ),
                    child: Directionality(
                      textDirection: state.t.isRTL
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Scaffold(
                        body: RepaintBoundary(
                          key: boundary,
                          child: const DashboardScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(seconds: 2));
            final macros = find.byKey(const ValueKey('dashboard-macros'));
            await tester.ensureVisible(macros);
            await tester.pump();
            final labels = [state.t.protein, state.t.carbs, state.t.fat];
            for (var i = 0; i < 3; i++) {
              final card = find.byKey(
                ValueKey('macro-${labels[i]}-${values[i]}-${targets[i]}'),
              );
              final current = find.descendant(
                of: card,
                matching: find.text('${values[i]}'),
              );
              final target = find.descendant(
                of: card,
                matching: find.text('/${targets[i]}'),
              );
              expect(current, findsOneWidget);
              expect(target, findsOneWidget);
              assertLeftToRightGlyphs(tester, current, '${values[i]}');
              assertLeftToRightGlyphs(tester, target, '/${targets[i]}');
              expect(
                tester.getTopLeft(current).dy,
                lessThan(tester.getTopLeft(target).dy),
              );
            }
            // Supplement ratio remains numeric LTR; surrounding app stays localized.
            expect(
              tester.widget<Text>(find.text('0/0')).textDirection,
              TextDirection.ltr,
            );
            expect(
              Directionality.of(tester.element(macros)),
              state.t.isRTL ? TextDirection.rtl : TextDirection.ltr,
            );
            expect(state.goals.calories, 2200);
            expect(state.consumedStats['calories'], 844);
            expect(tester.takeException(), isNull);
            if (const bool.fromEnvironment('BNYAD_RATIO_SCREENSHOTS') &&
                scenario == 1 &&
                !dark &&
                lang != 'ku' &&
                [320, 430].contains(width)) {
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory('build/macro-ratio-evidence')
                  ..createSync(recursive: true);
                await File(
                  '${folder.path}/macros-$lang-${width.toInt()}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.pumpWidget(const SizedBox());
            state.dispose();
          }
        });
      }
    }
  }
}
