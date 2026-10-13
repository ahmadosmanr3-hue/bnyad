import 'package:nutrify/constants/food_database.dart';

/// Estimates micronutrients for a logged composite meal (AI meal plan / swap)
/// when no per-ingredient data exists. Uses the user's daily calorie goal as
/// reference so portions align with the same [dailyRecommended] scale as the DB.
Map<String, double> estimateMicrosForPlannedMeal({
  required num calories,
  required num protein,
  required num carbs,
  required num fat,
  int dailyCalorieGoal = 2000,
}) {
  final c = calories.toDouble().clamp(1.0, 12000.0);
  final p = protein.toDouble().clamp(0.0, 500.0);
  final carb = carbs.toDouble().clamp(0.0, 1000.0);
  final f = fat.toDouble().clamp(0.0, 500.0);

  final goal = dailyCalorieGoal.clamp(1200, 5000);
  final calRatio = (c / goal).clamp(0.04, 1.2);

  final out = <String, double>{};
  for (final e in dailyRecommended.entries) {
    out[e.key] = e.value * calRatio * 0.9;
  }

  final pCal = p * 4;
  final carbCal = carb * 4;
  final fatCal = f * 9;
  final denom = pCal + carbCal + fatCal;
  final proteinFrac = denom > 0 ? pCal / denom : 0.25;
  final fatFrac = denom > 0 ? fatCal / denom : 0.30;
  final carbFrac = denom > 0 ? carbCal / denom : 0.45;

  void mul(Iterable<String> keys, double factor) {
    for (final k in keys) {
      out[k] = (out[k] ?? 0) * factor;
    }
  }

  if (proteinFrac >= 0.22) {
    mul(['iron', 'zinc', 'vitB12', 'selenium', 'phosphorus'], 1.0 + (proteinFrac - 0.22) * 0.9);
  }
  if (fatFrac >= 0.32) {
    mul(['vitA', 'vitD', 'vitE', 'vitK'], 1.0 + (fatFrac - 0.32) * 0.6);
  }
  if (carbFrac >= 0.38) {
    mul(['potassium', 'vitC', 'fiber', 'folate', 'vitB6'], 1.0 + (carbFrac - 0.38) * 0.45);
  }
  if (carbFrac >= 0.45 && proteinFrac >= 0.18) {
    mul(['calcium', 'magnesium'], 1.08);
  }

  return out;
}

/// Rough edible portion mass (g) for display when logging a whole planned meal.
int estimatedMealGramsForDisplay(int mealCalories) {
  if (mealCalories <= 0) return 100;
  return (mealCalories / 2.4).round().clamp(80, 900);
}
