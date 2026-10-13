import 'package:nutrify/models/nutritional_goals.dart';

/// Nutrition math aligned with [calculator.net](https://www.calculator.net/calorie-calculator.html):
/// Mifflin–St Jeor BMR × activity → TDEE, then ±500 kcal (~1 lb / 0.45 kg per week)
/// or ±1000 kcal (~2 lb / 0.9 kg per week). Protein stays 1.6–2.0 g/kg by goal.

/// Standard BMI (kg / m²) — same WHO formula as calculator.net BMI page.
double computeBmi({required double weightKg, required double heightCm}) {
  if (weightKg <= 0 || heightCm <= 0) return 0;
  final heightM = heightCm / 100.0;
  return weightKg / (heightM * heightM);
}

/// Mifflin–St Jeor BMR (1990) — default formula on calculator.net.
double computeBmr({
  required double weightKg,
  required double heightCm,
  required int age,
  required String gender,
}) {
  final isFemale = _isFemaleGender(gender);
  if (isFemale) {
    return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  }
  return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
}

/// Activity multipliers matching calculator.net calorie calculator.
double activityMultiplier(String activityLevel) {
  const multipliers = {
    'sedentary': 1.2, // little or no exercise
    'lightlyActive': 1.375, // exercise 1–3×/week
    'moderatelyActive': 1.55, // exercise 4–5×/week
    'veryActive': 1.725, // daily or intense 3–4×/week
    'extraActive': 1.9, // intense daily / physical job
  };
  return multipliers[activityLevel] ?? 1.2;
}

/// Maps onboarding goal keys to internal nutrition goal keys.
String normalizeNutritionGoal(String goal) {
  switch (goal) {
    case 'gainMuscle':
      return 'buildMuscle';
    case 'athletic':
      return 'buildMuscle';
    case 'manageCondition':
      return 'stayHealthy';
    default:
      return goal;
  }
}

/// Maintenance TDEE (BMR × activity) — calories to keep current weight.
double computeMaintenanceTdee({
  required double weightKg,
  required double heightCm,
  required int age,
  required String gender,
  required String activityLevel,
}) {
  return computeBmr(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    gender: gender,
  ) *
      activityMultiplier(activityLevel);
}

/// Goal adjustment vs maintenance (calculator.net: ±500 ≈ 1 lb/week, ±1000 ≈ 2 lb/week).
///
/// Lose weight uses a larger cut when BMI is high or the target weight gap is large,
/// so heavy users are not left on near-maintenance calories.
double goalCalorieDelta({
  required String goal,
  required double weightKg,
  required double heightCm,
  double? targetWeightKg,
}) {
  final normalized = normalizeNutritionGoal(goal);
  final bmi = computeBmi(weightKg: weightKg, heightCm: heightCm);
  final gapKg = weightKg - (targetWeightKg ?? weightKg);

  switch (normalized) {
    case 'loseWeight':
    case 'loseFat':
      // Standard: −500 (~0.45 kg/week). Extreme: −1000 (~0.9 kg/week).
      if (bmi >= 35 || gapKg >= 15) return -1000;
      if (bmi >= 30 || gapKg >= 8) return -750;
      return -500;
    case 'gainWeight':
      // +500 ≈ +0.45 kg/week (calculator.net gain rate).
      if (targetWeightKg != null && targetWeightKg - weightKg >= 10) {
        return 750;
      }
      return 500;
    case 'buildMuscle':
      // Mild surplus for leaner gain (~0.25 kg/week).
      return 250;
    case 'stayHealthy':
    default:
      return 0;
  }
}

/// Daily calorie target — calculator.net style (TDEE ± goal delta).
int computeDailyCalories({
  required double weightKg,
  required double heightCm,
  required int age,
  required String gender,
  required String activityLevel,
  required String goal,
  double? targetWeightKg,
  int workoutDaysPerWeek = 0,
}) {
  final tdee = computeMaintenanceTdee(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    gender: gender,
    activityLevel: activityLevel,
  );

  var target = tdee +
      goalCalorieDelta(
        goal: goal,
        weightKg: weightKg,
        heightCm: heightCm,
        targetWeightKg: targetWeightKg,
      );

  // calculator.net: do not cut more than ~1000 kcal/day below maintenance.
  final normalized = normalizeNutritionGoal(goal);
  if (normalized == 'loseWeight' || normalized == 'loseFat') {
    if (tdee - target > 1000) target = tdee - 1000;
  }

  // Safe floors (calculator.net / common guidance).
  final lowerBound = _isFemaleGender(gender) ? 1200 : 1500;
  return target.round().clamp(lowerBound, 4000);
}

/// Protein target: 1.6–2.0 g per kg body weight (by goal).
double proteinGramsPerKg(String goal) {
  switch (normalizeNutritionGoal(goal)) {
    case 'buildMuscle':
      return 2.0;
    case 'loseFat':
    case 'loseWeight':
      return 1.8;
    case 'gainWeight':
    case 'stayHealthy':
    default:
      return 1.6;
  }
}

/// Macro split in grams — protein from g/kg; carbs/fat fill remaining calories.
NutritionalGoals computeMacroGoals({
  required int calories,
  required String goal,
  required double weightKg,
  int proteinBonusG = 0,
}) {
  final normalizedGoal = normalizeNutritionGoal(goal);

  double carbsPct;
  double fatPct;
  switch (normalizedGoal) {
    case 'buildMuscle':
      carbsPct = 0.42;
      fatPct = 0.33;
      break;
    case 'loseFat':
    case 'loseWeight':
      carbsPct = 0.43;
      fatPct = 0.35;
      break;
    case 'gainWeight':
      carbsPct = 0.50;
      fatPct = 0.30;
      break;
    default:
      carbsPct = 0.52;
      fatPct = 0.30;
  }

  var protein = (weightKg * proteinGramsPerKg(goal)).round();
  if (protein * 4 > calories) protein = (calories / 4).floor();

  var proteinCal = protein * 4;
  final remainingCal = calories - proteinCal;
  final nonProteinShare = carbsPct + fatPct;
  final carbShareOfRemainder =
      nonProteinShare > 0 ? carbsPct / nonProteinShare : 0.5;

  var carbs = remainingCal > 0
      ? ((remainingCal * carbShareOfRemainder) / 4).round()
      : 0;
  var fat = remainingCal > 0
      ? ((remainingCal - carbs * 4) / 9).round()
      : 0;

  if (fat < 0) {
    fat = 0;
    carbs = remainingCal > 0 ? (remainingCal / 4).round() : 0;
  }

  // Reconcile rounding so macro calories match the calorie target.
  var totalMacroCal = protein * 4 + carbs * 4 + fat * 9;
  var diff = calories - totalMacroCal;
  if (diff != 0) {
    final carbAdjust = diff ~/ 4;
    carbs = (carbs + carbAdjust).clamp(0, 999);
    totalMacroCal = protein * 4 + carbs * 4 + fat * 9;
    diff = calories - totalMacroCal;
    if (diff != 0) {
      fat = (fat + diff ~/ 9).clamp(0, 999);
      totalMacroCal = protein * 4 + carbs * 4 + fat * 9;
      diff = calories - totalMacroCal;
      if (diff != 0) {
        carbs = (carbs + diff ~/ 4).clamp(0, 999);
      }
    }
  }

  return NutritionalGoals(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}

/// Calories from macro grams (protein/carbs = 4 kcal/g, fat = 9 kcal/g).
int caloriesFromMacros(int protein, int carbs, int fat) =>
    protein * 4 + carbs * 4 + fat * 9;

/// Which macro field the user last edited in Settings.
enum MacroEditField { calories, protein, carbs, fat }

/// Reconcile manual macro edits so calories and grams stay consistent.
NutritionalGoals rebalanceMacroEdit({
  required NutritionalGoals current,
  required MacroEditField changed,
  int? calories,
  int? protein,
  int? carbs,
  int? fat,
}) {
  var p = (protein ?? current.protein).clamp(0, 1000);
  var c = (carbs ?? current.carbs).clamp(0, 2000);
  var f = (fat ?? current.fat).clamp(0, 1000);

  if (changed == MacroEditField.calories && calories != null) {
    final target = calories.clamp(500, 10000);
    return _scaleMacrosToCalories(
      NutritionalGoals(calories: current.calories, protein: p, carbs: c, fat: f),
      target,
    );
  }

  final macroCal = caloriesFromMacros(p, c, f).clamp(500, 10000);
  return NutritionalGoals(calories: macroCal, protein: p, carbs: c, fat: f);
}

NutritionalGoals _scaleMacrosToCalories(NutritionalGoals current, int targetCalories) {
  final currentTotal = caloriesFromMacros(current.protein, current.carbs, current.fat);
  if (currentTotal <= 0) {
    return NutritionalGoals(calories: targetCalories, protein: 0, carbs: 0, fat: 0);
  }

  final ratio = targetCalories / currentTotal;
  var p = (current.protein * ratio).round().clamp(0, 1000);
  var c = (current.carbs * ratio).round().clamp(0, 2000);
  var f = (current.fat * ratio).round().clamp(0, 1000);

  var cal = caloriesFromMacros(p, c, f);
  var diff = targetCalories - cal;
  if (diff != 0) {
    c = (c + diff ~/ 4).clamp(0, 2000);
    cal = caloriesFromMacros(p, c, f);
    diff = targetCalories - cal;
    if (diff != 0) {
      f = (f + diff ~/ 9).clamp(0, 1000);
    }
  }

  cal = caloriesFromMacros(p, c, f);
  return NutritionalGoals(
    calories: cal.clamp(500, 10000),
    protein: p,
    carbs: c,
    fat: f,
  );
}

NutritionalGoals computeNutritionalGoals({
  required double weightKg,
  required double heightCm,
  required int age,
  required String gender,
  required String activityLevel,
  required String goal,
  double? targetWeightKg,
  int workoutDaysPerWeek = 0,
  String workoutType = 'workoutNone',
  int proteinBonusG = 0,
}) {
  final calories = computeDailyCalories(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    gender: gender,
    activityLevel: activityLevel,
    goal: goal,
    targetWeightKg: targetWeightKg,
  );

  return computeMacroGoals(
    calories: calories,
    goal: goal,
    weightKg: weightKg,
  );
}

/// Onboarding / profile map → daily macro targets.
NutritionalGoals computeNutritionalGoalsFromProfile(
  Map<String, dynamic> profile,
) {
  return computeNutritionalGoals(
    weightKg: (profile['weight'] as num).toDouble(),
    heightCm: (profile['height'] as num).toDouble(),
    age: profile['age'] as int,
    gender: profile['gender'] as String,
    activityLevel: profile['activity'] as String,
    goal: profile['goal'] as String,
    targetWeightKg: (profile['targetWeight'] as num?)?.toDouble(),
    workoutDaysPerWeek:
        (profile['workoutDaysPerWeek'] as num?)?.toInt() ?? 0,
    workoutType: profile['workoutType'] as String? ?? 'workoutNone',
  );
}

bool _isFemaleGender(String gender) {
  final g = gender.toLowerCase();
  return g == 'female' || g == 'f' || g == 'woman';
}
