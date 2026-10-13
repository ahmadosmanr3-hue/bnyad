import 'package:nutrify/models/food_item.dart';

/// Product nutrition resolved from a barcode (Open Food Facts or local DB).
class BarcodeFoodLookup {
  final String barcode;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? servingSizeLabel;
  /// Parsed package serving weight (g) when known — used as default portion.
  final double? defaultGrams;
  final bool fromLocalDatabase;
  final String? localFoodId;
  /// Where the data came from (for debugging / UI hints).
  final String? source;

  const BarcodeFoodLookup({
    required this.barcode,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.servingSizeLabel,
    this.defaultGrams,
    this.fromLocalDatabase = false,
    this.localFoodId,
    this.source,
  });

  factory BarcodeFoodLookup.fromFoodItem({
    required String barcode,
    required FoodItem food,
    String? source,
  }) {
    return BarcodeFoodLookup(
      barcode: barcode,
      name: food.name,
      caloriesPer100g: food.calories,
      proteinPer100g: food.protein,
      carbsPer100g: food.carbs,
      fatPer100g: food.fat,
      servingSizeLabel: food.servingLabelEn ?? '100g',
      fromLocalDatabase: true,
      localFoodId: food.id,
      source: source ?? 'local_db',
    );
  }

  factory BarcodeFoodLookup.fromJson(Map<String, dynamic> json) {
    return BarcodeFoodLookup(
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? 'Product',
      brand: json['brand'] as String?,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
      servingSizeLabel: json['servingSizeLabel'] as String?,
      defaultGrams: (json['defaultGrams'] as num?)?.toDouble(),
      fromLocalDatabase: json['fromLocalDatabase'] as bool? ?? true,
      localFoodId: json['localFoodId'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        if (brand != null) 'brand': brand,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
        if (servingSizeLabel != null) 'servingSizeLabel': servingSizeLabel,
        if (defaultGrams != null) 'defaultGrams': defaultGrams,
        'fromLocalDatabase': fromLocalDatabase,
        if (localFoodId != null) 'localFoodId': localFoodId,
        if (source != null) 'source': source,
      };

  Map<String, double> macrosForGrams(double grams) {
    final r = grams / 100.0;
    return {
      'calories': caloriesPer100g * r,
      'protein': proteinPer100g * r,
      'carbs': carbsPer100g * r,
      'fat': fatPer100g * r,
    };
  }

  double get initialGrams {
    final d = defaultGrams;
    if (d != null && d >= 5 && d <= 2000) return d;
    return 100;
  }
}
