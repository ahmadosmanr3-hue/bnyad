import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/widgets/food_browse_tile.dart';
import 'package:nutrify/utils/measured_portion.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:nutrify/services/recent_foods.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/utils/catalog_scan_correction.dart';
import 'package:nutrify/utils/food_search_match.dart';
import 'package:nutrify/widgets/measured_portion_dialog.dart';

void main() {
  test(
    'measured rice, pizza and drink totals use their own reference basis',
    () {
      const rice = FoodItem(
        id: 'qa-rice',
        name: 'Fictional measured rice',
        category: 'Rice',
        calories: 130,
        protein: 2.7,
        carbs: 28,
        fat: .3,
      );
      const pizza = FoodItem(
        id: 'qa-pizza',
        name: 'Fictional measured pizza',
        category: 'Pizza',
        calories: 266,
        protein: 11,
        carbs: 33,
        fat: 10,
      );
      const drink = FoodItem(
        id: 'qa-drink',
        name: 'Fictional measured drink',
        category: 'Drink',
        nutritionUnit: 'ml',
        calories: 46,
        protein: 0,
        carbs: 11.5,
        fat: 0,
      );
      final spoonGrams = measuredPortionAmount(amountPerUnit: 13, count: 3);
      expect(spoonGrams, 39);
      expect(rice.calories * rice.macroRatio(spoonGrams), closeTo(50.7, .001));
      final slicesGrams = measuredPortionAmount(amountPerUnit: 90, count: 2);
      expect(
        pizza.calories * pizza.macroRatio(slicesGrams),
        closeTo(478.8, .001),
      );
      expect(
        pizza.protein * pizza.macroRatio(slicesGrams),
        closeTo(19.8, .001),
      );
      final canMl = measuredPortionAmount(amountPerUnit: 330, count: 1);
      expect(drink.calories * drink.macroRatio(canMl), closeTo(151.8, .001));
      expect(drink.carbs * drink.macroRatio(canMl), closeTo(37.95, .001));
    },
  );
  test(
    'catalog correction scales verified mass nutrition and rejects volume guessing',
    () {
      const food = FoodItem(
        id: 'test-rice',
        name: 'Rice',
        nameAr: 'أرز',
        nameKu: 'برنج',
        category: 'Rice',
        calories: 130,
        protein: 2.7,
        carbs: 28,
        fat: .3,
        micros: {'iron': 1},
        nutritionReferenceG: 100,
      );
      final corrected = catalogScanComponent(food, 250);
      expect(corrected['calories'], 325);
      expect(corrected['protein'], closeTo(6.75, .001));
      expect(corrected['micros'], {'iron': 2.5});
      expect(corrected['names'], {'en': 'Rice', 'ar': 'أرز', 'ku': 'برنج'});
      for (final grams in [0.0, -1.0, double.nan, 2001.0]) {
        expect(() => catalogScanComponent(food, grams), throwsFormatException);
      }
      const liquid = FoodItem(
        id: 'drink',
        name: 'Drink',
        category: 'Drink',
        nutritionUnit: 'ml',
        calories: 40,
        protein: 0,
        carbs: 10,
        fat: 0,
      );
      expect(() => catalogScanComponent(liquid, 250), throwsFormatException);
    },
  );
  test('search folds Arabic marks, Sorani letters and localized digits', () {
    expect(
      normalizeForFoodSearch('أَرْز ١٢۳'),
      normalizeForFoodSearch('ارز 123'),
    );
    expect(
      normalizeForFoodSearch('كەباب ي'),
      normalizeForFoodSearch('کەباب ی'),
    );
  });
  test(
    'record during account initialization retains previous recent foods',
    () async {
      SharedPreferences.setMockInitialValues({
        'recent_foods_v1_test': ['old'],
      });
      final recents = RecentFoods();
      final loading = recents.attach('test');
      await recents.record('new');
      await loading;
      expect(recents.ids, ['new', 'old']);
      recents.dispose();
      final reopened = RecentFoods();
      await reopened.attach('test');
      expect(reopened.ids, ['new', 'old']);
      reopened.dispose();
    },
  );
  for (final lang in ['en', 'ar', 'ku']) {
    testWidgets(
      'measured portion dialog accepts localized measured quantities $lang',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        double? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: lang == 'en'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await showMeasuredPortion(
                        context,
                        liquid: false,
                        pizza: true,
                        lang: lang,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.enterText(
          find.byType(TextField).first,
          lang == 'en' ? '90' : '٩٠',
        );
        await tester.enterText(
          find.byType(TextField).last,
          lang == 'en' ? '2' : '٢',
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(result, 180);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'measured spoon, plate, slices and drink quantities never assume a weight',
    () {
      expect(measuredPortionAmount(amountPerUnit: 13, count: 3), 39);
      expect(measuredPortionAmount(amountPerUnit: 410, count: .5), 205);
      expect(measuredPortionAmount(amountPerUnit: 90, count: 3), 270);
      expect(measuredPortionAmount(amountPerUnit: 330, count: 2), 660);
      expect(
        measuredPortionAmount(
          amountPerUnit: parseLocalizedDouble('١٫٥')! * 1000,
          count: 1,
        ),
        1500,
      );
      for (final x in [0.0, -1.0, double.nan, double.infinity, 10001.0]) {
        expect(
          () => measuredPortionAmount(amountPerUnit: x, count: 1),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'recents survive restart, deduplicate and never cross account/backend boundaries',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = RecentFoods();
      await first.attach('test-api|1');
      await first.record('rice');
      await first.record('milk');
      await first.record('rice');
      expect(first.ids, ['rice', 'milk']);
      first.dispose();
      final restored = RecentFoods();
      await restored.attach('test-api|1');
      expect(restored.ids, ['rice', 'milk']);
      await restored.attach('test-api|2');
      expect(restored.ids, isEmpty);
      await restored.attach('other-api|1');
      expect(restored.ids, isEmpty);
      await restored.attach(null);
      await restored.record('private');
      expect(restored.ids, isEmpty);
      restored.dispose();
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    for (final rtl in [false, true]) {
      testWidgets('long text result $width RTL=$rtl remains accessible', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  body: FoodBrowseTile(
                    name: rtl
                        ? 'بریانی مریشک و سەوزە / برياني دجاج وخضار'
                        : 'Chicken biryani with vegetables and long grain rice',
                    category: 'Regional rice / خواردنی برنج',
                    nutrition: '196 kcal · 100 g',
                    actionLabel: rtl ? 'هەڵبژاردنی پشک' : 'Choose portion',
                    favorite: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star_border),
                    ),
                    onOpen: () => opened++,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
        await tester.tap(find.byType(OutlinedButton));
        expect(opened, 1);
      });
    }
  }
}
