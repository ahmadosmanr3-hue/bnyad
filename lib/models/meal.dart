class Meal {
  /// New AI recipes use server-computed edible grams in each ingredient line.
  double? get portionGrams {
    final matches = ingredientsForLang(
      'en',
    ).map((line) => RegExp(r'^(\d+(?:\.\d+)?) g ').firstMatch(line)).toList();
    if (matches.isEmpty || matches.any((m) => m == null)) return null;
    return matches.fold<double>(0, (sum, m) => sum + double.parse(m![1]!));
  }

  final String name;

  /// When set, [name] is typically the English fallback for prompts / legacy.
  final Map<String, String>? namesByLang;
  final List<String> ingredients;
  final Map<String, List<String>>? ingredientsByLang;
  final List<String> instructions;
  final Map<String, List<String>>? instructionsByLang;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  /// Total micronutrients for this whole meal (same units as [FoodItem.micros] per 100g basis but scaled to the meal).
  final Map<String, double> micros;

  Meal({
    required this.name,
    this.namesByLang,
    required this.ingredients,
    this.ingredientsByLang,
    required this.instructions,
    this.instructionsByLang,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.micros = const {},
  });

  static String _normLang(String lang) {
    if (lang == 'ar') return 'ar';
    if ((lang == 'ku' || lang == 'ckb')) return 'ku';
    return 'en';
  }

  String nameForLang(String lang) {
    final k = _normLang(lang);
    final m = namesByLang;
    if (m != null) {
      final v = m[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
      for (final fallback in ['en', 'ar', 'ku']) {
        final t = m[fallback];
        if (t != null && t.trim().isNotEmpty) return t.trim();
      }
    }
    return name;
  }

  List<String> ingredientsForLang(String lang) {
    final k = _normLang(lang);
    final m = ingredientsByLang;
    if (m != null) {
      final v = m[k];
      if (v != null && v.isNotEmpty) return v;
      for (final fallback in ['en', 'ar', 'ku']) {
        final t = m[fallback];
        if (t != null && t.isNotEmpty) return t;
      }
    }
    return ingredients;
  }

  List<String> instructionsForLang(String lang) {
    final k = _normLang(lang);
    final m = instructionsByLang;
    if (m != null) {
      final v = m[k];
      if (v != null && v.isNotEmpty) return v;
      for (final fallback in ['en', 'ar', 'ku']) {
        final t = m[fallback];
        if (t != null && t.isNotEmpty) return t;
      }
    }
    return instructions;
  }

  bool needsDetailsForLang(String lang) {
    return ingredientsForLang(lang).isEmpty ||
        instructionsForLang(lang).isEmpty;
  }

  static Map<String, String>? _parseNamesMap(dynamic raw) {
    if (raw is! Map) return null;
    final en = raw['en']?.toString().trim() ?? '';
    final ar = raw['ar']?.toString().trim() ?? '';
    final ku = raw['ku']?.toString().trim() ?? '';
    if (en.isEmpty && ar.isEmpty && ku.isEmpty) return null;
    return {'en': en, 'ar': ar, 'ku': ku};
  }

  static Map<String, List<String>>? _parseListMap(dynamic raw) {
    if (raw is! Map) return null;
    List<String> parseList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    final en = parseList(raw['en']);
    final ar = parseList(raw['ar']);
    final ku = parseList(raw['ku']);
    if (en.isEmpty && ar.isEmpty && ku.isEmpty) return null;
    return {'en': en, 'ar': ar, 'ku': ku};
  }

  static List<String> _primaryListFromLangMap(Map<String, List<String>> m) {
    for (final k in ['en', 'ar', 'ku']) {
      final v = m[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return m['en'] ?? [];
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    final rawMicros = map['micros'];
    final micros = <String, double>{};
    if (rawMicros is Map) {
      for (final e in rawMicros.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is num && v.toDouble() >= 0) micros[k] = v.toDouble();
      }
    }

    final namesMap = _parseNamesMap(map['names']);
    var primaryName = map['name']?.toString().trim() ?? '';
    if (primaryName.isEmpty && namesMap != null) {
      for (final k in ['en', 'ar', 'ku']) {
        final v = namesMap[k];
        if (v != null && v.trim().isNotEmpty) {
          primaryName = v.trim();
          break;
        }
      }
    }

    Map<String, List<String>>? ingByLang;
    List<String> ingList;
    final rawIng = map['ingredients'];
    if (rawIng is Map) {
      ingByLang = _parseListMap(rawIng);
      ingList = ingByLang != null ? _primaryListFromLangMap(ingByLang) : [];
    } else {
      ingList = List<String>.from(map['ingredients'] ?? []);
    }

    Map<String, List<String>>? instByLang;
    List<String> instList;
    final rawInst = map['instructions'];
    if (rawInst is Map) {
      instByLang = _parseListMap(rawInst);
      instList = instByLang != null ? _primaryListFromLangMap(instByLang) : [];
    } else {
      instList = List<String>.from(map['instructions'] ?? []);
    }

    return Meal(
      name: primaryName,
      namesByLang: namesMap,
      ingredients: ingList,
      ingredientsByLang: ingByLang,
      instructions: instList,
      instructionsByLang: instByLang,
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fat: (map['fat'] as num?)?.toInt() ?? 0,
      micros: micros,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (namesByLang != null) 'names': namesByLang,
    'ingredients': ingredientsByLang ?? ingredients,
    'instructions': instructionsByLang ?? instructions,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    if (micros.isNotEmpty) 'micros': micros,
  };

  Meal copyWith({
    String? name,
    Map<String, String>? namesByLang,
    List<String>? ingredients,
    Map<String, List<String>>? ingredientsByLang,
    List<String>? instructions,
    Map<String, List<String>>? instructionsByLang,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    Map<String, double>? micros,
  }) {
    return Meal(
      name: name ?? this.name,
      namesByLang: namesByLang ?? this.namesByLang,
      ingredients: ingredients ?? this.ingredients,
      ingredientsByLang: ingredientsByLang ?? this.ingredientsByLang,
      instructions: instructions ?? this.instructions,
      instructionsByLang: instructionsByLang ?? this.instructionsByLang,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      micros: micros ?? this.micros,
    );
  }
}

class MealPlanData {
  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final Meal snacks;

  MealPlanData({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
  });

  factory MealPlanData.fromMap(Map<String, dynamic> map) {
    return MealPlanData(
      breakfast: Meal.fromMap(
        Map<String, dynamic>.from(map['breakfast'] ?? {}),
      ),
      lunch: Meal.fromMap(Map<String, dynamic>.from(map['lunch'] ?? {})),
      dinner: Meal.fromMap(Map<String, dynamic>.from(map['dinner'] ?? {})),
      snacks: Meal.fromMap(Map<String, dynamic>.from(map['snacks'] ?? {})),
    );
  }

  Map<String, dynamic> toMap() => {
    'breakfast': breakfast.toMap(),
    'lunch': lunch.toMap(),
    'dinner': dinner.toMap(),
    'snacks': snacks.toMap(),
  };

  MealPlanData copyWith({
    Meal? breakfast,
    Meal? lunch,
    Meal? dinner,
    Meal? snacks,
  }) {
    return MealPlanData(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
    );
  }
}
