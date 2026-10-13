import 'package:nutrify/constants/shla_no_oil_variants.dart';
import 'package:nutrify/models/food_item.dart';

const String _s100En = '100g';
const String _s100Ku = '100 گرام';
const String _s100Ar = '100 غرام';

const double _friedKcal = 18;
const double _friedFat = 2;
const double _stewKcal = 8;
const double _stewFat = 0.5;

/// Boiled-row macros for shla (with-oil id → no-oil id).
const Map<String, ({String en, String? ar, String? ku, double cal, double pro, double carb, double fat})>
    shlaDishMeta = {
  'shl_fasolia_100g': (
    en: 'Bean shla / fasolia',
    ar: 'شوربة فاصوليا',
    ku: 'شلەی فاسۆلیا',
    cal: 150, pro: 7, carb: 17, fat: 6,
  ),
  'shl_kolk_kurdi_100g': (
    en: 'Kurdish zucchini shla',
    ar: 'شوربة كوسا كردية',
    ku: 'شلە کولەکە کوردی',
    cal: 65, pro: 2, carb: 7, fat: 4,
  ),
  'shl_fish_broth_100g': (
    en: 'Fish shla',
    ar: 'شوربة سمك',
    ku: 'شلەی ماسی',
    cal: 51, pro: 4, carb: 2, fat: 3,
  ),
  'shl_eggplant_100g': (
    en: 'Eggplant shla',
    ar: 'شوربة باذنجان',
    ku: 'شلەی بادنجان',
    cal: 100, pro: 1, carb: 6, fat: 8,
  ),
  'shl_okra_100g': (
    en: 'Okra shla',
    ar: 'شوربة بامية',
    ku: 'شلەی بامیە',
    cal: 60, pro: 1, carb: 7, fat: 3,
  ),
  'shl_rice_yogurt_100g': (
    en: 'Rice & yogurt shla',
    ar: 'شوربة أرز ولبن',
    ku: 'شلەی برنج و ماست',
    cal: 67, pro: 3, carb: 7, fat: 3,
  ),
  'shl_savar_chicken_100g': (
    en: 'Savar shla with chicken',
    ar: 'شوربة ساور بدجاج',
    ku: 'شلەی ساوەر بە مریشک',
    cal: 112, pro: 10, carb: 11, fat: 3,
  ),
  'shl_okra_meat_100g': (
    en: 'Okra shla with meat',
    ar: 'شوربة بامية باللحم',
    ku: 'شلەی بامیە بە گۆشت',
    cal: 114, pro: 7, carb: 8, fat: 6,
  ),
  'shl_chicken_broccoli_100g': (
    en: 'Chicken & broccoli shla',
    ar: 'شوربة دجاج وبروكلي',
    ku: 'شلەی مریشک بە بڕۆکلی',
    cal: 64, pro: 4, carb: 5, fat: 3,
  ),
  'shl_kufta_meat_100g': (
    en: 'Kufta meat soup',
    ar: 'شوربة كفتة بلحم',
    ku: 'شلەی کفتە بە گۆشت',
    cal: 215, pro: 15, carb: 14, fat: 11,
  ),
  'shl_paqla_100g': (
    en: 'Chickpea shla',
    ar: 'شوربة حمص',
    ku: 'شلەی نۆک',
    cal: 94, pro: 6, carb: 13, fat: 2,
  ),
};

FoodItem _shlaRow({
  required String id,
  required String nameEn,
  String? nameAr,
  String? nameKu,
  required double cal,
  required double pro,
  required double carb,
  required double fat,
}) {
  return FoodItem(
    id: id,
    name: '$nameEn (100g)',
    nameAr: nameAr != null ? '$nameAr (100 غرام)' : null,
    nameKu: nameKu != null ? '$nameKu (100 گرام)' : null,
    calories: cal,
    protein: pro,
    carbs: carb,
    fat: fat,
    category: 'Soup',
    nutritionReferenceG: 100,
    servingLabelEn: _s100En,
    servingLabelKu: _s100Ku,
    servingLabelAr: _s100Ar,
  );
}

List<FoodItem> buildShlaOilPrepVariantRows() {
  final rows = <FoodItem>[];
  for (final entry in shlaNoOilPairIds.entries) {
    final withOilId = entry.key;
    final meta = shlaDishMeta[withOilId];
    if (meta == null) continue;

    final baseSlug = withOilId.replaceAll('_100g', '');
    final noOilBoiled = shlaNoOilVariants.firstWhere((f) => f.id == entry.value);

    // With oil — boiled (canonical row lives in shlaFoodsUser), fried, stewed
    rows.add(_shlaRow(
      id: '${baseSlug}_fried_100g',
      nameEn: '${meta.en}, fried',
      nameAr: meta.ar != null ? '${meta.ar} مقلي' : null,
      nameKu: meta.ku != null ? '${meta.ku} (سوراو)' : null,
      cal: meta.cal + _friedKcal,
      pro: meta.pro,
      carb: meta.carb,
      fat: meta.fat + _friedFat,
    ));
    rows.add(_shlaRow(
      id: '${baseSlug}_stewed_100g',
      nameEn: '${meta.en}, stewed',
      nameAr: meta.ar != null ? '${meta.ar} مطبوخ' : null,
      nameKu: meta.ku != null ? '${meta.ku} (لێنراو)' : null,
      cal: meta.cal + _stewKcal,
      pro: meta.pro,
      carb: meta.carb,
      fat: meta.fat + _stewFat,
    ));

    // No oil — fried, stewed (boiled = existing no_oil row)
    final noSlug = entry.value.replaceAll('_100g', '');
    rows.add(_shlaRow(
      id: '${noSlug}_fried_100g',
      nameEn: '${meta.en}, no oil, fried',
      nameAr: meta.ar != null ? '${meta.ar} بدون زيت مقلي' : null,
      nameKu: meta.ku != null ? '${meta.ku} (بێ ڕۆن، سوراو)' : null,
      cal: noOilBoiled.calories + _friedKcal,
      pro: noOilBoiled.protein,
      carb: noOilBoiled.carbs,
      fat: noOilBoiled.fat + _friedFat,
    ));
    rows.add(_shlaRow(
      id: '${noSlug}_stewed_100g',
      nameEn: '${meta.en}, no oil, stewed',
      nameAr: meta.ar != null ? '${meta.ar} بدون زيت مطبوخ' : null,
      nameKu: meta.ku != null ? '${meta.ku} (بێ ڕۆن، لێنراو)' : null,
      cal: noOilBoiled.calories + _stewKcal,
      pro: noOilBoiled.protein,
      carb: noOilBoiled.carbs,
      fat: noOilBoiled.fat + _stewFat,
    ));
  }
  return rows;
}

/// Tarkhina + paqla fried rows (boiled/raw rows exist elsewhere).
const List<FoodItem> legumeOilPrepExtraVariants = [
  FoodItem(
    id: 'kuu_tarkhina_fried_100g',
    name: 'Tarkhina (100g, fried)',
    nameAr: 'ترخينة مقلية',
    nameKu: 'تڕخێنە (100 گرام، سوراو)',
    calories: 135, protein: 5, carbs: 15, fat: 3,
    category: 'Soup', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_tarkhina_no_oil_fried_100g',
    name: 'Tarkhina (100g, no oil, fried)',
    nameAr: 'ترخينة بدون زيت مقلية',
    nameKu: 'تڕخێنە (100 گرام، بێ ڕۆن، سوراو)',
    calories: 108, protein: 5, carbs: 15, fat: 0.5,
    category: 'Soup', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_tarkhina_stewed_100g',
    name: 'Tarkhina (100g, stewed)',
    nameAr: 'ترخينة مطبوخة',
    nameKu: 'تڕخێنە (100 گرام، لێنراو)',
    calories: 125, protein: 5, carbs: 15, fat: 3.5,
    category: 'Soup', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_tarkhina_no_oil_stewed_100g',
    name: 'Tarkhina (100g, no oil, stewed)',
    nameAr: 'ترخينة بدون زيت مطبوخة',
    nameKu: 'تڕخێنە (100 گرام، بێ ڕۆن، لێنراو)',
    calories: 98, protein: 5, carbs: 15, fat: 0.5,
    category: 'Soup', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_paqla_raw_fried_no_oil_100g',
    name: 'Broad Beans (raw, fried, no oil)',
    nameAr: 'فول أخضر نيء مقلي بدون زيت',
    nameKu: 'پاقلە (خاو، سوراو، بێ ڕۆن)',
    calories: 128, protein: 8, carbs: 19, fat: 3,
    category: 'Legumes', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_paqla_raw_fried_with_oil_100g',
    name: 'Broad Beans (raw, fried, with oil)',
    nameAr: 'فول أخضر نيء مقلي بالزيت',
    nameKu: 'پاقلە (خاو، سوراو، بە ڕۆن)',
    calories: 155, protein: 8, carbs: 19, fat: 6,
    category: 'Legumes', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_paqla_boiled_fried_no_oil_100g',
    name: 'Broad Beans (boiled, fried, no oil)',
    nameAr: 'فول أخضر مسلوق مقلي بدون زيت',
    nameKu: 'پاقلە (کوڵاو، سوراو، بێ ڕۆن)',
    calories: 128, protein: 8, carbs: 19, fat: 2.4,
    category: 'Legumes', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
  FoodItem(
    id: 'kuu_paqla_boiled_fried_with_oil_100g',
    name: 'Broad Beans (boiled, fried, with oil)',
    nameAr: 'فول أخضر مسلوق مقلي بالزيت',
    nameKu: 'پاقلە (کوڵاو، سوراو، بە ڕۆن)',
    calories: 155, protein: 8, carbs: 19, fat: 5.4,
    category: 'Legumes', nutritionReferenceG: 100,
    servingLabelEn: _s100En, servingLabelKu: _s100Ku, servingLabelAr: _s100Ar,
  ),
];
