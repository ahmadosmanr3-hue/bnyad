import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/widgets/barcode_label_dialog.dart';
import 'package:nutrify/widgets/app_build_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

BarcodeFoodLookup label(
  String name,
  String unit,
  double cal,
  double p,
  double c,
  double f,
) => BarcodeFoodLookup(
  barcode: '5449000000996',
  name: name,
  basisUnit: unit,
  caloriesPer100g: cal,
  proteinPer100g: p,
  carbsPer100g: c,
  fatPer100g: f,
);
void main() {
  final fixtures = [
    label('Fictional milk', 'ml', 60, 3.2, 4.8, 3.2),
    label('Water', 'ml', 0, 0, 0, 0),
    label('Fictional juice', 'ml', 45, 0.2, 10.8, 0.1),
    label('Fictional soda', 'ml', 42, 0, 10.6, 0),
    label('Oil label per 100g', 'g', 884, 0, 0, 100),
    label('Rice', 'g', 130, 2.7, 28, 0.3),
    label('Bread', 'g', 265, 8.7, 49, 3.2),
    label('Yogurt', 'g', 61, 3.5, 4.7, 3.3),
    label('Cheese', 'g', 403, 25, 1.3, 33),
    label('Packaged snack', 'g', 500, 6, 55, 28),
  ];
  for (final product in fixtures) {
    test(
      '${product.name}: portion scales calories and every macro together',
      () {
        expect(product.isValid, isTrue);
        final whole = product.macrosForAmount(250),
            half = product.macrosForAmount(125);
        for (final key in whole.keys) {
          expect(whole[key], closeTo(half[key]! * 2, 0.00001));
        }
      },
    );
  }
  test('250mL equals 0.25L, without any volume-to-mass assumption', () {
    final milk = fixtures.first;
    expect(milk.macrosForAmount(250), milk.macrosForAmount(0.25, unit: 'L'));
    expect(milk.macrosForAmount(0.25, unit: 'L')['calories'], 150);
    expect(() => milk.macrosForGrams(250), throwsArgumentError);
    expect(
      () => fixtures[4].macrosForAmount(1, unit: 'L'),
      throwsArgumentError,
    );
    final volumeOil = label(
      'Verified label oil per 100mL',
      'ml',
      828,
      0,
      0,
      92,
    );
    expect(volumeOil.macrosForAmount(1, unit: 'L')['calories'], 8280);
    final syrup = label('Dense syrup label per 100mL', 'ml', 460, 0, 115, 0);
    expect(syrup.isValid, isTrue);
    expect(syrup.macrosForAmount(0.25, unit: 'L')['carbs'], 287.5);
    expect(
      label('Invalid zero-energy oil', 'g', 0, 0, 0, 100).isValid,
      isFalse,
    );
  });
  test(
    'food catalog portions are normalized from their actual serving reference',
    () {
      final p = BarcodeFoodLookup.fromFoodItem(
        barcode: '5449000000996',
        food: const FoodItem(
          id: 'fixture',
          name: 'Rice bowl',
          calories: 390,
          protein: 8.1,
          carbs: 84,
          fat: 0.9,
          category: 'Grains',
          nutritionReferenceG: 300,
        ),
      );
      expect(p.caloriesPer100g, 130);
      expect(p.macrosForGrams(150)['calories'], 195);
    },
  );
  test(
    'mL log metadata survives local and API serialization; legacy entries stay grams',
    () {
      final e = LogEntry(
        id: '1',
        foodId: 'fixture',
        name: 'Milk',
        amount: 250,
        amountUnit: 'ml',
        calories: 150,
        protein: 8,
        carbs: 12,
        fat: 8,
        timestamp: 1,
      );
      expect(LogEntry.fromMap('1', e.toMap()).amountUnit, 'ml');
      expect(
        LogEntry.fromMap('1', {'amount_unit': 'ml', 'amount': 250}).amountUnit,
        'ml',
      );
      expect(LogEntry.fromMap('old', {'amount': 100}).amountUnit, 'g');
      expect(
        BarcodeFoodLookup.fromJson(fixtures.first.toJson()).basisUnit,
        'ml',
      );
    },
  );
  for (final lang in ['en', 'ar', 'ku']) {
    testWidgets('editable label remains usable at 320px in $lang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
            child: BarcodeLabelDialog(lookup: fixtures.first, lang: lang),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNWidgets(5));
      await tester.enterText(
        find.byType(TextField).at(1),
        lang == 'en' ? '61.5' : '٦١٫٥',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'settings show actual installed version and build, not pubspec defaults',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'BNYAD',
        packageName: 'com.bnyad.app',
        version: '1.0.2',
        buildNumber: '14',
        buildSignature: 'fixture',
      );
      await tester.pumpWidget(
        const MaterialApp(home: AppBuildInfo(lang: 'ku')),
      );
      await tester.pumpAndSettle();
      expect(find.text('1.0.2 (14)\ncom.bnyad.app'), findsOneWidget);
    },
  );
}
