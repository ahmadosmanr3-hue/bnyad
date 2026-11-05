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

  /// Existing numeric field names are retained for cache compatibility. Their
  /// reference is 100 [basisUnit], never an assumed grams/mL conversion.
  final String basisUnit;
  final double? servingAmount;
  final String? attribution;
  final String? sourceUrl;
  final bool labelBasisConfirmed;

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
    this.basisUnit = 'g',
    this.servingAmount,
    this.attribution,
    this.sourceUrl,
    this.labelBasisConfirmed = false,
  });

  factory BarcodeFoodLookup.fromFoodItem({
    required String barcode,
    required FoodItem food,
    String? source,
  }) {
    return BarcodeFoodLookup(
      barcode: barcode,
      name: food.name,
      caloriesPer100g: food.calories * 100 / food.nutritionReferenceG,
      proteinPer100g: food.protein * 100 / food.nutritionReferenceG,
      carbsPer100g: food.carbs * 100 / food.nutritionReferenceG,
      fatPer100g: food.fat * 100 / food.nutritionReferenceG,
      servingAmount: food.nutritionReferenceG,
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
      basisUnit: json['basisUnit'] == 'ml' ? 'ml' : 'g',
      servingAmount: (json['servingAmount'] as num?)?.toDouble(),
      attribution: json['attribution'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      labelBasisConfirmed: json['labelBasisConfirmed'] == true,
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
    'basisUnit': basisUnit,
    if (servingAmount != null) 'servingAmount': servingAmount,
    if (attribution != null) 'attribution': attribution,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
    'labelBasisConfirmed': labelBasisConfirmed,
  };

  Map<String, double> macrosForGrams(double grams) {
    return macrosForAmount(grams, unit: 'g');
  }

  Map<String, double> macrosForAmount(double amount, {String? unit}) {
    final supplied = unit ?? basisUnit;
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Invalid quantity');
    }
    final normalizedUnit = supplied == 'L' ? 'ml' : supplied;
    if (normalizedUnit != basisUnit) {
      throw ArgumentError(
        'A verified density is required to convert weight and volume',
      );
    }
    final r = amount * (supplied == 'L' ? 1000 : 1) / 100.0;
    return {
      'calories': caloriesPer100g * r,
      'protein': proteinPer100g * r,
      'carbs': carbsPer100g * r,
      'fat': fatPer100g * r,
    };
  }

  double get initialGrams {
    if (basisUnit != 'g') {
      throw StateError('This product uses volume, not grams');
    }
    final d = defaultGrams;
    if (d != null && d >= 5 && d <= 2000) return d;
    return 100;
  }

  double get initialAmount {
    final value = servingAmount ?? (basisUnit == 'g' ? defaultGrams : null);
    return value != null && value.isFinite && value > 0 && value <= 10000
        ? value
        : 100;
  }

  bool get isValid =>
      name.trim().isNotEmpty &&
      ['g', 'ml'].contains(basisUnit) &&
      [
        caloriesPer100g,
        proteinPer100g,
        carbsPer100g,
        fatPer100g,
      ].every((v) => v.isFinite && v >= 0) &&
      caloriesPer100g <= (basisUnit == 'ml' ? 1800 : 1200) &&
      [
        proteinPer100g,
        carbsPer100g,
        fatPer100g,
      ].every((v) => v <= (basisUnit == 'ml' ? 200 : 100)) &&
      proteinPer100g + carbsPer100g + fatPer100g <=
          (basisUnit == 'ml' ? 210 : 105) &&
      caloriesPer100g + 20 >= proteinPer100g * 4 + fatPer100g * 8;

  BarcodeFoodLookup corrected({
    required String name,
    required String unit,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) => BarcodeFoodLookup(
    barcode: barcode,
    name: name,
    brand: brand,
    basisUnit: unit,
    caloriesPer100g: calories,
    proteinPer100g: protein,
    carbsPer100g: carbs,
    fatPer100g: fat,
    source: 'manual',
    attribution: attribution,
    sourceUrl: sourceUrl,
    labelBasisConfirmed: true,
  );

  factory BarcodeFoodLookup.fromBackend(Map<String, dynamic> data) {
    final n = Map<String, dynamic>.from(data['nutrients'] as Map);
    return BarcodeFoodLookup(
      barcode: data['code'] as String,
      name: data['name'] as String,
      brand: data['brand'] as String?,
      caloriesPer100g: (n['calories'] as num).toDouble(),
      proteinPer100g: (n['protein'] as num).toDouble(),
      carbsPer100g: (n['carbs'] as num).toDouble(),
      fatPer100g: (n['fat'] as num).toDouble(),
      basisUnit: data['basisUnit'] as String,
      servingAmount: (data['servingAmount'] as num?)?.toDouble(),
      servingSizeLabel: data['servingLabel'] as String?,
      source: data['source'] as String?,
      attribution: data['attribution'] as String?,
      sourceUrl: data['url'] as String?,
      labelBasisConfirmed: data['labelBasisConfirmed'] == true,
    );
  }
}
