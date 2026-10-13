class LogEntry {
  final String id;
  final String foodId;
  final String name;
  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int timestamp;
  final String? mealId;
  final Map<String, double> micros;

  LogEntry({
    required this.id,
    required this.foodId,
    required this.name,
    required num amount,
    required num calories,
    required num protein,
    required num carbs,
    required num fat,
    required this.timestamp,
    this.mealId,
    this.micros = const {},
  })  : amount = amount.toDouble(),
        calories = calories.toDouble(),
        protein = protein.toDouble(),
        carbs = carbs.toDouble(),
        fat = fat.toDouble();

  factory LogEntry.fromMap(String id, Map<String, dynamic> map) {
    final rawMicros = map['micros'] as Map<String, dynamic>? ?? {};

    int ts = 0;
    final rawTs = map['timestamp'] ?? map['consumed_at'];
    if (rawTs is int) {
      ts = rawTs;
    } else if (rawTs is num) {
      ts = rawTs.toInt();
    } else if (rawTs is String) {
      final parsed = DateTime.tryParse(rawTs);
      if (parsed != null) ts = parsed.millisecondsSinceEpoch;
    }

    return LogEntry(
      id: id,
      foodId: map['foodId']?.toString() ??
          map['external_food_id']?.toString() ??
          map['food_id']?.toString() ??
          '',
      name: map['name']?.toString() ?? map['food_name']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ??
          (map['amount_g'] as num?)?.toDouble() ??
          0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      mealId: map['mealId']?.toString() ??
          map['meal_type']?.toString() ??
          map['meal_slot']?.toString(),
      micros: rawMicros.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'name': name,
        'amount': amount,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'timestamp': timestamp,
        if (mealId != null) 'mealId': mealId,
        if (micros.isNotEmpty) 'micros': micros,
      };
}
