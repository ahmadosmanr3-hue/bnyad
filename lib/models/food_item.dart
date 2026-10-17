import 'dart:convert';

import 'package:nutrify/utils/food_search_match.dart';

/// Logging UI: gram slider vs counting pieces or bowls (never both on one food).
enum FoodAmountKind {
  /// User adjusts weight in grams; macros scale vs [FoodItem.nutritionReferenceG].
  grams,
  /// User adjusts count; each unit = [nutritionReferenceG] grams for macro scaling.
  discreteUnits,
}

/// When [FoodAmountKind] is [discreteUnits], whether each unit is a piece or a bowl.
enum FoodDiscreteUnit {
  piece,
  bowl,
}

class FoodItem {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameKu;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  /// Micronutrients per 100g: vitA(mcg), vitC(mg), vitD(mcg), vitB12(mcg), iron(mg), calcium(mg), potassium(mg), zinc(mg)
  final Map<String, double> micros;

  /// Grams that [calories], [protein], [carbs], [fat] refer to (default 100 = per 100g).
  /// For a "one bowl" row with totals for a 350g bowl, set this to 350 and keep macros as given for that bowl.
  final double nutritionReferenceG;

  /// Optional labels (e.g. "100g" vs "1 bowl") for UI; search uses [name] / [nameKu] / [nameAr].
  final String? servingLabelEn;
  final String? servingLabelKu;
  final String? servingLabelAr;

  /// [grams] = gram slider only; [discreteUnits] = piece/bowl counter only.
  final FoodAmountKind amountKind;

  /// Set when [amountKind] is [FoodAmountKind.discreteUnits].
  final FoodDiscreteUnit? discreteUnit;

  /// If non-null, this food can also be logged by **piece** in the food log
  /// sheet (e.g. 1 dolma ≈ 50g). The serving switch synthesizes a piece
  /// variant with linearly-scaled macros from the canonical (per-100g) row.
  final double? gramsPerPiece;

  /// If non-null, this food can be logged by **bowl/cup** (e.g. 1 bowl of
  /// rice ≈ 160g). Same synthesis logic as [gramsPerPiece].
  final double? gramsPerBowl;

  const FoodItem({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameKu,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    this.micros = const {},
    this.nutritionReferenceG = 100,
    this.servingLabelEn,
    this.servingLabelKu,
    this.servingLabelAr,
    this.amountKind = FoodAmountKind.grams,
    this.discreteUnit,
    this.gramsPerPiece,
    this.gramsPerBowl,
  });

  bool get usesGramsOnly => amountKind == FoodAmountKind.grams;

  bool get usesDiscreteUnitsOnly => amountKind == FoodAmountKind.discreteUnits;

  /// `amountG` grams → multiplier vs the reference serving.
  double macroRatio(double amountG) => amountG / nutritionReferenceG;

  /// Parses JSON objects that carry English + Kurdish (Sorani) [+ Arabic] labels.
  ///
  /// Supported shapes:
  /// - Flat: `name` / `nameEn` / `en`, `nameKu` / `ku`, `nameAr` / `ar`
  /// - Nested: `names: { "en": "...", "ku": "...", "ar": "..." }`
  /// - Macros: `calories`, `protein`, `carbs`, `fat` (num)
  /// - `micros`: map of string → num (per 100g)
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final names = json['names'];
    Map<String, dynamic>? nameMap;
    if (names is Map) {
      nameMap = Map<String, dynamic>.from(names);
    }

    String? pick(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final en = pick(json, ['name', 'nameEn', 'en', 'english', 'name_en']) ??
        (nameMap == null ? null : pick(nameMap, ['en', 'english', 'name'])) ??
        '';
    final ku = pick(json, ['nameKu', 'ku', 'name_ku', 'sorani']) ??
        (nameMap == null ? null : pick(nameMap, ['ku', 'ckb', 'sorani']));
    final ar = pick(json, ['nameAr', 'ar', 'name_ar', 'arabic']) ??
        (nameMap == null ? null : pick(nameMap, ['ar', 'arabic']));

    double numField(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    final microRaw = json['micros'] ?? json['micro'];
    final micros = _microsFromJson(microRaw);

    double refG = 100;
    final rawRef = json['nutritionReferenceG'] ?? json['reference_g'] ?? json['nutrition_reference_g'];
    if (rawRef is num) refG = rawRef.toDouble();

    final sEn = pick(json, ['serving_en', 'servingLabelEn']);
    final sKu = pick(json, ['serving_ku', 'servingLabelKu']);
    final sAr = pick(json, ['serving_ar', 'servingLabelAr']);

    final rawKind = json['amountKind'] ?? json['amount_kind'];
    FoodAmountKind kind = FoodAmountKind.grams;
    if (rawKind == 'discreteUnits' || rawKind == 'discrete' || rawKind == 'units') {
      kind = FoodAmountKind.discreteUnits;
    }
    FoodDiscreteUnit? du;
    final rawU = json['discreteUnit'] ?? json['unit'] ?? json['discrete_unit'];
    if (rawU == 'bowl' || rawU == 'bowls') {
      du = FoodDiscreteUnit.bowl;
    } else if (rawU == 'piece' || rawU == 'pieces') {
      du = FoodDiscreteUnit.piece;
    }
    if (kind == FoodAmountKind.discreteUnits) {
      du ??= FoodDiscreteUnit.piece;
    }

    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: en,
      nameAr: ar,
      nameKu: ku,
      calories: numField('calories', 'kcal'),
      protein: numField('protein', 'p'),
      carbs: numField('carbs', 'c'),
      fat: numField('fat', 'f'),
      category: json['category']?.toString() ?? 'General',
      micros: micros,
      nutritionReferenceG: refG,
      servingLabelEn: sEn,
      servingLabelKu: sKu,
      servingLabelAr: sAr,
      amountKind: kind,
      discreteUnit: kind == FoodAmountKind.discreteUnits ? du : null,
    );
  }

  /// True if [name], [nameAr], and [nameKu] are all non-empty (trilingual entry).
  bool get isTrilingual =>
      name.trim().isNotEmpty &&
      (nameAr != null && nameAr!.trim().isNotEmpty) &&
      (nameKu != null && nameKu!.trim().isNotEmpty);

  /// Extra tokens per [id] (e.g. naan ↔ bread in Kurdish / English).
  static const Map<String, List<String>> searchAliases = {
    'k5': ['naan', 'nan', 'flatbread', 'nan bread', 'نان'],
    'k2': ['biryani', 'kurdish rice', 'rice kurdish', 'بریانی', 'برنج کوردی'],
    'k2_no_oil': ['kurdish rice no oil', 'biryani no oil', 'rice without oil', 'بێ ڕۆن'],
    'k2_with_oil': ['kurdish rice with oil', 'biryani with oil', 'rice with oil', 'بە ڕۆن'],
    'k2_chicken': ['biryani chicken', 'rice chicken'],
    'k2_meat': ['biryani meat', 'rice meat'],
    'g2': ['white rice', 'rice white', 'برنج', 'برنجی سپی'],
    'g2_with_oil': ['white rice oil', 'rice with oil'],
    'g2_steamed': ['steamed rice', 'rice steamed', 'rice no oil'],
    'p1': ['chicken breast', 'grilled chicken', 'mrişk', 'سنگی مریشک'],
    'p1_fried': ['fried chicken', 'chicken fried'],
    'p1_boiled': ['boiled chicken', 'chicken boiled'],
    'p1_stew': ['stew chicken', 'chicken stew'],
    'p1_roasted': ['roasted chicken', 'chicken roasted'],
    'kuu_rice_kurdish_oil_100g': ['kurdish rice oil', 'rice kurdish oil'],
    'kuu_rice_kurdish_no_oil_100g': ['kurdish rice no oil', 'rice without oil'],
    'kuu_rice_kurdish_oil_bowl': ['kurdish rice bowl oil'],
    'kuu_rice_kurdish_no_oil_bowl': ['kurdish rice bowl no oil'],
    'kuu_paqla_raw_no_oil_100g': ['paqla', 'broad beans', 'fava beans', 'پاقلە', 'باقلا'],
    'shl_kolk_kurdi_100g': ['zucchini shla', 'kolek', 'kolk', 'کولەکە', 'شلە کولەکە'],
    'sup_on_gold_whey': ['optimum nutrition', 'gold standard whey', 'on whey', 'whey protein', 'وی پروتین', 'بروتين واي'],
    'sup_whey_isolate': ['mpn isolate', 'maxpro isolate', 'isolate blend', 'banana protein', 'پرۆتینی ئایسۆلەیت'],
    'sup_mass_gainer': ['mpn pro mass', 'maxpro mass', 'mass gainer', 'pro mass vanilla', 'گەینەر', 'mass protein'],
    'sup_whey_concentrate': ['whey concentrate', 'whey scoop', 'پرۆتینی وەی'],
    'ff_big_mac': ['big mac', 'mcdonalds', 'mcd burger', 'بیگ ماک'],
    'ff_mcnuggets': ['mcnuggets', 'chicken nuggets', 'ناگێتس'],
    'ff_whopper': ['burger king', 'whopper', 'وۆپەر'],
    'ff_kfc_breast': ['kfc', 'kentucky fried', 'كنتاكي'],
  };

  /// Match [query] against any localized name (spacing-normalized, Arabic/Kurdish folding, light fuzzy).
  bool matchesSearchQuery(String query) {
    final nq = normalizeForFoodSearch(query);
    if (nq.isEmpty) return true;
    if (foodSearchFieldMatches(name, nq)) return true;
    if (foodSearchFieldMatches(nameAr, nq)) return true;
    if (foodSearchFieldMatches(nameKu, nq)) return true;
    final extra = searchAliases[id];
    if (extra != null) {
      for (final e in extra) {
        if (foodSearchFieldMatches(e, nq)) return true;
      }
    }
    return false;
  }

  static Map<String, double> _microsFromJson(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0),
    );
  }

  /// Decode a JSON array string (e.g. from a file or API) into [FoodItem]s.
  static List<FoodItem> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String getLocalizedName(String lang) {
    if (lang == 'ar') return nameAr ?? name;
    if ((lang == 'ku' || lang == 'ckb')) return nameKu ?? name;
    return name;
  }

  /// Localized serving line (100g / bowl / piece) when [servingLabel*] are set.
  String? servingLabelForLang(String lang) {
    switch (lang) {
      case 'ar':
        return servingLabelAr ?? servingLabelEn;
      case 'ckb':
      case 'ku':
        return servingLabelKu ?? servingLabelEn;
      default:
        return servingLabelEn ?? servingLabelKu;
    }
  }

  Map<String, double> getMicrosForAmount(double amountG) {
    final ratio = macroRatio(amountG);
    return micros.map((k, v) => MapEntry(k, v * ratio));
  }

  /// Returns a synthesized variant of this item whose [nutritionReferenceG]
  /// equals [gramsPerUnit]. Macros and micros are scaled linearly from the
  /// canonical per-[nutritionReferenceG] row so the log sheet's
  /// `food.calories * (totalGrams / nutritionReferenceG)` math stays correct.
  ///
  /// Used by the food-log piece / bowl switch for items that opt in via
  /// [gramsPerPiece] or [gramsPerBowl] without needing a separate FoodItem.
  FoodItem asServingVariant({
    required String idSuffix,
    required double gramsPerUnit,
    String? servingLabelEn,
    String? servingLabelKu,
    String? servingLabelAr,
  }) {
    final ratio = gramsPerUnit / nutritionReferenceG;
    return FoodItem(
      id: '${id}_$idSuffix',
      name: name,
      nameAr: nameAr,
      nameKu: nameKu,
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      category: category,
      micros: micros.map((k, v) => MapEntry(k, v * ratio)),
      nutritionReferenceG: gramsPerUnit,
      servingLabelEn: servingLabelEn ?? this.servingLabelEn,
      servingLabelKu: servingLabelKu ?? this.servingLabelKu,
      servingLabelAr: servingLabelAr ?? this.servingLabelAr,
      amountKind: amountKind,
      discreteUnit: discreteUnit,
      gramsPerPiece: gramsPerPiece,
      gramsPerBowl: gramsPerBowl,
    );
  }
}
