import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/utils/meal_micro_estimator.dart';

// [kTrackedMicroKeys] lives in food_database.dart

/// Parse micros from AI JSON (nested or flat).
Map<String, double> parseMicrosFromJson(dynamic raw) {
  if (raw == null || raw is! Map) return {};
  final out = <String, double>{};
  for (final k in kTrackedMicroKeys) {
    final v = raw[k];
    if (v is num) {
      final d = v.toDouble();
      if (d >= 0 && d.isFinite) out[k] = d;
    }
  }
  return out;
}

/// Soft upper bounds per single meal (not strict biology — avoids absurd AI values).
Map<String, double> _maxMicrosPerMeal(int mealCalories) {
  final calFactor = (mealCalories / 600).clamp(0.5, 2.5);
  return {
    'vitA': 1200 * calFactor,
    'vitC': 250 * calFactor,
    'vitD': 25 * calFactor,
    'vitE': 20 * calFactor,
    'vitK': 150 * calFactor,
    'vitB6': 3 * calFactor,
    'vitB12': 12 * calFactor,
    'folate': 400 * calFactor,
    'iron': 12 * calFactor,
    'calcium': 600 * calFactor,
    'potassium': 1800 * calFactor,
    'magnesium': 200 * calFactor,
    'phosphorus': 500 * calFactor,
    'zinc': 10 * calFactor,
    'selenium': 80 * calFactor,
    'sodium': 2500 * calFactor,
    'fiber': 15 * calFactor,
  };
}

Map<String, double> _clampMicros(Map<String, double> m, int mealCalories) {
  final caps = _maxMicrosPerMeal(mealCalories);
  return {
    for (final k in kTrackedMicroKeys)
      k: (m[k] ?? 0).clamp(0, caps[k] ?? 99999).toDouble(),
  };
}

bool _aiMicrosLookUsable(Map<String, double> rawAi, int mealCalories) {
  if (mealCalories <= 0) return false;
  if (rawAi.isEmpty) return false;
  var sum = 0.0;
  for (final k in kTrackedMicroKeys) {
    sum += rawAi[k] ?? 0;
  }
  if (sum < 0.8) return false;
  return true;
}

/// Match ingredient line to best [FoodItem] using EN/AR/KU names.
FoodItem? _bestFoodMatch(String line) {
  final norm = _normalize(line);
  if (norm.length < 3) return null;

  FoodItem? best;
  var bestScore = 0.0;

  for (final f in foodDatabase) {
    final candidates = <String>[f.name, f.nameAr ?? '', f.nameKu ?? ''];
    for (final name in candidates) {
      if (name.length < 3) continue;
      final nn = _normalize(name);
      var s = 0.0;
      if (norm.contains(nn) && nn.length >= 4) {
        s = 0.55 + 0.45 * (nn.length / norm.length).clamp(0.0, 1.0);
      } else if (nn.contains(norm) && norm.length >= 4) {
        s = 0.5 + 0.4 * (norm.length / nn.length).clamp(0.0, 1.0);
      } else {
        for (final w in norm.split(RegExp(r'\s+'))) {
          if (w.length < 4) continue;
          for (final nw in nn.split(RegExp(r'\s+'))) {
            if (nw.length < 4) continue;
            if (w == nw) s = s > 0.48 ? s : 0.48;
            if (w.contains(nw) || nw.contains(w)) {
              s = s > 0.42 ? s : 0.42;
            }
          }
        }
      }
      if (s > bestScore) {
        bestScore = s;
        best = f;
      }
    }
  }

  if (bestScore < 0.42 || best == null) return null;
  return best;
}

String _normalize(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'[0-9]+(\.[0-9]+)?\s*(g|kg|ml|oz|cup|tbsp|tsp)\b'), '')
      .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Sum micronutrients from matched database foods; splits meal calories across matches.
Map<String, double>? aggregateMicrosFromIngredients(
  List<String> ingredients,
  int mealCalories,
) {
  if (ingredients.isEmpty || mealCalories <= 0) return null;

  final lines = <String>[];
  for (final raw in ingredients) {
    for (final part in raw.split(RegExp(r'[,،;]'))) {
      final t = part.trim();
      if (t.length >= 3) lines.add(t);
    }
  }
  if (lines.isEmpty) return null;

  final matches = <FoodItem>[];
  for (final line in lines) {
    final f = _bestFoodMatch(line);
    if (f != null) matches.add(f);
  }

  if (matches.isEmpty) return null;

  final coverage = matches.length / lines.length;
  if (coverage < 0.34) return null;

  final calPer = mealCalories / matches.length;
  final totals = <String, double>{};
  for (final k in kTrackedMicroKeys) {
    totals[k] = 0;
  }

  for (final f in matches) {
    if (f.calories <= 0.5) continue;
    final grams = (calPer / f.calories) * f.nutritionReferenceG;
    final scaled = f.getMicrosForAmount(grams);
    for (final e in scaled.entries) {
      if (kTrackedMicroKeys.contains(e.key)) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
  }

  return totals;
}

Map<String, double> _blend(
  Map<String, double> a,
  Map<String, double> b,
  double wa,
  double wb,
) {
  final out = <String, double>{};
  final wSum = wa + wb;
  final na = wa / wSum;
  final nb = wb / wSum;
  for (final k in kTrackedMicroKeys) {
    out[k] = (a[k] ?? 0) * na + (b[k] ?? 0) * nb;
  }
  return out;
}

/// Best-effort micronutrients for logging a planned meal (AI + DB + estimator).
Map<String, double> resolveMicrosForPlannedMeal(
  Meal meal, {
  required int dailyCalorieGoal,
}) {
  final est = estimateMicrosForPlannedMeal(
    calories: meal.calories,
    protein: meal.protein,
    carbs: meal.carbs,
    fat: meal.fat,
    dailyCalorieGoal: dailyCalorieGoal,
  );

  List<String> ingredientsForMatch() {
    for (final lng in ['en', 'ar', 'ku']) {
      final v = meal.ingredientsForLang(lng);
      if (v.isNotEmpty) return v;
    }
    return meal.ingredients;
  }

  final ing = aggregateMicrosFromIngredients(ingredientsForMatch(), meal.calories);

  final aiOk = _aiMicrosLookUsable(meal.micros, meal.calories);
  final ai = _clampMicros(meal.micros, meal.calories);

  if (aiOk && ing != null) {
    return _clampMicros(
      _blend(ai, ing, 0.52, 0.48),
      meal.calories,
    );
  }
  if (aiOk) {
    return _clampMicros(_blend(ai, est, 0.72, 0.28), meal.calories);
  }
  if (ing != null) {
    return _clampMicros(_blend(ing, est, 0.68, 0.32), meal.calories);
  }
  return _clampMicros(est, meal.calories);
}
