import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/scan_meal_draft.dart';
import 'package:nutrify/screens/scan_result_editor.dart';
import 'package:nutrify/theme/app_theme.dart';

Map<String, dynamic> scanFixture(
  List<String> ids, {
  bool unresolved = false,
}) => {
  'names': {'en': 'Reviewed meal', 'ar': 'وجبة للمراجعة', 'ku': 'ژەمی پشکنین'},
  'recognition_unresolved': unresolved,
  'identification': {
    'status': unresolved ? 'needs-review' : 'matched',
    'candidates': [
      {
        'en': 'Kurdish chicken biryani',
        'ar': 'برياني دجاج كردي',
        'ku': 'بریانی بە مریشک',
      },
      {'en': 'Dolma', 'ar': 'دولمة', 'ku': 'دۆڵمە'},
      {'en': 'Shawarma', 'ar': 'شاورما', 'ku': 'شاورمە'},
    ],
  },
  'components': [
    for (final id in ids)
      {
        'id': id,
        'names': {'en': id},
        'grams': 150,
        'calories': 99999,
        'protein': 99999,
        'carbs': 99999,
        'fat': 99999,
      },
  ],
};
Future<Map<String, FoodItem>> scanTestCatalog() async {
  final doc =
      jsonDecode(await rootBundle.loadString('assets/catalog/catalog.json'))
          as Map;
  return {
    for (final raw in doc['foods'] as List)
      raw['id'].toString(): FoodItem.fromJson(Map<String, dynamic>.from(raw)),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, FoodItem> foods;
  setUp(() async {
    foods = await scanTestCatalog();
  });
  test(
    'catalog is the only nutrition authority, estimates stay unrounded and confirmation is mandatory',
    () {
      final d = ScanMealDraft.fromScan(
        scanFixture(['g2', 'p1']),
        foods,
        {},
        'en',
      );
      expect(d.valid, isTrue);
      expect(
        d.totals['calories'],
        (foods['g2']!.calories + foods['p1']!.calories) * 1.5,
      );
      expect(() => d.toRequest(1, 'en'), throwsFormatException);
      d.confirmed = true;
      expect((d.toRequest(1, 'en')['items'] as List).length, 2);
      d.items.first.amount = 123.45;
      expect(
        d.totals['carbs'],
        foods['g2']!.carbs * 1.2345 + foods['p1']!.carbs * 1.5,
      );
    },
  );
  test(
    'unknown, disabled, malformed, duplicate and unsupported unit components cannot be logged',
    () {
      for (final raw in [
        scanFixture(['invented']),
        scanFixture(['g2', 'g2']),
        {
          ...scanFixture(['g2']),
          'components': [
            {'id': 'g2', 'grams': -5},
          ],
        },
        {
          ...scanFixture(['g2']),
          'components': [
            {'id': 'g2', 'grams': double.nan},
          ],
        },
        {
          ...scanFixture(['g2']),
          'components': [
            {'id': 'g2', 'grams': 100, 'unit': 'ml'},
          ],
        },
      ]) {
        final d = ScanMealDraft.fromScan(raw, foods, {}, 'en');
        expect(d.valid, isFalse);
      }
      expect(
        ScanMealDraft.fromScan(scanFixture(['g2']), foods, {'g2'}, 'en').valid,
        isFalse,
      );
    },
  );
  test(
    'prepared dishes remain whole; mixed whole plus ingredients never fabricate a recipe',
    () {
      for (final id in ['k2_chicken', 'k1', 'a3']) {
        final d = ScanMealDraft.fromScan(scanFixture([id]), foods, {}, 'ku');
        expect(d.mode, 'dish');
        expect(d.items.length, 1);
        expect(d.valid, isTrue);
        d.mode = 'components';
        expect(d.valid, isFalse);
      }
      final d = ScanMealDraft.fromScan(
        scanFixture(['k2_chicken', 'g2']),
        foods,
        {},
        'en',
      );
      expect(d.items, isEmpty);
      expect(d.pending.length, 2);
      expect(d.valid, isFalse);
    },
  );
  test(
    'regional aliases find preparations in EN AR Sorani without auto-selecting rice',
    () {
      for (final q in [
        'biryani',
        'برياني',
        'بریانی',
        'yaprax',
        'دولمة',
        'شاورما',
      ]) {
        final results = scanCatalogMatches(foods.values, {}, [q]);
        expect(results, isNotEmpty, reason: q);
      }
      expect(
        scanCatalogMatches(foods.values, {}, [
          'biryani',
        ]).any((f) => f.id == 'k2_chicken'),
        isTrue,
      );
    },
  );
  for (final lang in ['en', 'ar', 'ku']) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0, 430.0, 1024.0]) {
        testWidgets(
          'editor $lang ${dark ? 'dark' : 'light'} $width has visible footer and no overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 850);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final d = ScanMealDraft.fromScan(
              scanFixture(['g2', 'p1']),
              foods,
              {},
              lang,
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                home: ScanResultEditor(
                  draft: d,
                  foods: foods,
                  disabled: {},
                  lang: lang,
                  simulated: true,
                  onSave: (_) async => true,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('scan-save')), findsOneWidget);
            expect(
              tester.getRect(find.byKey(const ValueKey('scan-save'))).bottom,
              lessThanOrEqualTo(850),
            );
            expect(tester.takeException(), isNull);
            final row = find.byKey(const ValueKey('scan-portion-0'));
            await tester.ensureVisible(row);
            await tester.pumpAndSettle();
            await tester.tap(row);
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('portion-weight')),
              '٢٥٠',
            );
            await tester.pumpAndSettle();
            tester.testTextInput.hide();
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('scan-apply-portion')));
            await tester.pumpAndSettle();
            expect(d.items.first.amount, 250);
            expect(d.confirmed, isFalse);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets(
    'candidate is actionable; portion is required; corrections and confirmation gate saving',
    (tester) async {
      final d = ScanMealDraft.fromScan(
        scanFixture([], unresolved: true),
        foods,
        {},
        'en',
      );
      int saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScanResultEditor(
            draft: d,
            foods: foods,
            disabled: {},
            lang: 'en',
            onSave: (_) async {
              saves++;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('scan-save')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('scan-candidate-0')),
      );
      await tester.tap(find.byKey(const ValueKey('scan-candidate-0')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('scan-search')),
        'Kurdish Biryani with Chicken',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scan-food-k2_chicken')));
      await tester.pumpAndSettle();
      expect(d.items.single.amount, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('portion-weight')),
        '200',
      );
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scan-apply-portion')));
      await tester.pumpAndSettle();
      expect(d.mode, 'dish');
      expect(d.totals['calories'], foods['k2_chicken']!.calories * 2);
      await tester.tap(find.byKey(const ValueKey('scan-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scan-save')));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.byKey(const ValueKey('scan-save-error')), findsOneWidget);
      expect(d.confirmed, isFalse);
    },
  );
}
