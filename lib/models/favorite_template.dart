import 'dart:convert';

/// Saved food or meal template for quick re-logging.
class FavoriteTemplate {
  final String id;
  final String name;
  final String? foodId;
  final double amount;
  final String amountUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final Map<String, double> micros;

  FavoriteTemplate({
    required this.id,
    required this.name,
    this.foodId,
    required this.amount,
    this.amountUnit = 'g',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.micros = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (foodId != null) 'foodId': foodId,
    'amount': amount,
    'amountUnit': amountUnit,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    if (micros.isNotEmpty) 'micros': micros,
  };

  factory FavoriteTemplate.fromMap(Map<String, dynamic> map) {
    final rawM = map['micros'];
    final micros = <String, double>{};
    if (rawM is Map) {
      for (final e in rawM.entries) {
        final v = e.value;
        if (v is num) micros[e.key.toString()] = v.toDouble();
      }
    }
    return FavoriteTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      foodId: map['foodId']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 100,
      amountUnit: map['amountUnit'] == 'ml' ? 'ml' : 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      micros: micros,
    );
  }

  String toJsonString() => jsonEncode(toMap());

  static FavoriteTemplate? tryParse(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return FavoriteTemplate.fromMap(m);
    } catch (_) {
      return null;
    }
  }
}
