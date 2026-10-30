import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/food_catalog.dart';
import 'package:nutrify/constants/food_serving_switch.dart';

void main() {
  final document =
      jsonDecode(File('assets/catalog/catalog.json').readAsStringSync())
          as Map<String, dynamic>;
  late ApiService api;
  late FoodCatalog catalog;
  setUp(() {
    api = ApiService(
      baseUrl: 'https://example.invalid/api',
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    catalog = FoodCatalog(api)..accept(document);
  });
  tearDown(() {
    catalog.dispose();
    api.dispose();
    FoodItem.catalogOverrides = {};
  });
  test(
    'all 829 records parse, nutrition bases remain finite and trilingual',
    () {
      expect(catalog.foods.length, 829);
      expect(catalog.categories.length, 49);
      for (final food in catalog.foods.values) {
        expect(food.isTrilingual, true);
        expect(food.nutritionReferenceG, greaterThan(0));
        expect(food.calories.isFinite, true);
      }
    },
  );
  test(
    '250mL and liter nutrition retain milk density, servings preserve canonical identity',
    () {
      final f = catalog.foods['usda_sr_171265']!;
      expect(f.isLiquid, true);
      expect(
        f.calories * f.macroRatio(250),
        closeTo(61 * 30.5 / 29.5735295625 * 2.5, .001),
      );
      expect(f.calories * f.macroRatio(1000), closeTo(f.calories * 10, .001));
      final variant = f.asServingVariant(
        idSuffix: 'portion',
        gramsPerUnit: 250,
      );
      expect(variant.canonicalKey, f.canonicalKey);
      expect(variant.nutritionUnit, 'ml');
    },
  );
  test(
    'new catalog uses grouped legacy variants, localized aliases, parent and child categories',
    () {
      expect(
        catalog
            .browse()
            .where((r) => r.displayFood.id == 'usda_sr_171265')
            .length,
        1,
      );
      final f = catalog.foods['usda_sr_171265']!;
      for (final query in ['milk', 'شیر', 'حليب']) {
        expect(f.matchesSearchQuery(query), true);
      }
      expect(catalog.categoryMatches(f, 'drinks'), true);
      expect(catalog.categoryMatches(f, 'milk'), true);
      expect(catalog.categoryMatches(f, 'eggs'), false);
    },
  );
  test(
    'remote disable removes browsing row, updated metadata replaces serving lookup without changing old logs',
    () {
      final f = catalog.foods['k1']!;
      catalog.accept({
        ...document,
        'disabledIds': ['usda_sr_171265'],
        'foods': (document['foods'] as List)
            .map((r) => r['id'] == 'k1' ? {...r, 'calories': 123} : r)
            .toList(),
      });
      expect(
        catalog.browse().any((r) => r.displayFood.id == 'usda_sr_171265'),
        false,
      );
      expect(foodById('k1')!.calories, 123);
      expect(f.calories, isNot(123));
    },
  );
  test(
    'invalid cached catalog is rejected atomically; existing catalog remains usable',
    () {
      final invalid = Map<String, dynamic>.from(
        (document['foods'] as List).first,
      )..['referenceAmount'] = 0;
      expect(
        () => catalog.accept({
          ...document,
          'foods': [invalid],
        }),
        throwsFormatException,
      );
      expect(catalog.foods.length, 829);
    },
  );
}
