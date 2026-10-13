import 'package:nutrify/models/food_item.dart';

/// Foods where macros are per edible meat; weighing bone-in portions needs a lower factor.
const Set<String> _noBoneChoiceIds = {
  'p4',
  'p6',
  'p8',
  'p9',
  'p18',
  'p23',
  'p7',
  'p14',
  'p20',
  'p21',
};

bool _idMatchesPrefix(String id, String prefix) => id == prefix || id.startsWith('${prefix}_');

bool _isKurdishMeatDish(String id) =>
    id.startsWith('kuu_kebab') ||
    id.startsWith('kuu_chicken') ||
    id.startsWith('kuu_shish') ||
    id.startsWith('kuu_fish') ||
    id.startsWith('kuu_boiled_lamb') ||
    id.startsWith('kuu_quozi') ||
    id.startsWith('kuu_turkish_kebab') ||
    id == 'kuu_qara_meat_100g';

/// Whether the log sheet should offer boneless vs with-bones for this food.
bool meatSupportsBoneChoice(FoodItem food) {
  final id = food.id;
  if (_noBoneChoiceIds.contains(id)) return false;
  if (_idMatchesPrefix(id, 'p4') ||
      _idMatchesPrefix(id, 'p6') ||
      _idMatchesPrefix(id, 'p7') ||
      _idMatchesPrefix(id, 'p8') ||
      _idMatchesPrefix(id, 'p9') ||
      _idMatchesPrefix(id, 'p18') ||
      _idMatchesPrefix(id, 'p23')) {
    return false;
  }
  if (food.category == 'Protein') return true;
  if (_isKurdishMeatDish(id)) return true;
  if (id == 'i4' || id == 'k16') return true;
  return false;
}

/// Edible-meat fraction of scale weight when bones are included (USDA-style yields).
double meatBoneInMacroFactor(String foodId) {
  final id = foodId.toLowerCase();

  if (id == 'p13' || id.contains('wing')) return 0.52;
  if (_idMatchesPrefix(id, 'p11') || id.contains('thigh')) return 0.68;
  if (id.contains('drumstick') || id.contains('_leg')) return 0.66;

  if (_idMatchesPrefix(id, 'p5') ||
      id.contains('lamb') ||
      id.contains('gosht') ||
      id.contains('berkh') ||
      id == 'kuu_boiled_lamb_100g') {
    return 0.62;
  }
  if (id.contains('shish_gosht')) return 0.70;
  if (id.contains('shish_sing') || id.contains('breast')) return 0.84;

  if (id.contains('fish_tikka') || id.contains('shrimp_tikka')) return 0.90;
  if (id.contains('kebab') || id.contains('tikka') || id == 'p22') return 0.93;

  if (_idMatchesPrefix(id, 'p2') ||
      _idMatchesPrefix(id, 'p16') ||
      (id.contains('fish') && !id.contains('broth'))) {
    return 0.55;
  }
  if (id == 'p12' || id.contains('sardine')) return 0.78;

  if (_idMatchesPrefix(id, 'p1')) return 0.84;
  if (_idMatchesPrefix(id, 'p3') || id.contains('steak') || id.contains('beef_cu')) {
    return 0.88;
  }
  if (id == 'i4' || id.contains('fried_chicken')) return 0.58;
  if (_idMatchesPrefix(id, 'p17')) return 0.72;
  if (id == 'p15') return 0.65;
  if (id == 'kuu_qara_meat_100g') return 0.72;
  if (id.startsWith('kuu_quozi')) return 0.78;

  return 0.70;
}

/// Multiplier applied to macro ratio when logging bone-in portions on a scale.
double meatLogMacroMultiplier(FoodItem food, {required bool withBones}) {
  if (!withBones || !meatSupportsBoneChoice(food)) return 1.0;
  return meatBoneInMacroFactor(food.id);
}

String meatBoneSuffixForLang(String lang, {required bool withBones}) {
  if (!withBones) return '';
  if (lang == 'ar') return ' (مع عظم)';
  if (lang == 'ku') return ' (بە ئێسک)';
  return ' (with bones)';
}
