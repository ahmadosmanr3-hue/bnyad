import 'package:nutrify/models/food_item.dart';

/// Convert the selected catalog reference to absolute component nutrition.
/// A volume reference needs its own volume workflow; never assume mL equals g.
Map<String, dynamic> catalogScanComponent(FoodItem food, double grams) {
  if (food.nutritionReferenceG <= 0 ||
      !food.nutritionReferenceG.isFinite ||
      food.isLiquid ||
      !grams.isFinite ||
      grams <= 0 ||
      grams > 2000) {
    throw const FormatException(
      'Choose a gram-based food and a measured portion up to 2000 g.',
    );
  }
  final ratio = food.macroRatio(grams);
  return {
    'id': food.id,
    'foodId': food.id,
    'names': {
      for (final lang in ['en', 'ar', 'ku']) lang: food.getLocalizedName(lang),
    },
    'grams': grams,
    'calories': food.calories * ratio,
    'protein': food.protein * ratio,
    'carbs': food.carbs * ratio,
    'fat': food.fat * ratio,
    'micros': food.getMicrosForAmount(grams),
    'correctedFromCatalog': true,
  };
}
