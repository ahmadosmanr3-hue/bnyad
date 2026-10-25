import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/l10n/scan_strings.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/widgets/barcode_scan_flow.dart';

class LabelState extends AppState {
  final String language;
  final bool dark;
  LabelState(ApiService api, this.language, this.dark)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
      );
  @override
  String get lang => language;
  @override
  AppLocalizations get t => AppLocalizations(language);
  @override
  bool get isDark => dark;
  final logs = <LogEntry>[];
  final save = Completer<bool>();
  @override
  Future<bool> addLogEntry(LogEntry entry) {
    logs.add(entry);
    return save.future;
  }
}

const product = BarcodeFoodLookup(
  barcode: '5449000000996',
  name: 'Fictional packaged milk with a long original-language product name',
  source: 'open_food_facts',
  caloriesPer100g: 60,
  proteinPer100g: 3.2,
  carbsPer100g: 4.8,
  fatPer100g: 3.2,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<LabelState> mount(
    WidgetTester tester,
    String lang,
    bool dark,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiService(
      baseUrl: 'https://fixture.invalid/api',
      client: MockClient((_) async => http.Response('{}', 503)),
    );
    final state = LabelState(api, lang, dark);
    addTearDown(state.dispose);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
            child: BarcodeConfirmSheet(state: state, lookup: product),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  for (final lang in ['en', 'ar', 'ku']) {
    for (final width in [320.0, 390.0, 430.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'food confirmation $lang $width dark=$dark has no layout overflow',
          (tester) async {
            final state = await mount(tester, lang, dark, width);
            expect(tester.takeException(), isNull);
            final button = find.widgetWithText(
              ElevatedButton,
              state.t.barcodeLogYes,
            );
            expect(
              tester.widget<ElevatedButton>(button).onPressed,
              isNull,
              reason: 'Unknown label basis requires an explicit choice',
            );
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final lang in ['en', 'ar', 'ku']) {
    testWidgets(
      '$lang logs 0.25L as 250mL once, with unchanged label scaling',
      (tester) async {
        final state = await mount(tester, lang, false, 320);
        final s = ScanStrings(lang);
        final basis = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(basis);
        await tester.tap(basis);
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.per100ml).last);
        await tester.pumpAndSettle();
        final units = find.byWidgetPredicate(
          (w) =>
              w is DropdownButton<String> &&
              (w.items?.any((i) => i.value == 'L') ?? false),
        );
        await tester.ensureVisible(units);
        await tester.tap(units);
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.liters).last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          lang == 'en' ? '0.25' : '٠٫٢٥',
        );
        await tester.pump();
        final save = find.widgetWithText(ElevatedButton, state.t.barcodeLogYes);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(state.logs, hasLength(1));
        expect(state.logs.single.amount, 250);
        expect(state.logs.single.amountUnit, 'ml');
        expect(state.logs.single.calories, 150);
        expect(
          tester.widget<ElevatedButton>(save).onPressed,
          isNull,
          reason: 'A pending save must not create a duplicate',
        );
        state.save.complete(false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
