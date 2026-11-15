class LogEntry {
  final bool catalogCalculation, withBones;
  final List<Map<String, dynamic>> catalogComponents;
  final String id;
  final String foodId;
  final String name;
  final double amount;
  final String amountUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int timestamp;
  final String? mealId;
  final Map<String, double> micros;

  LogEntry({
    required this.id,
    this.catalogCalculation = false,
    this.catalogComponents = const [],
    this.withBones = false,
    required this.foodId,
    required this.name,
    required num amount,
    this.amountUnit = 'g',
    required num calories,
    required num protein,
    required num carbs,
    required num fat,
    required this.timestamp,
    this.mealId,
    this.micros = const {},
  }) : amount = amount.toDouble(),
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
      catalogCalculation: map['catalogCalculation'] == true,
      catalogComponents: (map['catalogComponents'] as List? ?? [])
          .whereType<Map>()
          .map((component) => Map<String, dynamic>.from(component))
          .toList(),
      withBones: map['withBones'] == true,
      foodId:
          map['foodId']?.toString() ??
          map['external_food_id']?.toString() ??
          map['food_id']?.toString() ??
          '',
      name: map['name']?.toString() ?? map['food_name']?.toString() ?? '',
      amount:
          (map['amount'] as num?)?.toDouble() ??
          (map['amount_g'] as num?)?.toDouble() ??
          0.0,
      amountUnit: map['amount_unit'] == 'ml' || map['amountUnit'] == 'ml'
          ? 'ml'
          : 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      mealId:
          map['mealId']?.toString() ??
          map['meal_type']?.toString() ??
          map['meal_slot']?.toString(),
      micros: rawMicros.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    if (catalogCalculation) 'catalogCalculation': true,
    if (catalogComponents.isNotEmpty) 'catalogComponents': catalogComponents,
    if (withBones) 'withBones': true,
    'name': name,
    'amount': amount,
    'amountUnit': amountUnit,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'timestamp': timestamp,
    if (mealId != null) 'mealId': mealId,
    if (micros.isNotEmpty) 'micros': micros,
  };
}
