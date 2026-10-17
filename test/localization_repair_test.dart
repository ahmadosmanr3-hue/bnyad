import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/l10n/framework_localizations.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/screens/weekly_summary_screen.dart';
import 'package:nutrify/utils/ai_trilingual_strings.dart';
import 'package:nutrify/l10n/notification_text.dart';
import 'package:nutrify/l10n/localized_time_picker.dart';
import 'localization_audit_test.dart' show flatten;

void main() {
  test(
    'all three digit scripts normalize without changing numeric precision',
    () {
      for (final input in ['75.125', '٧٥٫١٢٥', '۷۵,۱۲۵']) {
        expect(parseLocalizedDouble(input), 75.125);
      }
      for (final input in ['175', '١٧٥', '۱۷۵']) {
        expect(parseLocalizedDouble(input), 175);
        expect(parseLocalizedInt(input), 175);
      }
      for (final input in ['25', '٢٥', '۲۵']) {
        expect(parseLocalizedInt(input), 25);
      }
      expect(parseLocalizedDouble('١٬٢٣٤٫٥'), 1234.5);
      for (final bad in [
        '',
        'NaN',
        'Infinity',
        '1,2,3',
        '١٬٢',
        '1/2',
        '75kg',
      ]) {
        expect(parseLocalizedDouble(bad), isNull, reason: bad);
      }
      expect(parseLocalizedInt('٢٥.٥'), isNull);
    },
  );

  test(
    'digit formatter normalizes before ASCII filtering and preserves selection',
    () {
      const value = TextEditingValue(
        text: '١٢۳٤',
        selection: TextSelection.collapsed(offset: 4),
      );
      final result = const LocalizedDigitsFormatter().formatEditUpdate(
        TextEditingValue.empty,
        value,
      );
      expect(result.text, '1234');
      expect(result.selection.baseOffset, 4);
      expect(
        FilteringTextInputFormatter.digitsOnly
            .formatEditUpdate(TextEditingValue.empty, result)
            .text,
        '1234',
      );
    },
  );

  test('numeric fragments preserve logical min/max and count/goal order', () {
    expect(ltrFragment('15.1% — 25.1%'), '\u206615.1% — 25.1%\u2069');
    expect(ltrFragment('12345 / 5000'), '\u206612345 / 5000\u2069');
    expect(
      const SoraniMaterialLocalizations().parseCompactDate('١٧/١٠/٢٠٢٦'),
      DateTime(2026, 10, 17),
    );
    expect(
      const SoraniMaterialLocalizations().parseCompactDate('٣١/٢/٢٠٢٦'),
      isNull,
    );
  });

  test('canonical ckb names and AI helpers match legacy ku', () {
    for (final food in foodDatabase) {
      expect(food.getLocalizedName('ckb'), food.getLocalizedName('ku'));
      expect(food.servingLabelForLang('ckb'), food.servingLabelForLang('ku'));
    }
    expect(normAiLang('ckb'), 'ku');
  });

  test(
    'authored notification translations follow switching; legacy content remains unchanged',
    () {
      final note = {
        'title': 'Original',
        'body': 'Original body',
        'translations': {
          'en': {'title': 'Reminder', 'body': 'Today'},
          'ar': {'title': 'تذكير', 'body': 'اليوم'},
          'ckb': {'title': 'بیرهێنانەوە', 'body': 'ئەمڕۆ'},
        },
      };
      expect(notificationText(note, 'title', 'ku'), 'بیرهێنانەوە');
      expect(notificationText(note, 'body', 'ckb'), 'ئەمڕۆ');
      expect(notificationText(note, 'title', 'ar'), 'تذكير');
      expect(notificationText(note, 'title', 'en'), 'Reminder');
      expect(
        notificationText(
          {'title': 'Preserve authored message'},
          'title',
          'ckb',
        ),
        'Preserve authored message',
      );
    },
  );

  test('literal UI lookups exist and placeholder multiplicities match', () {
    final en = flatten(AppLocalizations.translationsFor('en'));
    for (final language in ['ar', 'ku', 'ckb']) {
      final translated = flatten(AppLocalizations.translationsFor(language));
      expect(translated.keys.toSet(), en.keys.toSet());
      for (final key in en.keys) {
        List<String> placeholders(String s) =>
            RegExp(r'\{\w+\}').allMatches(s).map((m) => m[0]!).toList()..sort();
        expect(
          placeholders(translated[key]!),
          placeholders(en[key]!),
          reason: '$language/$key',
        );
        expect(translated[key]!.trim(), isNotEmpty);
      }
    }
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final match in RegExp(
        r"\bt\.get\('([^']+)'\)",
      ).allMatches(file.readAsStringSync())) {
        expect(
          en.containsKey(match[1]),
          true,
          reason: '${file.path}/${match[1]}',
        );
      }
    }
    for (final lang in ['en', 'ar', 'ku']) {
      final t = AppLocalizations(lang);
      expect(
        t.get('or'),
        lang == 'en'
            ? 'or'
            : lang == 'ar'
            ? 'أو'
            : 'یان',
      );
      expect(
        t.premiumPerkMealPlan,
        isNot(
          contains(
            lang == 'en'
                ? 'weekly'
                : lang == 'ar'
                ? 'أسبوع'
                : 'هەفت',
          ),
        ),
      );
    }
  });

  Future<(AppState, ApiService)> fixture(String lang) async {
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
    );
    await state.initializeSession();
    await state.loginWithPassword('+9647700000010', 'fictional');
    await state.setLang(lang);
    return (state, api);
  }

  Widget shell(AppState state, Widget child) => ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      locale: bnyadLocale(state.lang),
      supportedLocales: bnyadLocales,
      localizationsDelegates: bnyadDelegates,
      home: Scaffold(body: child),
    ),
  );

  testWidgets(
    'language transitions and restart preserve fixtures and food allowance',
    (tester) async {
      final (state, api) = await fixture('en');
      await state.updateWater(1500);
      for (final lang in ['ckb', 'ar', 'ckb', 'en', 'ckb']) {
        await state.setLang(lang);
        expect(state.lang, lang == 'ckb' ? 'ku' : lang);
        expect(state.waterIntake, 1500);
        expect(state.goals!.calories, 2200);
      }
      state.dispose();
      final restored = AppState(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
      );
      await restored.initializeSession();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(restored.lang, 'ku');
      expect(restored.isRTL, true);
      expect(restored.waterIntake, 1500);
      expect(restored.goals!.calories, 2200);
      restored.dispose();
      api.dispose();
    },
  );

  for (final language in ['ckb', 'ar']) {
    testWidgets(
      'reminder input accepts all digit scripts in $language and validates bounds',
      (tester) async {
        final (state, api) = await fixture(language);
        late BuildContext context;
        await tester.pumpWidget(
          shell(
            state,
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final digits in [
          ['16', '30'],
          ['١٦', '٣٠'],
          ['۱۶', '۳۰'],
        ]) {
          final pending = showBnyadTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 8, minute: 0),
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('localized-hour')),
            '٢٤',
          );
          await tester.tap(
            find.text(MaterialLocalizations.of(context).okButtonLabel),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(MaterialLocalizations.of(context).invalidTimeLabel),
            findsOneWidget,
          );
          await tester.enterText(
            find.byKey(const ValueKey('localized-hour')),
            digits[0],
          );
          await tester.enterText(
            find.byKey(const ValueKey('localized-minute')),
            digits[1],
          );
          await tester.tap(
            find.text(MaterialLocalizations.of(context).okButtonLabel),
          );
          await tester.pumpAndSettle();
          expect(await pending, const TimeOfDay(hour: 16, minute: 30));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        state.dispose();
        api.dispose();
      },
    );
  }

  for (final lang in ['en', 'ar', 'ckb']) {
    testWidgets('framework controls use $lang, including real picker', (
      tester,
    ) async {
      final (state, api) = await fixture(lang);
      late BuildContext context;
      await tester.pumpWidget(
        shell(
          state,
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final material = MaterialLocalizations.of(context);
      final cupertino = CupertinoLocalizations.of(context);
      expect(Localizations.localeOf(context).languageCode, lang);
      expect(
        Directionality.of(context),
        lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
      );
      expect(
        material.cancelButtonLabel,
        lang == 'en'
            ? 'Cancel'
            : lang == 'ar'
            ? 'الإلغاء'
            : 'هەڵوەشاندنەوە',
      );
      expect(cupertino.cancelButtonLabel, isNotEmpty);
      if (lang == 'ckb') {
        expect(
          material.formatMediumDate(DateTime(2026, 10, 17)),
          contains('تشرینی یەکەم'),
        );
      }
      final picker = showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
      );
      await tester.pumpAndSettle();
      expect(find.text(material.cancelButtonLabel), findsOneWidget);
      await tester.tap(find.text(material.cancelButtonLabel));
      await tester.pumpAndSettle();
      await picker;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      api.dispose();
    });

    for (final width in [320.0, 430.0]) {
      testWidgets('welcome/password/OTP $lang width=$width has no overflow', (
        tester,
      ) async {
        final (state, api) = await fixture(lang);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(shell(state, const LoginScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(state.t.login));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField).first, '٧٧٠٠٠٠٠٠١٠');
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          '7700000010',
        );
        await tester.tap(find.text(state.t.loginWithOtp));
        await tester.pumpAndSettle();
        if (find.byKey(const ValueKey('otp-step')).evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextField).last, '۱۲۳۴۵۶');
          expect(
            tester
                .widget<TextField>(find.byType(TextField).last)
                .controller!
                .text,
            '123456',
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
        api.dispose();
      });
    }
  }

  testWidgets(
    'localized weight saves, invalid values explain errors, no chart assertion',
    (tester) async {
      final (state, api) = await fixture('ckb');
      await tester.pumpWidget(shell(state, const WeeklySummaryScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip(state.t.weeklyUpdateWeight));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '-١');
      await tester.tap(find.text(state.t.save));
      await tester.pumpAndSettle();
      expect(find.text(state.t.get('invalidNumber')), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '٧٥٫٥');
      await tester.tap(find.text(state.t.save));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(state.weightHistory.values, contains(75.5));
      expect(state.goals!.calories, 2200);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      api.dispose();
    },
  );
}
