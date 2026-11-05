// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/constants/food_serving_switch.dart';
import 'package:nutrify/models/food_item.dart';

void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Supply an output JSON path.');
  final rows = foodDatabase.map((f) {
    final canonical = foodCanonicalGrams(f);
    final portions = <Map<String, dynamic>>[];
    for (final mode in [FoodServingMode.piece, FoodServingMode.bowl]) {
      final portion = foodForServingMode(canonical, mode);
      if (portion.id != canonical.id && portion.nutritionReferenceG > 0) {
        portions.add({
          'id': mode.name,
          'amount': portion.nutritionReferenceG,
          'names': mode == FoodServingMode.piece
              ? {'en': 'piece', 'ar': 'قطعة', 'ku': 'دانە'}
              : {'en': 'bowl', 'ar': 'وعاء', 'ku': 'قاپ'},
          'estimated': true,
        });
      }
    }
    return {
      'id': f.id,
      'canonicalId': canonical.id,
      'names': {
        'en': f.name,
        'ar': f.nameAr ?? f.name,
        'ku': f.nameKu ?? f.name,
      },
      'category': f.category,
      'calories': f.calories,
      'protein': f.protein,
      'carbs': f.carbs,
      'fat': f.fat,
      'referenceAmount': f.nutritionReferenceG,
      'nutritionUnit': 'g',
      'amountKind': f.amountKind.name,
      'discreteUnit': f.discreteUnit?.name,
      'gramsPerPiece': f.gramsPerPiece,
      'gramsPerBowl': f.gramsPerBowl,
      'micros': f.micros,
      'portions': portions,
      'synonyms': FoodItem.searchAliases[f.id] ?? <String>[],
    };
  }).toList();
  File(args.single).writeAsStringSync(jsonEncode(rows));
  print(
    'Exported ${rows.length} legacy records, ${rows.map((r) => r['canonicalId']).toSet().length} canonical foods, ${rows.map((r) => r['category']).toSet().length} legacy categories.',
  );
}
