import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/log_entry.dart';

/// Central micronutrient math — scaling, aggregation, goal validation.

/// Scale food micros for a logged portion (respects [nutritionReferenceG] + bone).
Map<String, double> scaleMicrosFromFood(
  FoodItem food,
  double grams, {
  double boneMult = 1.0,
}) {
  final amountG = grams * boneMult;
  if (amountG <= 0) return {};

  final direct = food.getMicrosForAmount(amountG);
  if (direct.values.any((v) => v > 0)) {
    return _fillMissingMicroKeys(direct, food, amountG);
  }
  return estimateMicrosFromFoodProfile(food, amountG);
}

/// Sum micronutrients across today's food log entries.
Map<String, double> aggregateDailyMicros(Iterable<LogEntry> logs) {
  final totals = <String, double>{for (final k in kTrackedMicroKeys) k: 0};
  for (final e in logs) {
    for (final k in kTrackedMicroKeys) {
      final v = e.micros[k];
      if (v != null && v.isFinite && v > 0) {
        totals[k] = (totals[k] ?? 0) + v;
      }
    }
  }
  return totals;
}

/// Ensures every tracked key has a goal (IOM baseline + stored personalization).
Map<String, double> resolveEffectiveMicroGoals(Map<String, double> storedGoals) {
  final out = Map<String, double>.from(dailyRecommended);
  for (final k in kTrackedMicroKeys) {
    final v = storedGoals[k];
    if (v != null && v.isFinite && v > 0) {
      out[k] = v;
    }
  }
  return out;
}

/// Merge AI goals with evidence-based DRIs — AI cannot override more than ±35%.
Map<String, double> validateAndMergeMicroGoals(
  Map<String, double> evidenceBased,
  Map<String, double> aiGoals,
) {
  final merged = Map<String, double>.from(evidenceBased);
  for (final k in kTrackedMicroKeys) {
    final ai = aiGoals[k];
    if (ai == null || !ai.isFinite || ai <= 0) continue;
    final base = evidenceBased[k] ?? dailyRecommended[k] ?? ai;
    final lo = base * 0.65;
    final hi = base * 1.35;
    merged[k] = ai.clamp(lo, hi).toDouble();
  }
  return merged;
}

/// USDA-inspired category templates per 100g (approximate when DB lacks micros).
Map<String, double> _categoryMicroTemplatePer100g(String category) {
  switch (category.toLowerCase()) {
    case 'protein':
    case 'meat':
    case 'poultry':
    case 'fish':
      return {
        'vitB12': 1.4, 'iron': 1.8, 'zinc': 2.5, 'selenium': 25,
        'phosphorus': 180, 'potassium': 280, 'vitB6': 0.35, 'vitD': 0.3,
      };
    case 'dairy':
      return {
        'calcium': 120, 'vitD': 0.5, 'vitB12': 0.4, 'phosphorus': 95,
        'vitA': 30, 'potassium': 150, 'zinc': 0.5,
      };
    case 'vegetable':
      return {
        'vitA': 80, 'vitC': 18, 'vitK': 25, 'folate': 35, 'fiber': 2.8,
        'potassium': 250, 'magnesium': 18, 'iron': 0.8,
      };
    case 'fruit':
      return {
        'vitC': 35, 'vitA': 15, 'potassium': 180, 'fiber': 2.2,
        'folate': 12, 'vitE': 0.4,
      };
    case 'grains':
    case 'bread':
      return {
        'iron': 1.2, 'folate': 25, 'fiber': 2.5, 'magnesium': 35,
        'phosphorus': 90, 'vitB6': 0.12, 'selenium': 12,
      };
    case 'legumes':
      return {
        'iron': 2.5, 'folate': 120, 'fiber': 7, 'magnesium': 50,
        'potassium': 350, 'zinc': 1.2, 'phosphorus': 140,
      };
    case 'nuts':
      return {
        'vitE': 2.5, 'magnesium': 75, 'fiber': 3.5, 'selenium': 8,
        'vitB6': 0.15, 'iron': 1.0, 'zinc': 1.5,
      };
    case 'supplement':
      return {};
    default:
      return {
        'potassium': 120, 'magnesium': 15, 'phosphorus': 50,
        'vitC': 5, 'iron': 0.5,
      };
  }
}

/// Estimate micros from macros + category when food DB row has no micro data.
Map<String, double> estimateMicrosFromFoodProfile(FoodItem food, double grams) {
  final ratio = grams / food.nutritionReferenceG;
  final calRatio = food.calories > 0
      ? (food.calories * ratio) / 2000.0
      : ratio;

  final template = _categoryMicroTemplatePer100g(food.category);
  final out = <String, double>{for (final k in kTrackedMicroKeys) k: 0};

  for (final e in template.entries) {
    out[e.key] = e.value * ratio;
  }

  // Macro-informed adjustments (Atwater-based).
  final p = food.protein * ratio;
  final c = food.carbs * ratio;
  final f = food.fat * ratio;
  if (p >= 8) {
    out['iron'] = (out['iron'] ?? 0) + p * 0.04;
    out['zinc'] = (out['zinc'] ?? 0) + p * 0.025;
    out['vitB12'] = (out['vitB12'] ?? 0) + p * 0.008;
  }
  if (c >= 15) {
    out['fiber'] = (out['fiber'] ?? 0) + c * 0.08;
    out['folate'] = (out['folate'] ?? 0) + c * 0.15;
    out['vitC'] = (out['vitC'] ?? 0) + c * 0.05;
  }
  if (f >= 5) {
    out['vitE'] = (out['vitE'] ?? 0) + f * 0.06;
    out['vitA'] = (out['vitA'] ?? 0) + f * 0.4;
  }

  // Scale down if estimate exceeds plausible per-meal caps.
  for (final k in kTrackedMicroKeys) {
    final cap = (dailyRecommended[k] ?? 100) * calRatio * 1.5;
    out[k] = (out[k] ?? 0).clamp(0, cap).toDouble();
  }
  return out;
}

Map<String, double> _fillMissingMicroKeys(
  Map<String, double> scaled,
  FoodItem food,
  double grams,
) {
  final out = Map<String, double>.from(scaled);
  final missing = kTrackedMicroKeys.where((k) => (out[k] ?? 0) <= 0).toList();
  if (missing.isEmpty) return out;

  final estimate = estimateMicrosFromFoodProfile(food, grams);
  for (final k in missing) {
    final v = estimate[k] ?? 0;
    if (v > 0) out[k] = v * 0.45; // conservative fill for sparse DB rows
  }
  return out;
}

/// Upper-limit nutrients — progress shows inverse (lower is better).
const Set<String> kMicroUpperLimitKeys = {'sodium'};

/// Nutrient progress: 0–1 for targets; sodium uses inverse when over limit.
double microProgressPct(String key, double current, double goal) {
  if (goal <= 0) return 0;
  if (kMicroUpperLimitKeys.contains(key)) {
    if (current <= goal) return 1.0;
    return (goal / current).clamp(0.0, 1.0);
  }
  return (current / goal).clamp(0.0, 1.5);
}

String microProgressLabel(String key, double current, double goal) {
  if (goal <= 0) return '0%';
  if (kMicroUpperLimitKeys.contains(key)) {
    if (current <= goal) return 'OK';
    return '${((current / goal) * 100).toStringAsFixed(0)}% of limit';
  }
  final pct = (current / goal) * 100;
  if (pct > 100) return '${pct.toStringAsFixed(0)}%';
  return '${pct.toStringAsFixed(0)}%';
}
