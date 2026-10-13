// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:nutrify/constants/food_database.dart';

void main() {
  final list = foodDatabase.map((f) => {
    'external_id': f.id,
    'category': f.category,
    'calories': f.calories,
    'protein': f.protein,
    'carbs': f.carbs,
    'fats': f.fat,
    'serving_size': f.nutritionReferenceG,
    'serving_unit': 'g',
    if (f.micros.isNotEmpty) 'micros': f.micros,
    'names': {
      'en': f.name,
      if (f.nameAr != null) 'ar': f.nameAr,
      if (f.nameKu != null) 'ckb': f.nameKu,
    },
  }).toList();

  final outDir = Directory('laravel-backend/database/data');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File('${outDir.path}/food_items.json');
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(list),
  );
  print('Exported ${list.length} food items to ${outFile.path}');
}
