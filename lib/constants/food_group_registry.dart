import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/constants/food_serving_switch.dart';
import 'package:nutrify/constants/shla_no_oil_variants.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/utils/food_search_match.dart';

/// One row in the food log search list; tapping opens [options] when length > 1.
class FoodPickGroup {
  final String id;
  final String listFoodId;
  final String? titleEn;
  final String? titleAr;
  final String? titleKu;
  final List<FoodGroupOption> options;
  final Map<String, FoodPickGroup>? subGroups;

  const FoodPickGroup({
    required this.id,
    required this.listFoodId,
    this.titleEn,
    this.titleAr,
    this.titleKu,
    required this.options,
    this.subGroups,
  });

  String titleForLang(String lang) {
    if (lang == 'ar') return titleAr ?? titleEn ?? '';
    if (lang == 'ku') return titleKu ?? titleEn ?? '';
    return titleEn ?? '';
  }
}

class FoodGroupOption {
  final String foodId;
  final String? subGroupKey;
  final String labelEn;
  final String? labelAr;
  final String? labelKu;

  const FoodGroupOption({
    required this.foodId,
    this.subGroupKey,
    required this.labelEn,
    this.labelAr,
    this.labelKu,
  });

  bool get opensSubGroup => subGroupKey != null && subGroupKey!.isNotEmpty;

  String labelForLang(String lang) {
    if (lang == 'ar') return labelAr ?? labelEn;
    if (lang == 'ku') return labelKu ?? labelEn;
    return labelEn;
  }
}

/// Bowl / spoon / piece rows map to a 100g (or primary) row — hide from browse list.
final Set<String> _servingSizeOnlyIds = {
  ...foodServingSizeVariantIds,
};

FoodGroupOption _optionFromFood(FoodItem f) => FoodGroupOption(
      foodId: f.id,
      labelEn: f.name,
      labelAr: f.nameAr,
      labelKu: f.nameKu,
    );

FoodGroupOption _optionById(String foodId, {String? labelEn, String? labelAr, String? labelKu}) {
  final f = foodById(foodId);
  if (f != null) return _optionFromFood(f);
  return FoodGroupOption(foodId: foodId, labelEn: labelEn ?? foodId, labelAr: labelAr, labelKu: labelKu);
}

FoodGroupOption _prepOption(String foodId, String en, String ar, String ku) =>
    FoodGroupOption(foodId: foodId, labelEn: en, labelAr: ar, labelKu: ku);

FoodGroupOption _oilSubOption(String key, String en, String ar, String ku) =>
    FoodGroupOption(foodId: key, subGroupKey: key, labelEn: en, labelAr: ar, labelKu: ku);

FoodPickGroup _shlaPrepSubGroup({
  required String slug,
  required String boiledId,
  required String friedId,
  required String stewedId,
}) {
  return FoodPickGroup(
    id: 'grp_${slug}_prep',
    listFoodId: boiledId,
    titleEn: 'Cooking method',
    titleAr: 'طريقة الطبخ',
    titleKu: 'شێوازی چێشت',
    options: [
      _prepOption(boiledId, 'Boiled / simmered', 'مسلوق / مطبوخ', 'کوڵاو'),
      _prepOption(friedId, 'Fried / sautéed', 'مقلي', 'سوراو'),
      _prepOption(stewedId, 'Stewed', 'مطبوخ في مرق', 'لێنراو'),
    ],
  );
}

FoodPickGroup _proteinPrepSubGroup({
  required String id,
  required String listFoodId,
  required List<FoodGroupOption> options,
}) {
  return FoodPickGroup(
    id: id,
    listFoodId: listFoodId,
    titleEn: 'Cooking method',
    titleAr: 'طريقة الطبخ',
    titleKu: 'شێوازی چێشت',
    options: options,
  );
}

/// Foods that appear once in search; preparation / type chosen on the next step.
final List<FoodPickGroup> _manualFoodPickGroups = [
  FoodPickGroup(
    id: 'grp_chicken_breast',
    listFoodId: 'p1',
    titleEn: 'Chicken Breast',
    titleAr: 'صدر دجاج',
    titleKu: 'سنگی مریشک',
    options: [
      _oilSubOption('no_oil', 'Without added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _proteinPrepSubGroup(
        id: 'grp_chicken_breast_no_oil',
        listFoodId: 'p1',
        options: [
          _prepOption('p1', 'Grilled', 'مشوي', 'برژاو'),
          _prepOption('p1_boiled', 'Boiled', 'مسلوق', 'کوڵاو'),
          _prepOption('p1_roasted', 'Roasted', 'بالفرن', 'برژاو لە فرن'),
          _prepOption('p1_stew', 'Stewed / in sauce', 'مطبوخ بصلصة', 'لێنراو لە سۆس'),
        ],
      ),
      'with_oil': _proteinPrepSubGroup(
        id: 'grp_chicken_breast_with_oil',
        listFoodId: 'p1_fried',
        options: [
          _prepOption('p1_fried', 'Fried', 'مقلي', 'سوراو'),
          _prepOption('p1_stew', 'Stewed / in sauce', 'مطبوخ بصلصة', 'لێنراو لە سۆس'),
          _prepOption('p1', 'Grilled (light oil)', 'مشوي', 'برژاو'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_beef_steak',
    listFoodId: 'p3',
    titleEn: 'Beef Steak',
    titleAr: 'ستيك لحم بقري',
    titleKu: 'ستیکی گۆشتی مانگا',
    options: [
      FoodGroupOption(foodId: 'p3', labelEn: 'Standard', labelAr: 'عادي', labelKu: 'ئاسایی'),
      FoodGroupOption(foodId: 'p3_grilled', labelEn: 'Grilled (lean)', labelAr: 'مشوي قليل دهن', labelKu: 'برژاو (کم چەوری)'),
      FoodGroupOption(foodId: 'p3_stew', labelEn: 'Stewed', labelAr: 'مطبوخ', labelKu: 'لێنراو'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_ground_beef',
    listFoodId: 'p4',
    titleEn: 'Ground Beef',
    titleAr: 'لحم مفروم',
    titleKu: 'گۆشتی هاڕاو',
    options: [
      FoodGroupOption(foodId: 'p4', labelEn: 'Standard', labelAr: 'عادي', labelKu: 'ئاسایی'),
      FoodGroupOption(foodId: 'p4_grilled', labelEn: 'Grilled', labelAr: 'مشوي', labelKu: 'برژاو'),
      FoodGroupOption(foodId: 'p4_fried', labelEn: 'Pan-fried', labelAr: 'مقلي', labelKu: 'سوراو'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_lamb_chop',
    listFoodId: 'p5',
    titleEn: 'Lamb',
    titleAr: 'لحم غنم',
    titleKu: 'گۆشتی بەرخ',
    options: [
      FoodGroupOption(foodId: 'p5', labelEn: 'Lamb chop', labelAr: 'ريش غنم', labelKu: 'پارچەی بەرخ'),
      FoodGroupOption(foodId: 'p5_grilled', labelEn: 'Grilled chop', labelAr: 'ريش مشوي', labelKu: 'پارچە (برژاو)'),
      FoodGroupOption(foodId: 'p5_boiled', labelEn: 'Boiled', labelAr: 'مسلوق', labelKu: 'کوڵاو'),
      FoodGroupOption(foodId: 'p15', labelEn: 'Shoulder', labelAr: 'كتف', labelKu: 'شان'),
      FoodGroupOption(
        foodId: 'kuu_boiled_lamb_100g',
        labelEn: 'Boiled (Kurdish style)',
        labelAr: 'مسلوق بأسلوب كوردي',
        labelKu: 'کوڵاو (شێوازی کوردی)',
      ),
    ],
  ),
  FoodPickGroup(
    id: 'grp_chicken_thigh',
    listFoodId: 'p11',
    titleEn: 'Chicken Thigh',
    titleAr: 'فخذ دجاج',
    titleKu: 'ڕانی مریشک',
    options: [
      _oilSubOption('no_oil', 'Without added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _proteinPrepSubGroup(
        id: 'grp_chicken_thigh_no_oil',
        listFoodId: 'p11',
        options: [
          _prepOption('p11', 'Standard', 'عادي', 'ئاسایی'),
          _prepOption('p11_grilled', 'Grilled', 'مشوي', 'برژاو'),
          _prepOption('p11_roasted', 'Roasted', 'بالفرن', 'لە فرن'),
        ],
      ),
      'with_oil': _proteinPrepSubGroup(
        id: 'grp_chicken_thigh_with_oil',
        listFoodId: 'p11_fried',
        options: [
          _prepOption('p11_fried', 'Fried', 'مقلي', 'سوراو'),
          _prepOption('p11_grilled', 'Grilled', 'مشوي', 'برژاو'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_salmon',
    listFoodId: 'p2',
    titleEn: 'Salmon',
    titleAr: 'سلمون',
    titleKu: 'سەلمۆن',
    options: [
      FoodGroupOption(foodId: 'p2', labelEn: 'Standard', labelAr: 'عادي', labelKu: 'ئاسایی'),
      FoodGroupOption(foodId: 'p2_grilled', labelEn: 'Grilled', labelAr: 'مشوي', labelKu: 'برژاو'),
      FoodGroupOption(foodId: 'p2_baked', labelEn: 'Baked', labelAr: 'بالفرن', labelKu: 'لە فرن'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_shrimp',
    listFoodId: 'p7',
    titleEn: 'Shrimp',
    titleAr: 'جمبري',
    titleKu: 'میگۆ',
    options: [
      FoodGroupOption(foodId: 'p7', labelEn: 'Standard', labelAr: 'عادي', labelKu: 'ئاسایی'),
      FoodGroupOption(foodId: 'p7_grilled', labelEn: 'Grilled', labelAr: 'مشوي', labelKu: 'برژاو'),
      FoodGroupOption(foodId: 'p7_fried', labelEn: 'Fried', labelAr: 'مقلي', labelKu: 'سوراو'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_white_rice',
    listFoodId: 'g2',
    titleEn: 'White Rice',
    titleAr: 'أرز أبيض',
    titleKu: 'برنجی سپی',
    options: [
      _oilSubOption('no_oil', 'Without added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _proteinPrepSubGroup(
        id: 'grp_white_rice_no_oil',
        listFoodId: 'g2_steamed',
        options: [
          _prepOption('g2_steamed', 'Steamed', 'مطهو على البخار', 'بە بخار'),
          _prepOption('g2', 'Plain cooked', 'مطبوخ عادي', 'ئاسایی لێنراو'),
          _prepOption('kuu_rice_white_no_oil_100g', 'Kurdish style', 'بأسلوب كوردي', 'شێوازی کوردی'),
        ],
      ),
      'with_oil': _proteinPrepSubGroup(
        id: 'grp_white_rice_with_oil',
        listFoodId: 'g2_with_oil',
        options: [
          _prepOption('g2_with_oil', 'Cooked with oil', 'بالزيت', 'بە ڕۆن'),
          _prepOption('g2', 'Plain cooked', 'مطبوخ عادي', 'ئاسایی'),
          _prepOption('kuu_rice_white_oil_100g', 'Kurdish style', 'بأسلوب كوردي', 'شێوازی کوردی'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_kurdish_rice',
    listFoodId: 'kuu_rice_kurdish_no_oil_100g',
    titleEn: 'Kurdish Rice',
    titleAr: 'أرز كوردي',
    titleKu: 'برنجی کوردی',
    options: [
      _oilSubOption('no_oil', 'Without added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _proteinPrepSubGroup(
        id: 'grp_kurdish_rice_no_oil',
        listFoodId: 'kuu_rice_kurdish_no_oil_100g',
        options: [
          _prepOption('kuu_rice_kurdish_no_oil_100g', 'Standard', 'عادي', 'ئاسایی'),
          _prepOption('kuu_rice_red_100g', 'Red rice', 'أرز أحمر', 'برنجی سوور'),
          _prepOption('kuu_rice_yellow_100g', 'Yellow rice', 'أرز أصفر', 'برنجی زەرد'),
          _prepOption('kuu_rice_brown_100g', 'Brown rice', 'أرز بني', 'برنجی قاوەیی'),
          _prepOption('kuu_rice_mung_100g', 'Mung bean rice', 'أرز ماش', 'برنجی ماش'),
          _prepOption('kuu_rice_kurdish_precooked_100g', 'Pre-cooked', 'مسبق الطبخ', 'پێشتر لێنراو'),
        ],
      ),
      'with_oil': _proteinPrepSubGroup(
        id: 'grp_kurdish_rice_with_oil',
        listFoodId: 'kuu_rice_kurdish_oil_100g',
        options: [
          _prepOption('kuu_rice_kurdish_oil_100g', 'Standard', 'عادي', 'ئاسایی'),
          _prepOption('kuu_rice_red_100g', 'Red rice', 'أرز أحمر', 'برنجی سوور'),
          _prepOption('kuu_rice_yellow_100g', 'Yellow rice', 'أرز أصفر', 'برنجی زەرد'),
          _prepOption('kuu_rice_brown_100g', 'Brown rice', 'أرز بني', 'برنجی قاوەیی'),
          _prepOption('kuu_rice_mung_100g', 'Mung bean rice', 'أرز ماش', 'برنجی ماش'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_kurdish_biryani',
    listFoodId: 'k2',
    titleEn: 'Kurdish Biryani',
    titleAr: 'برياني كوردي',
    titleKu: 'بریانی کوردی',
    options: [
      _oilSubOption('no_oil', 'No added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _proteinPrepSubGroup(
        id: 'grp_k2_no_oil',
        listFoodId: 'k2_no_oil',
        options: [
          _prepOption('k2_no_oil', 'Standard', 'عادي', 'ئاسایی'),
          _prepOption('k2_chicken', 'With chicken', 'بالدجاج', 'بە مریشک'),
          _prepOption('k2_meat', 'With meat', 'باللحم', 'بە گۆشت'),
        ],
      ),
      'with_oil': _proteinPrepSubGroup(
        id: 'grp_k2_with_oil',
        listFoodId: 'k2_with_oil',
        options: [
          _prepOption('k2_with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
          _prepOption('k2', 'Standard', 'عادي', 'ئاسایی'),
          _prepOption('k2_chicken', 'With chicken', 'بالدجاج', 'بە مریشک'),
          _prepOption('k2_meat', 'With meat', 'باللحم', 'بە گۆشت'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_egg',
    listFoodId: 'p8',
    titleEn: 'Egg',
    titleAr: 'بيض',
    titleKu: 'هێلکە',
    options: [
      FoodGroupOption(foodId: 'p8_boiled', labelEn: 'Whole egg — boiled', labelAr: 'بيضة مسلوقة', labelKu: 'هێلکەی تاک — کوڵاو'),
      FoodGroupOption(foodId: 'p8_fried', labelEn: 'Whole egg — fried', labelAr: 'بيضة مقلية', labelKu: 'هێلکەی تاک — سوراو'),
      FoodGroupOption(foodId: 'p8_poached', labelEn: 'Whole egg — poached', labelAr: 'بيضة مسلوقة في الماء', labelKu: 'هێلکەی تاک — لێنراو'),
      FoodGroupOption(foodId: 'p8_scrambled', labelEn: 'Whole egg — scrambled', labelAr: 'بيض مخفوق', labelKu: 'هێلکەی تاک — تێکەڵکراو'),
      FoodGroupOption(foodId: 'p8', labelEn: 'Whole egg — raw', labelAr: 'بيضة نيئة', labelKu: 'هێلکەی تاک — خام'),
      FoodGroupOption(foodId: 'p9', labelEn: 'Egg white', labelAr: 'بياض البيض', labelKu: 'سپێناوی هێلکە'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_paqla',
    listFoodId: 'kuu_paqla_raw_no_oil_100g',
    titleEn: 'Broad Beans (Paqla)',
    titleAr: 'فول أخضر (باقلا)',
    titleKu: 'پاقلە',
    options: [
      _oilSubOption('no_oil', 'No added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': FoodPickGroup(
        id: 'grp_paqla_no_oil_prep',
        listFoodId: 'kuu_paqla_raw_no_oil_100g',
        titleEn: 'Cooking method',
        titleAr: 'طريقة الطبخ',
        titleKu: 'شێوازی چێشت',
        options: [
          _prepOption('kuu_paqla_raw_no_oil_100g', 'Raw', 'نيء', 'خاو'),
          _prepOption('kuu_paqla_boiled_no_oil_100g', 'Boiled', 'مسلوق', 'کوڵاو'),
          _prepOption('kuu_paqla_raw_fried_no_oil_100g', 'Fried', 'مقلي', 'سوراو'),
        ],
      ),
      'with_oil': FoodPickGroup(
        id: 'grp_paqla_with_oil_prep',
        listFoodId: 'kuu_paqla_raw_with_oil_100g',
        titleEn: 'Cooking method',
        titleAr: 'طريقة الطبخ',
        titleKu: 'شێوازی چێشت',
        options: [
          _prepOption('kuu_paqla_raw_with_oil_100g', 'Raw', 'نيء', 'خاو'),
          _prepOption('kuu_paqla_boiled_with_oil_100g', 'Boiled', 'مسلوق', 'کوڵاو'),
          _prepOption('kuu_paqla_raw_fried_with_oil_100g', 'Fried', 'مقلي', 'سوراو'),
        ],
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_tarkhina',
    listFoodId: 'kuu_tarkhina_100g',
    titleEn: 'Tarkhina',
    titleAr: 'ترخينة',
    titleKu: 'تڕخێنە',
    options: [
      _oilSubOption('no_oil', 'No added oil', 'بدون زيت', 'بێ ڕۆن'),
      _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
    ],
    subGroups: {
      'no_oil': _shlaPrepSubGroup(
        slug: 'tarkhina_no',
        boiledId: 'kuu_tarkhina_no_oil_100g',
        friedId: 'kuu_tarkhina_no_oil_fried_100g',
        stewedId: 'kuu_tarkhina_no_oil_stewed_100g',
      ),
      'with_oil': _shlaPrepSubGroup(
        slug: 'tarkhina_oil',
        boiledId: 'kuu_tarkhina_100g',
        friedId: 'kuu_tarkhina_fried_100g',
        stewedId: 'kuu_tarkhina_stewed_100g',
      ),
    },
  ),
  FoodPickGroup(
    id: 'grp_kubba',
    listFoodId: 'k3',
    titleEn: 'Kubba',
    titleAr: 'كبة',
    titleKu: 'کوبە',
    options: [
      FoodGroupOption(foodId: 'k3', labelEn: 'Kubba', labelAr: 'كبة', labelKu: 'کوبە'),
      FoodGroupOption(foodId: 'k14', labelEn: 'Kubba Halab', labelAr: 'كبة حلب', labelKu: 'کوبەی حەلەب'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_dolma',
    listFoodId: 'k1',
    titleEn: 'Dolma',
    titleAr: 'دولمة',
    titleKu: 'دۆڵمە',
    options: [
      FoodGroupOption(foodId: 'k1', labelEn: 'Kurdish dolma', labelAr: 'دولمة كوردية', labelKu: 'دۆڵمەی کوردی'),
      FoodGroupOption(foodId: 'k25', labelEn: 'Chard dolma', labelAr: 'دولمة سلق', labelKu: 'دۆڵمەی سەلق'),
    ],
  ),
];

/// Explicit multi-food groups (IDs that do not share one prefix).
final List<FoodPickGroup> _explicitFoodPickGroups = [
  FoodPickGroup(
    id: 'grp_kebab_skewers',
    listFoodId: 'kuu_kebab_100g',
    titleEn: 'Kebab & skewers',
    titleAr: 'كباب وأسياخ',
    titleKu: 'کەباب و شیش',
    options: [
      _optionById('kuu_kebab_100g'),
      _optionById('kuu_chicken_kebab_100g'),
      _optionById('kuu_turkish_kebab_100g'),
      _optionById('kuu_shish_gosht_100g'),
      _optionById('kuu_shish_sing_100g'),
      _optionById('kuu_kebab_bread_100g'),
      _optionById('p22'),
    ],
  ),
  FoodPickGroup(
    id: 'grp_tikka',
    listFoodId: 'kuu_fish_tikka_100g',
    titleEn: 'Tikka',
    titleAr: 'تكة',
    titleKu: 'تیکە',
    options: [
      _optionById('kuu_fish_tikka_100g'),
      _optionById('kuu_shrimp_tikka_100g'),
      _optionById('k16'),
    ],
  ),
];

class _PrefixGroupDef {
  final String id;
  final String prefix;
  final String titleEn;
  final String titleAr;
  final String titleKu;
  final String? defaultListFoodId;

  const _PrefixGroupDef({
    required this.id,
    required this.prefix,
    required this.titleEn,
    required this.titleAr,
    required this.titleKu,
    this.defaultListFoodId,
  });
}

/// Longest prefixes first so e.g. `kuu_plt_pasta` wins over `kuu_plt`.
const List<_PrefixGroupDef> _prefixGroupDefs = [
  _PrefixGroupDef(
    id: 'grp_pasta',
    prefix: 'kuu_plt_pasta',
    titleEn: 'Pasta',
    titleAr: 'معكرونة',
    titleKu: 'پاستا',
    defaultListFoodId: 'kuu_plt_pasta_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_wraps',
    prefix: 'kuu_plt_wrap',
    titleEn: 'Wraps & sandwiches',
    titleAr: 'ساندويتش ولفائف',
    titleKu: 'پێچان و ساندویچ',
    defaultListFoodId: 'kuu_plt_wrap_chicken_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_quozi',
    prefix: 'kuu_quozi',
    titleEn: 'Quzi',
    titleAr: 'قوزي',
    titleKu: 'قوزی',
    defaultListFoodId: 'kuu_quozi_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_qara',
    prefix: 'kuu_qara',
    titleEn: 'Qara',
    titleAr: 'قرة',
    titleKu: 'قەرە',
    defaultListFoodId: 'kuu_qara_plain_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_snk_bak',
    prefix: 'kuu_snk_bak',
    titleEn: 'Sweet bakery',
    titleAr: 'حلويات مخبوزة',
    titleKu: 'شیرینی نانەوا',
    defaultListFoodId: 'kuu_snk_bak_turkish_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_icecream',
    prefix: 'kuu_snk_icecream',
    titleEn: 'Ice cream',
    titleAr: 'آيس كريم',
    titleKu: 'ئایس کریم',
    defaultListFoodId: 'kuu_snk_icecream_soft_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_milk',
    prefix: 'kuu_mlk_',
    titleEn: 'Milk & dairy drinks',
    titleAr: 'حليب ومشروبات ألبان',
    titleKu: 'شیر و خواردنەوەی شیری',
    defaultListFoodId: 'kuu_mlk_buffalo_100g',
  ),
  _PrefixGroupDef(
    id: 'grp_sharbat',
    prefix: 'kuu_srb_',
    titleEn: 'Sharbat drinks',
    titleAr: 'شربات',
    titleKu: 'شەربەت',
    defaultListFoodId: 'kuu_srb_banana_100g',
  ),
];

bool _isReferenceBrowseId(String id) =>
    id.endsWith('_100g') || id.endsWith('_100ml');

Set<String> _allVariantIdsInGroup(FoodPickGroup g) => _collectLeafFoodIds(g);

List<FoodPickGroup> _buildPrefixGroups(Set<String> alreadyAssigned) {
  final groups = <FoodPickGroup>[];
  for (final def in _prefixGroupDefs) {
    final options = <FoodGroupOption>[];
    for (final f in foodDatabase) {
      if (!f.id.startsWith(def.prefix)) continue;
      if (!_isReferenceBrowseId(f.id)) continue;
      if (_servingSizeOnlyIds.contains(f.id)) continue;
      if (alreadyAssigned.contains(f.id)) continue;
      options.add(_optionFromFood(f));
    }
    if (options.length < 2) continue;
    options.sort((a, b) => a.labelEn.compareTo(b.labelEn));
    final listId = def.defaultListFoodId != null &&
            options.any((o) => o.foodId == def.defaultListFoodId)
        ? def.defaultListFoodId!
        : options.first.foodId;
    groups.add(FoodPickGroup(
      id: def.id,
      listFoodId: listId,
      titleEn: def.titleEn,
      titleAr: def.titleAr,
      titleKu: def.titleKu,
      options: options,
    ));
    alreadyAssigned.addAll(options.map((o) => o.foodId));
  }
  return groups;
}

String _titleFromClusterKey(String key) {
  final parts = key.split('_');
  if (parts.isEmpty) return key;
  final last = parts.last;
  return last.isEmpty ? key : '${last[0].toUpperCase()}${last.substring(1)}';
}

List<FoodPickGroup> _buildSiblingClusters(Set<String> alreadyAssigned) {
  final buckets = <String, List<FoodItem>>{};
  for (final f in foodDatabase) {
    if (!f.id.endsWith('_100g')) continue;
    if (alreadyAssigned.contains(f.id)) continue;
    if (_servingSizeOnlyIds.contains(f.id)) continue;
    final withoutSuffix = f.id.substring(0, f.id.length - 5);
    final lastUnderscore = withoutSuffix.lastIndexOf('_');
    if (lastUnderscore <= 0) continue;
    final clusterKey = withoutSuffix.substring(0, lastUnderscore);
    buckets.putIfAbsent(clusterKey, () => []).add(f);
  }

  final groups = <FoodPickGroup>[];
  for (final entry in buckets.entries) {
    if (entry.value.length < 2) continue;
    final foods = List<FoodItem>.from(entry.value)
      ..sort((a, b) => a.name.compareTo(b.name));
    final options = foods.map(_optionFromFood).toList();
    final listFood = foods.first;
    groups.add(FoodPickGroup(
      id: 'grp_auto_${entry.key}',
      listFoodId: listFood.id,
      titleEn: _titleFromClusterKey(entry.key),
      titleAr: listFood.nameAr,
      titleKu: listFood.nameKu,
      options: options,
    ));
    alreadyAssigned.addAll(options.map((o) => o.foodId));
  }
  return groups;
}

List<FoodPickGroup> _buildShlaOilPrepPickGroups(Set<String> alreadyAssigned) {
  final groups = <FoodPickGroup>[];
  for (final entry in shlaNoOilPairIds.entries) {
    final withOilId = entry.key;
    final noOilId = entry.value;
    if (alreadyAssigned.contains(withOilId)) continue;
    final withOil = foodById(withOilId);
    if (withOil == null) continue;

    final slug = withOilId.replaceAll('_100g', '');
    final noSlug = noOilId.replaceAll('_no_oil_100g', '').replaceAll('_100g', '');

    groups.add(FoodPickGroup(
      id: 'grp_oil_$slug',
      listFoodId: withOilId,
      titleEn: withOil.name.replaceAll(' (100g)', ''),
      titleAr: withOil.nameAr,
      titleKu: withOil.nameKu?.replaceAll(' (100 گرام)', ''),
      options: [
        _oilSubOption('no_oil', 'No added oil', 'بدون زيت', 'بێ ڕۆن'),
        _oilSubOption('with_oil', 'With oil', 'بالزيت', 'بە ڕۆن'),
      ],
      subGroups: {
        'no_oil': _shlaPrepSubGroup(
          slug: '${slug}_no',
          boiledId: noOilId,
          friedId: '${noSlug}_no_oil_fried_100g',
          stewedId: '${noSlug}_no_oil_stewed_100g',
        ),
        'with_oil': _shlaPrepSubGroup(
          slug: '${slug}_oil',
          boiledId: withOilId,
          friedId: '${slug}_fried_100g',
          stewedId: '${slug}_stewed_100g',
        ),
      },
    ));
    alreadyAssigned.add(withOilId);
    alreadyAssigned.add(noOilId);
  }
  return groups;
}

List<FoodPickGroup> _buildAllFoodPickGroups() {
  final groups = <FoodPickGroup>[
    ..._manualFoodPickGroups,
    ..._explicitFoodPickGroups,
  ];
  final assigned = <String>{};
  for (final g in groups) {
    assigned.addAll(_allVariantIdsInGroup(g));
  }

  groups.addAll(_buildPrefixGroups(assigned));

  assigned.clear();
  for (final g in groups) {
    assigned.addAll(_allVariantIdsInGroup(g));
  }

  groups.addAll(_buildSiblingClusters(assigned));

  assigned.clear();
  for (final g in groups) {
    assigned.addAll(_allVariantIdsInGroup(g));
  }

  groups.addAll(_buildShlaOilPrepPickGroups(assigned));
  return groups;
}

Set<String> _collectLeafFoodIds(FoodPickGroup g) {
  final ids = <String>{};
  void walk(FoodPickGroup group) {
    for (final o in group.options) {
      if (o.opensSubGroup && group.subGroups != null) {
        final sub = group.subGroups![o.subGroupKey!];
        if (sub != null) walk(sub);
      } else if (o.foodId.isNotEmpty) {
        ids.add(o.foodId);
      }
    }
  }
  walk(g);
  return ids;
}

void _registerGroupVariants(FoodPickGroup root, Map<String, FoodPickGroup> byVariant) {
  for (final id in _collectLeafFoodIds(root)) {
    byVariant[id] = root;
  }
}

void _registerHiddenFromGroup(FoodPickGroup root, Set<String> hidden) {
  for (final id in _collectLeafFoodIds(root)) {
    if (id != root.listFoodId) hidden.add(id);
  }
  if (root.subGroups != null) {
    for (final sub in root.subGroups!.values) {
      for (final id in _collectLeafFoodIds(sub)) {
        if (id != root.listFoodId) hidden.add(id);
      }
    }
  }
}

/// All dish families (manual + auto-discovered).
final List<FoodPickGroup> foodPickGroups = _buildAllFoodPickGroups();

final Map<String, FoodPickGroup> _groupByListId = {
  for (final g in foodPickGroups) g.listFoodId: g,
};

final Map<String, FoodPickGroup> _groupByVariantId = () {
  final map = <String, FoodPickGroup>{};
  for (final g in foodPickGroups) {
    _registerGroupVariants(g, map);
  }
  return map;
}();

final Set<String> _hiddenFromSearchIds = () {
  final hidden = <String>{..._servingSizeOnlyIds};
  for (final g in foodPickGroups) {
    _registerHiddenFromGroup(g, hidden);
  }
  return hidden;
}();

FoodPickGroup? foodGroupForListFood(String listFoodId) =>
    _groupByListId[listFoodId];

FoodPickGroup? foodGroupForVariantFood(String foodId) =>
    _groupByVariantId[foodId];

bool isFoodHiddenFromSearch(String foodId) =>
    _hiddenFromSearchIds.contains(foodId);

/// Rows shown in the food log browser (one per dish family).
List<FoodBrowseRow> foodsForFoodLogBrowse() {
  final rows = <FoodBrowseRow>[];
  final seenGroups = <String>{};

  for (final f in foodDatabase) {
    if (isFoodHiddenFromSearch(f.id)) continue;

    final group = foodGroupForListFood(f.id);
    if (group != null) {
      if (seenGroups.add(group.id)) {
        rows.add(FoodBrowseRow(group: group, displayFood: f));
      }
      continue;
    }

    if (foodGroupForVariantFood(f.id) != null) continue;

    rows.add(FoodBrowseRow(displayFood: f));
  }
  return rows;
}

class FoodBrowseRow {
  final FoodItem displayFood;
  final FoodPickGroup? group;

  const FoodBrowseRow({required this.displayFood, this.group});

  String nameForLang(String lang) {
    if (group != null) {
      final t = group!.titleForLang(lang);
      if (t.isNotEmpty) return t;
    }
    return displayFood.getLocalizedName(lang);
  }

  bool matchesQuery(String query) {
    final nq = normalizeForFoodSearch(query);
    if (nq.isEmpty) return true;
    if (foodSearchFieldMatches(nameForLang('en'), nq) ||
        foodSearchFieldMatches(nameForLang('ar'), nq) ||
        foodSearchFieldMatches(nameForLang('ku'), nq)) {
      return true;
    }
    if (group != null) {
      for (final o in group!.options) {
        final food = foodById(o.foodId);
        if (food != null && food.matchesSearchQuery(query)) return true;
      }
    }
    return displayFood.matchesSearchQuery(query);
  }
}

bool foodBrowseRowMatchesCategory(FoodBrowseRow row, String? category) {
  if (category == null) return true;
  return row.displayFood.category == category;
}
