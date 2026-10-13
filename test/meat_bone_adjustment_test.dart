import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/utils/meat_bone_adjustment.dart';

void main() {
  const thigh = FoodItem(
    id: 'p11',
    name: 'Chicken Thigh',
    calories: 210,
    protein: 26,
    carbs: 0,
    fat: 11,
    category: 'Protein',
  );

  const ground = FoodItem(
    id: 'p4',
    name: 'Ground Beef',
    calories: 250,
    protein: 17,
    carbs: 0,
    fat: 20,
    category: 'Protein',
  );

  test('bone choice available for chicken thigh not ground beef', () {
    expect(meatSupportsBoneChoice(thigh), isTrue);
    expect(meatSupportsBoneChoice(ground), isFalse);
  });

  test('bone-in lowers macro multiplier for thigh', () {
    expect(meatLogMacroMultiplier(thigh, withBones: false), 1.0);
    expect(meatLogMacroMultiplier(thigh, withBones: true), closeTo(0.68, 0.001));
  });

  test('wings have lower edible yield than breast', () {
    expect(meatBoneInMacroFactor('p13'), lessThan(meatBoneInMacroFactor('p1')));
  });
}
