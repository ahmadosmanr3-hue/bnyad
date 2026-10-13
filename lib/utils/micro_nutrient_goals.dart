import 'dart:math' as math;

import 'package:nutrify/constants/food_database.dart';

bool _isFemaleGender(String gender) {
  final g = gender.toLowerCase();
  return g == 'female' || g == 'f' || g == 'woman';
}

/// IOM / NIH DRI-based personalized daily micronutrient targets.
/// Covers age, sex, pregnancy, lactation, anemia, kidney, and activity.
Map<String, double> computeMicroGoals({
  required int age,
  required String gender,
  String pregnancyStatus = 'none',
  List<String> sicknesses = const [],
  String activityLevel = 'moderatelyActive',
  double weightKg = 70,
}) {
  final female = _isFemaleGender(gender);
  final pregnant = pregnancyStatus == 'pregnant';
  final breastfeeding = pregnancyStatus == 'breastfeeding';
  final anemia = sicknesses.contains('anemia');
  final kidney = sicknesses.contains('kidney');
  final ageClamped = age.clamp(14, 100);

  final goals = Map<String, double>.from(dailyRecommended);

  // ─── Sex-specific DRIs (adults 19+) ─────────────────
  if (female) {
    goals['iron'] = ageClamped >= 51 ? 8 : 18;
    goals['magnesium'] = 320;
    goals['fiber'] = 25;
    goals['vitB6'] = ageClamped >= 51 ? 1.5 : 1.3;
    goals['vitK'] = 90;
    goals['zinc'] = 8;
    goals['potassium'] = 2600;
  } else {
    goals['iron'] = 8;
    goals['magnesium'] = 420;
    goals['fiber'] = 38;
    goals['vitB6'] = ageClamped >= 51 ? 1.7 : 1.7;
    goals['vitK'] = 120;
    goals['zinc'] = 11;
    goals['potassium'] = 3400;
  }

  // ─── Age brackets ───────────────────────────────────
  if (ageClamped >= 71) {
    goals['vitD'] = 20;
    goals['calcium'] = female ? 1200 : 1200;
  } else if (ageClamped >= 51) {
    goals['vitD'] = 15;
    goals['calcium'] = female ? 1200 : 1000;
  } else if (ageClamped >= 19) {
    goals['vitD'] = 15;
    goals['calcium'] = 1000;
  } else {
    // Teens 14–18
    goals['vitD'] = 15;
    goals['calcium'] = 1300;
    goals['iron'] = female ? 15 : 11;
    goals['folate'] = 400;
  }

  // ─── Pregnancy / lactation ──────────────────────────
  if (pregnant) {
    goals['folate'] = 600;
    goals['iron'] = 27;
    goals['vitA'] = 770;
    goals['vitC'] = 85;
    goals['vitD'] = 15;
    goals['zinc'] = 11;
    goals['calcium'] = 1000;
    goals['vitB6'] = 1.9;
    goals['vitB12'] = 2.6;
    goals['fiber'] = 28;
  } else if (breastfeeding) {
    goals['folate'] = 500;
    goals['vitA'] = 1300;
    goals['vitC'] = 120;
    goals['vitD'] = 15;
    goals['iron'] = anemia ? 18 : 9;
    goals['vitB6'] = 2.0;
    goals['vitB12'] = 2.8;
    goals['zinc'] = 12;
    goals['calcium'] = 1000;
    goals['fiber'] = 29;
  }

  // ─── Anemia ───────────────────────────────────────────
  if (anemia && !pregnant) {
    goals['iron'] = female ? 18 : 11;
    goals['vitC'] = (goals['vitC'] ?? 90) + 15;
    goals['vitB12'] = 2.8;
    goals['folate'] = 600;
  }

  // ─── Kidney disease — lower electrolytes ──────────────
  if (kidney) {
    goals['potassium'] = 2000;
    goals['phosphorus'] = 800;
    goals['sodium'] = 2000;
  }

  // ─── Activity-based adjustments ───────────────────────
  final activity = activityLevel.toLowerCase();
  if (activity.contains('very') || activity.contains('extra')) {
    goals['magnesium'] = (goals['magnesium'] ?? 400) * 1.12;
    goals['potassium'] = (goals['potassium'] ?? 3000) * 1.08;
    goals['vitB6'] = (goals['vitB6'] ?? 1.7) * 1.1;
    goals['vitC'] = (goals['vitC'] ?? 90) * 1.05;
    goals['zinc'] = (goals['zinc'] ?? 11) * 1.08;
  } else if (activity.contains('moderate')) {
    goals['magnesium'] = (goals['magnesium'] ?? 400) * 1.05;
    goals['potassium'] = (goals['potassium'] ?? 3000) * 1.03;
  }

  // ─── Weight-scaled minerals (reference 70 kg) ───────
  if (weightKg > 0) {
    final wFactor = (weightKg / 70.0).clamp(0.75, 1.35);
    goals['calcium'] = (goals['calcium'] ?? 1000) * wFactor;
    goals['magnesium'] = (goals['magnesium'] ?? 400) * wFactor;
    goals['phosphorus'] = (goals['phosphorus'] ?? 700) * wFactor;
    goals['zinc'] = (goals['zinc'] ?? 11) * math.sqrt(wFactor);
  }

  // Round to sensible precision
  for (final k in kTrackedMicroKeys) {
    final v = goals[k];
    if (v == null) continue;
    goals[k] = k == 'fiber' || k.startsWith('vitB')
        ? double.parse(v.toStringAsFixed(1))
        : v.roundToDouble();
  }

  return goals;
}
