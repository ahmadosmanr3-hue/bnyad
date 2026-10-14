/// Fixed fictional examples, not generated nutritional advice or image analysis.
Map<String, String> demoText(String en, String ar, String ku) => {
  'en': en,
  'ar': ar,
  'ku': ku,
};

Map<String, dynamic> demoMeal([String slot = 'lunch']) {
  final names = switch (slot) {
    'breakfast' => demoText(
      'Demo: oats and banana',
      'نموذج: شوفان وموز',
      'نموونە: جۆدۆسەر و مۆز',
    ),
    'dinner' => demoText(
      'Demo: lentil soup',
      'نموذج: شوربة عدس',
      'نموونە: شۆربای نیسک',
    ),
    'snacks' => demoText(
      'Demo: apple and yogurt',
      'نموذج: تفاح ولبن',
      'نموونە: سێو و ماست',
    ),
    _ => demoText(
      'Demo: chickpea rice bowl',
      'نموذج: أرز وحمص',
      'نموونە: برنج و نۆک',
    ),
  };
  final ingredients = switch (slot) {
    'breakfast' => {
      'en': ['60 g oats', '150 g banana', '150 ml milk'],
      'ar': ['٦٠ غ شوفان', '١٥٠ غ موز', '١٥٠ مل حليب'],
      'ku': ['٦٠ گرام جۆدۆسەر', '١٥٠ گرام مۆز', '١٥٠ مل شیر'],
    },
    'dinner' => {
      'en': ['200 g cooked lentils', '150 g vegetables', '150 ml water'],
      'ar': ['٢٠٠ غ عدس مطبوخ', '١٥٠ غ خضار', '١٥٠ مل ماء'],
      'ku': ['٢٠٠ گرام نیسکی کوڵاو', '١٥٠ گرام سەوزە', '١٥٠ مل ئاو'],
    },
    'snacks' => {
      'en': ['150 g apple', '150 g plain yogurt'],
      'ar': ['١٥٠ غ تفاح', '١٥٠ غ لبن'],
      'ku': ['١٥٠ گرام سێو', '١٥٠ گرام ماست'],
    },
    _ => {
      'en': ['150 g cooked rice', '100 g cooked chickpeas', '100 g vegetables'],
      'ar': ['١٥٠ غ أرز مطبوخ', '١٠٠ غ حمص مطبوخ', '١٠٠ غ خضار'],
      'ku': ['١٥٠ گرام برنجی کوڵاو', '١٠٠ گرام نۆکی کوڵاو', '١٠٠ گرام سەوزە'],
    },
  };
  final (calories, protein, carbs, fat, grams) = switch (slot) {
    'breakfast' => (360, 12, 60, 8, 360),
    'dinner' => (400, 20, 62, 8, 500),
    'snacks' => (234, 12, 33, 6, 300),
    _ => (484, 18, 76, 12, 350),
  };
  return {
    'name': names['en'],
    'names': names,
    'ingredients': ingredients,
    'instructions': {
      'en': [
        'SIMULATED example; not a real generated recipe.',
        'Combine the cooked ingredients. Confirm portions before logging.',
      ],
      'ar': [
        'مثال محاكى، وليس وصفة مولدة حقيقية.',
        'اخلط المكونات المطبوخة وتأكد من الكميات.',
      ],
      'ku': [
        'ئەمە نموونەیە، نەک ڕەچەتەیەکی ڕاستەقینەی AI.',
        'پێکهاتە کوڵاوەکان تێکەڵ بکە و بڕەکان پشتڕاست بکەرەوە.',
      ],
    },
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'portionGrams': grams,
    'portion_grams': grams,
    'micros': <String, double>{},
  };
}

Map<String, dynamic> demoMealPlan() => {
  for (final slot in ['breakfast', 'lunch', 'dinner', 'snacks'])
    slot: demoMeal(slot),
};

Map<String, dynamic>? demoAiResponse(
  String operation,
  Map<String, dynamic> input,
) => switch (operation) {
  'guidance' => demoText(
    'SIMULATED: explore food, water and weight tracking. This is fictional data, not health advice.',
    'نموذج محاكى: جرّب تتبع الطعام والماء والوزن. ليست نصيحة صحية.',
    'نموونە: تۆمارکردنی خواردن و ئاو و کێش تاقی بکەرەوە. ڕێنمایی تەندروستی نییە.',
  ),
  'meal-plan' => demoMealPlan(),
  'meal' || 'details' => demoMeal(input['slot']?.toString() ?? 'lunch'),
  'recipe' => demoMeal(),
  'fridge' => {
    'detected_ingredients': {
      'en': ['SIMULATED: rice', 'chickpeas', 'vegetables'],
      'ar': ['نموذج: أرز', 'حمص', 'خضار'],
      'ku': ['نموونە: برنج', 'نۆک', 'سەوزە'],
    },
    'recipe': demoMeal(),
  },
  'food' => {
    'names': demoText(
      'Demo: rice bowl (not identified)',
      'نموذج: طبق أرز، ليس تحليلاً',
      'نموونە: برنج، نەک ناسینەوەی وێنە',
    ),
    'descriptions': demoText(
      'Fixed fixture. No photo was analyzed or uploaded. Confirm the food and portion.',
      'مثال ثابت. لم يتم تحليل أو إرسال الصورة.',
      'نموونەی جێگیر. وێنەکە شیکاری یان نێردراو نییە.',
    ),
    'calories': 140,
    'protein': 4,
    'carbs': 22,
    'fat': 4,
    'estimated_grams': 100,
    'confidence': 'low',
    'requiresConfirmation': true,
    'components': [],
    'micros': <String, double>{},
  },
  'shopping' => {
    'items': [
      {
        'name': demoText('Demo: rice', 'نموذج: أرز', 'نموونە: برنج'),
        'reason': demoText(
          'Fixed example only',
          'مثال ثابت فقط',
          'تەنها نموونەیە',
        ),
      },
    ],
  },
  // Do not invent a body composition measurement from a photograph.
  _ => null,
};

Map<String, dynamic> demoProfile() => {
  'uid': '909009',
  'display_name': 'BNYAD Demo User',
  'weight': 75.0,
  'height': 175.0,
  'age': 30,
  'gender': 'male',
  'activity_level': 'moderatelyActive',
  'goal': 'stayHealthy',
  'sicknesses': [],
  'allergies': [],
  'disabilities': [],
  'daily_calories': 2200,
  'daily_protein': 120,
  'daily_carbs': 268,
  'daily_fat': 72,
  'language': 'en',
  'theme': 'light',
  'onboarded': true,
};

String demoDate(DateTime date) => date.toIso8601String().substring(0, 10);

Map<String, dynamic> demoSeed({DateTime? now}) {
  final today = now ?? DateTime.now();
  final logs = <Map<String, dynamic>>[];
  for (var day = 0; day < 7; day++) {
    final date = demoDate(today.subtract(Duration(days: day)));
    for (final meal in ['breakfast', 'lunch']) {
      logs.add({
        'id': 'seed-$day-$meal',
        'external_food_id': 'demo-$meal',
        'name': meal == 'breakfast'
            ? 'Demo: oats and banana'
            : 'Demo: rice and chickpeas',
        'amount': 250,
        'calories': meal == 'breakfast' ? 360 : 484,
        'protein': meal == 'breakfast' ? 12 : 18,
        'carbs': meal == 'breakfast' ? 60 : 76,
        'fat': meal == 'breakfast' ? 8 : 12,
        'logged_at': date,
        'consumed_at': '${date}T${meal == 'breakfast' ? '08' : '12'}:00:00',
        'meal_type': meal,
        'micros': {'fiber': 6.0},
      });
    }
  }
  return {
    'profile': demoProfile(),
    'logs': logs,
    'water': {
      for (var day = 0; day < 7; day++)
        demoDate(today.subtract(Duration(days: day))): 4,
    },
    'weights': <dynamic>[],
    'plan': demoMealPlan(),
    'premium': true,
    'consent': true, // Fixture access only; no Google consent or data sharing.
    'nextId': 1,
  };
}
