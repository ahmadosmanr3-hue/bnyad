class NutritionalGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  NutritionalGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionalGoals.fromMap(Map<String, dynamic> map) {
    return NutritionalGoals(
      calories: (map['calories'] as num?)?.toInt() ?? 2200,
      protein: (map['protein'] as num?)?.toInt() ?? 120,
      carbs: (map['carbs'] as num?)?.toInt() ?? 250,
      fat: (map['fat'] as num?)?.toInt() ?? 70,
    );
  }

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}
