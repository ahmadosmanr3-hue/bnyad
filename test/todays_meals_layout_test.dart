import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/dashboard_screen.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/theme/app_theme.dart';

const names = {
  'en': 'Demo: oats and banana',
  'ar': 'نموذج: شوفان وموز',
  'ku': 'نموونە: جۆدۆسەر و مۆز',
};
const longName =
    'Demo: a generous bowl of oats and banana with fresh berries, plain yogurt, cinnamon and toasted seeds';

LogEntry food(
  String id,
  String name, {
  String? meal = 'breakfast',
  int calories = 360,
}) => LogEntry(
  id: id,
  foodId: 'fictional-food',
  name: name,
  amount: 250,
  calories: calories,
  protein: 12,
  carbs: 60,
  fat: 8,
  timestamp: DateTime(2026, 10, 14, 8).millisecondsSinceEpoch,
  mealId: meal,
);

class MealsState extends AppState {
  MealsState(ApiService api, this.language, this.dark)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
      );
  final String language;
  final bool dark;
  final List<LogEntry> logs = [];
  String? openedMeal;
  int openCount = 0;
  @override
  AppLocalizations get t => AppLocalizations(language);
  @override
  bool get isDark => dark;
  @override
  bool get isLoggedIn => true;
  @override
  List<LogEntry> get dailyLog => logs;
  @override
  List<String> get eatenMeals =>
      logs.map((e) => e.mealId).whereType<String>().toList();
  @override
  void openFoodLog({String? mealId, bool openSheet = true}) {
    openedMeal = mealId;
    openCount++;
  }

  @override
  Future<bool> removeLogEntry(String id) async {
    logs.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }
}

void main() {
  setUpAll(() async {
    for (final family in ['NotoSans', 'NotoSansArabic']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('fonts/$family-Regular.ttf'))).load();
    }
  });

  Future<MealsState> mount(
    WidgetTester tester, {
    double width = 320,
    String lang = 'en',
    bool dark = false,
    double scale = 1,
    List<LogEntry>? entries,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiService(
      baseUrl: 'https://no-network.invalid/api',
      client: MockClient((_) async => http.Response('{}', 503)),
    );
    final state = MealsState(api, lang, dark)
      ..logs.addAll(
        entries ??
            [
              food('oats', names[lang]!),
              food('lunch', 'Demo rice bowl', meal: 'lunch'),
            ],
      );
    addTearDown(() {
      state.dispose();
      api.dispose();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.linear(scale),
            ),
            child: Directionality(
              textDirection: state.t.isRTL
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<AppState>(
                    builder: (_, current, _) => TodaysMealsSection(
                      state: current,
                      isDark: current.isDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  for (final width in [
    280.0,
    320.0,
    360.0,
    375.0,
    390.0,
    430.0,
    600.0,
    1024.0,
  ]) {
    for (final lang in ['en', 'ar', 'ku']) {
      for (final dark in [false, true]) {
        testWidgets(
          'meal cards at $width, $lang, ${dark ? 'dark' : 'light'} retain full name width',
          (tester) async {
            await mount(tester, width: width, lang: lang, dark: dark);
            final name = find.byKey(const ValueKey('logged-food-name-oats'));
            final card = find.byKey(const ValueKey('today-meal-breakfast'));
            final nameRect = tester.getRect(name),
                cardRect = tester.getRect(card);
            expect(nameRect.width, greaterThanOrEqualTo(cardRect.width - 32));
            expect(nameRect.left, greaterThanOrEqualTo(cardRect.left));
            expect(nameRect.right, lessThanOrEqualTo(cardRect.right));
            final paragraph = tester.renderObject<RenderParagraph>(name);
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: 'Ordinary food names must fit in two lines.',
            );
            if (lang == 'en') {
              for (final word in ['Demo:', 'oats', 'banana']) {
                final start = names[lang]!.indexOf(word);
                final boxes = paragraph.getBoxesForSelection(
                  TextSelection(
                    baseOffset: start,
                    extentOffset: start + word.length,
                  ),
                );
                expect(
                  boxes.map((box) => box.top).toSet(),
                  hasLength(1),
                  reason: 'Do not break $word into fragments.',
                );
              }
            }
            for (final key in [
              'logged-food-delete-oats',
              'logged-food-info-oats',
            ]) {
              final target = tester.getSize(find.byKey(ValueKey(key)));
              expect(target.width, greaterThanOrEqualTo(48));
              expect(target.height, greaterThanOrEqualTo(48));
            }
            final calories = tester.getRect(
              find.byKey(const ValueKey('logged-food-calories-oats')),
            );
            final delete = tester.getRect(
              find.byKey(const ValueKey('logged-food-delete-oats')),
            );
            expect(calories.overlaps(delete), isFalse);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }

  testWidgets(
    'exceptionally long names have a full-name dialog without navigating away',
    (tester) async {
      final state = await mount(tester, entries: [food('long', longName)]);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('logged-food-name-long')),
      );
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      await tester.tap(find.byKey(const ValueKey('logged-food-info-long')));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == longName,
        ),
        findsOneWidget,
      );
      expect(state.openCount, 0);
      await tester.tap(find.text(state.t.close));
      await tester.pumpAndSettle();
      expect(state.logs, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('delete still requires confirmation and updates meal status', (
    tester,
  ) async {
    final state = await mount(tester, entries: [food('oats', names['en']!)]);
    await tester.tap(find.byKey(const ValueKey('logged-food-delete-oats')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.t.cancel));
    await tester.pumpAndSettle();
    expect(state.logs, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('logged-food-delete-oats')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, state.t.remove));
    await tester.pumpAndSettle();
    expect(state.logs, isEmpty);
    expect(find.byKey(const ValueKey('logged-food-name-oats')), findsNothing);
    expect(find.text(state.t.eaten), findsNothing);
    expect(state.openCount, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'tapping the meal header still opens food logging for that slot',
    (tester) async {
      final state = await mount(tester);
      await tester.tap(find.text(state.t.breakfast));
      await tester.pumpAndSettle();
      expect(state.openedMeal, 'breakfast');
      expect(state.openCount, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final lang in ['en', 'ar', 'ku']) {
    testWidgets(
      'large text, multiple foods and large calorie values remain readable in $lang',
      (tester) async {
        await mount(
          tester,
          lang: lang,
          scale: 1.6,
          entries: [
            food('oats', names[lang]!),
            food('extra', 'Demo plain yogurt', calories: 123456),
            food('other', 'Demo other food', meal: null, calories: 123456),
          ],
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -900),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
