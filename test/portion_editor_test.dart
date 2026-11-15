import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/widgets/portion_editor.dart';

const food = FoodItem(
  id: 'test-rice',
  name: 'Cooked rice',
  calories: 130,
  protein: 2.7,
  carbs: 28,
  fat: .3,
  category: 'Grains',
);
void main() {
  for (final lang in ['en', 'ar', 'ku']) {
    for (final width in [320.0, 430.0, 1024.0]) {
      for (final dark in [false, true]) {
        testWidgets('portion editor $lang $width dark=$dark', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          double? total = 100;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: Scaffold(
                body: Directionality(
                  textDirection: lang == 'en'
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: PortionEditor(
                      food: food,
                      lang: lang,
                      amount: 100,
                      onChanged: (v) => total = v,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.byKey(const ValueKey('portion-tablespoon')));
          await tester.pumpAndSettle();
          expect(total, isNull); // No invented spoon weight.
          await tester.ensureVisible(
            find.byKey(const ValueKey('portion-weight')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('portion-weight')),
            lang == 'en' ? '12.5' : '١٢٫٥',
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('portion-plus')),
          );
          for (var i = 0; i < 4; i++) {
            await tester.tap(find.byKey(const ValueKey('portion-plus')));
          }
          await tester.pumpAndSettle();
          expect(total, 62.5);
          await tester.enterText(
            find.byKey(const ValueKey('portion-count')),
            '-1',
          );
          await tester.pump();
          expect(total, isNull);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('liquid liter keeps volume, no density assumption', (
    tester,
  ) async {
    double? total;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortionEditor(
              food: const FoodItem(
                id: 'milk',
                name: 'Milk',
                calories: 60,
                protein: 3,
                carbs: 5,
                fat: 3,
                category: 'Drink',
                nutritionUnit: 'ml',
              ),
              lang: 'en',
              amount: 100,
              onChanged: (v) => total = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('portion-liter')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('portion-weight')),
      '0.25',
    );
    expect(total, 250);
  });
  testWidgets(
    'USDA cup weights yield food-specific spoon estimates, never heaped defaults',
    (tester) async {
      double? amount;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortionEditor(
                food: const FoodItem(
                  id: 'cooked',
                  name: 'Cooked rice',
                  calories: 130,
                  protein: 2.7,
                  carbs: 28,
                  fat: .3,
                  category: 'Grains',
                  source: {'type': 'usda'},
                  portions: [
                    {
                      'amount': 158,
                      'names': {'en': '1 cup (158 g)'},
                    },
                  ],
                ),
                lang: 'en',
                amount: 100,
                onChanged: (v) => amount = v,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('portion-level')));
      await tester.pump();
      expect(amount, closeTo(158 / 16, .05));
      await tester.tap(find.byKey(const ValueKey('portion-heaped')));
      await tester.pump();
      expect(amount, isNull);
    },
  );
  testWidgets('bowl fill scales the measured mass without inventing density', (
    tester,
  ) async {
    double? amount;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortionEditor(
              food: food,
              lang: 'en',
              amount: 100,
              onChanged: (v) => amount = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('portion-small-bowl')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('portion-weight')));
    await tester.enterText(find.byKey(const ValueKey('portion-weight')), '200');
    await tester.ensureVisible(find.byKey(const ValueKey('portion-plus')));
    await tester.tap(find.byKey(const ValueKey('portion-plus')));
    await tester.pump();
    tester
        .widget<Slider>(find.byKey(const ValueKey('portion-fill')))
        .onChanged!(.5);
    await tester.pump();
    expect(amount, 200);
    expect(tester.takeException(), isNull);
  });
}
