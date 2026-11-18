import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nutrify/models/scan_meal_draft.dart';
import 'package:nutrify/screens/scan_result_editor.dart';
import 'package:nutrify/theme/app_theme.dart';
import '../test/scan_result_editor_test.dart' show scanFixture, scanTestCatalog;

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await settle(tester);
  await tester.tap(f);
  await settle(tester);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native replace/add/remove, invalid quantity, duplicate and rapid-save protection',
    (tester) async {
      final foods = await scanTestCatalog();
      tester.testTextInput.register();
      if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
      for (final lang in ['en', 'ar', 'ku']) {
        final d = ScanMealDraft.fromScan(
          scanFixture([], unresolved: true),
          foods,
          {},
          lang,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: lang == 'en' ? AppTheme.lightTheme : AppTheme.darkTheme,
            home: ScanResultEditor(
              draft: d,
              foods: foods,
              disabled: {},
              lang: lang,
              simulated: true,
              onSave: (_) async => false,
            ),
          ),
        );
        await settle(tester);
        await binding.takeScreenshot(
          '${Platform.operatingSystem}_scanner-candidates-$lang',
        );
        expect(find.byKey(const ValueKey('scan-candidate-2')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      final d = ScanMealDraft.fromScan(
        scanFixture(['g2', 'p1']),
        foods,
        {},
        'ku',
      );
      var calls = 0;
      final result = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ScanResultEditor(
            key: const ValueKey('correction-editor'),
            draft: d,
            foods: foods,
            disabled: {},
            lang: 'ku',
            simulated: true,
            onSave: (draft) {
              calls++;
              expect(draft.toRequest(1, 'ku')['confirmed'], isTrue);
              return result.future;
            },
          ),
        ),
      );
      await settle(tester);
      await press(tester, 'scan-portion-0');
      await tester.enterText(
        find.byKey(const ValueKey('portion-weight')),
        '-20',
      );
      await settle(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('scan-apply-portion')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('portion-weight')),
        '٢٠٠',
      );
      await settle(tester);
      await press(tester, 'portion-plus');
      await press(tester, 'portion-minus');
      await press(tester, 'scan-apply-portion');
      expect(d.items.first.amount, 200);
      await press(tester, 'scan-change-0');
      await tester.enterText(
        find.byKey(const ValueKey('scan-search')),
        foods['g1']!.name,
      );
      await settle(tester);
      await press(tester, 'scan-food-g1');
      await tester.enterText(
        find.byKey(const ValueKey('portion-weight')),
        '١٢٥',
      );
      await settle(tester);
      tester.testTextInput.hide();
      await settle(tester);
      await press(tester, 'scan-apply-portion');
      expect(d.items.first.food.id, 'g1');
      expect(d.items.first.amount, 125);
      await press(tester, 'scan-add');
      await tester.enterText(
        find.byKey(const ValueKey('scan-search')),
        foods['v3']!.name,
      );
      await settle(tester);
      await press(tester, 'scan-food-v3');
      expect(d.items.last.amount, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('portion-weight')),
        '٧٥',
      );
      await settle(tester);
      tester.testTextInput.hide();
      await settle(tester);
      await press(tester, 'scan-apply-portion');
      expect(d.items.length, 3);
      expect(
        d.totals['calories'],
        closeTo(
          foods['g1']!.calories * 1.25 +
              foods['p1']!.calories * 1.5 +
              foods['v3']!.calories * .75,
          .0001,
        ),
      );
      await press(tester, 'scan-remove-2');
      expect(d.items.length, 2);
      await press(tester, 'scan-add');
      await tester.enterText(
        find.byKey(const ValueKey('scan-search')),
        foods['p1']!.name,
      );
      await settle(tester);
      await press(tester, 'scan-food-p1');
      expect(d.items.length, 2);
      expect(d.valid, isTrue);
      await binding.takeScreenshot(
        '${Platform.operatingSystem}_scanner-corrected-components-ku',
      );
      await press(tester, 'scan-confirm');
      // Deliberately pending save: repeated taps cannot submit a second batch.
      await tester.tap(find.byKey(const ValueKey('scan-save')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('scan-save')));
      await tester.pump();
      expect(calls, 1);
      result.complete(false);
      await settle(tester);
      expect(find.byKey(const ValueKey('scan-save-error')), findsOneWidget);
      expect(d.confirmed, isFalse);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(
        '${Platform.operatingSystem}_scanner-save-error-ku',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      tester.testTextInput.unregister();
    },
  );
}
