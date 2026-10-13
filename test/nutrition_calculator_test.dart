import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';

void main() {
  test('BMI matches standard kg/cm formula', () {
    expect(
      computeBmi(weightKg: 80, heightCm: 178),
      closeTo(25.25, 0.01),
    );
    expect(
      computeBmi(weightKg: 70, heightCm: 175),
      closeTo(22.86, 0.01),
    );
  });

  test('BMR matches Mifflin-St Jeor reference (male)', () {
    expect(
      computeBmr(weightKg: 80, heightCm: 178, age: 30, gender: 'male'),
      closeTo(1767.5, 0.5),
    );
  });

  test('maintenance TDEE uses BMR and activity multiplier only', () {
    final tdee = computeMaintenanceTdee(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
    );
    expect(tdee, closeTo(1767.5 * 1.55, 1.0));
  });

  test('macro grams reconcile to calorie target', () {
    final goals = computeNutritionalGoals(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'stayHealthy',
    );
    final macroCal =
        goals.protein * 4 + goals.carbs * 4 + goals.fat * 9;
    expect(macroCal, inInclusiveRange(goals.calories - 15, goals.calories + 15));
  });

  test('stay healthy protein is 1.6 g per kg', () {
    final goals = computeNutritionalGoals(
      weightKg: 70,
      heightCm: 175,
      age: 25,
      gender: 'male',
      activityLevel: 'lightlyActive',
      goal: 'stayHealthy',
    );
    expect(goals.calories, inInclusiveRange(1800, 2600));
    expect(goals.protein, (70 * 1.6).round());
  });

  test('build muscle protein is 2.0 g per kg', () {
    final goals = computeNutritionalGoals(
      weightKg: 90,
      heightCm: 185,
      age: 22,
      gender: 'male',
      activityLevel: 'veryActive',
      goal: 'gainMuscle',
    );
    expect(goals.protein, (90 * 2.0).round());
    expect(
      goals.protein * 4 + goals.carbs * 4 + goals.fat * 9,
      inInclusiveRange(goals.calories - 15, goals.calories + 15),
    );
  });

  test('lose weight subtracts 500 kcal for normal BMI (calculator.net)', () {
    // BMI ≈ 25.2 — standard −500 (~1 lb / week)
    final maintain = computeDailyCalories(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'stayHealthy',
    );
    final cut = computeDailyCalories(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'loseWeight',
    );
    expect(cut, maintain - 500);
  });

  test('lose weight uses larger deficit when BMI is high', () {
    // 100 kg, 175 cm → BMI ≈ 32.7 → −750 (gap under 15 kg)
    final maintain = computeDailyCalories(
      weightKg: 100,
      heightCm: 175,
      age: 30,
      gender: 'male',
      activityLevel: 'lightlyActive',
      goal: 'stayHealthy',
    );
    final cut = computeDailyCalories(
      weightKg: 100,
      heightCm: 175,
      age: 30,
      gender: 'male',
      activityLevel: 'lightlyActive',
      goal: 'loseWeight',
      targetWeightKg: 90,
    );
    expect(cut, maintain - 750);
  });

  test('gainMuscle adds 250 kcal mild surplus over maintenance', () {
    final maintain = computeDailyCalories(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'stayHealthy',
    );
    final muscle = computeDailyCalories(
      weightKg: 80,
      heightCm: 178,
      age: 30,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'gainMuscle',
    );
    expect(muscle, maintain + 250);
  });

  test('gain weight adds 500 kcal over maintenance', () {
    final maintain = computeDailyCalories(
      weightKg: 70,
      heightCm: 175,
      age: 25,
      gender: 'male',
      activityLevel: 'lightlyActive',
      goal: 'stayHealthy',
    );
    final gain = computeDailyCalories(
      weightKg: 70,
      heightCm: 175,
      age: 25,
      gender: 'male',
      activityLevel: 'lightlyActive',
      goal: 'gainWeight',
    );
    expect(gain, maintain + 500);
  });

  test('onboarding lose-weight profile matches calculator.net style', () {
    final goals = computeNutritionalGoalsFromProfile({
      'weight': 90,
      'height': 180,
      'age': 25,
      'gender': 'male',
      'activity': 'sedentary',
      'goal': 'loseWeight',
      'targetWeight': 80,
      'workoutDaysPerWeek': 0,
      'workoutType': 'workoutNone',
    });
    // BMI ≈ 27.8, gap 10 kg → −750
    final maintenance = computeMaintenanceTdee(
      weightKg: 90,
      heightCm: 180,
      age: 25,
      gender: 'male',
      activityLevel: 'sedentary',
    ).round();
    expect(goals.calories, maintenance - 750);
    expect(goals.protein, (90 * 1.8).round());
  });
}
