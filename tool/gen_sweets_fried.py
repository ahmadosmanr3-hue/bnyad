# Generates lib/constants/kurdish_sweets_fried_user.dart
from pathlib import Path

def ref(k100, ku):
    return round(100 * ku / k100, 2) if k100 else 100

foods = [
  ('mahla_bee', 'Mahla bee', 'مەحە لە بی', 4,23,4,144, [('cup','بە کووپ',7,46,8,284)]),
  ('tralicha', 'Tralicha', 'ترالیچا', 6,39,12,288, [('pc','بە پارچە',8,46,14,342)]),
  ('khoshkhosh', 'Khoshkhosh', 'خش خش', 6,55,24,460, [('spoon','بە کەوچک',1,10,4,80),('pc','بە پارچە',7,66,29,553)]),
  ('crepe_plain', 'Plain crepe', 'کریپ سادە', 10,44,15,355, [('pc','بە دانە',6,27,9,213)]),
  ('crepe_nutella', 'Nutella crepe', 'کریپ نوتیلا', 8,48,21,413, [('pc','بە دانە',6,38,15,320)]),
  ('crepe_banana', 'Banana crepe', 'کریپ مۆز', 5,36,12,268, [('pc','بە دانە',9,64,22,490)]),
  ('cake_cream', 'Cream cake', 'کیک بە کریم', 5,52,16,372, [('pc','بە پارچە',4,42,13,302)]),
  ('quraw', 'Quraw', 'قوڕاو', 9,5,12,173, [('spoon','بە کەوچک',1,1,2,26),('bowl','بە قاپ',30,16,44,580)]),
  ('cream_rice', 'Cream rice', 'کریمی برنج', 7,80,1,357, [('spoon','بە کەوچک',1,8,0,36)]),
  ('kulira_cabbage', 'Kulira with cabbage', 'کولیرە بە کونجی', 10,46,20,405, [('pc','بە دانە',18,81,35,712)]),
  ('kulira_oil', 'Kulira with oil', 'کولیرە بە ڕۆن', 9,50,15,372, [('pc','بە دانە',13,75,23,560)]),
  ('kulira_cheese', 'Kulira with cheese', 'کولیرە بە پەنیر', 14,39,16,357, [('pc','بە دانە',25,77,31,687)]),
  ('kulira_qeema', 'Kulira with qeema', 'کولیرە بە گۆشت قیمە', 12,38,16,344, [('pc','بە دانە',24,75,32,685)]),
  ('kulira_mcm', 'Kulira meat cheese mushroom', 'کولیرە بە گۆشت پەنیر موشکەڵ', 16,31,18,350, [('pc','بە دانە',37,73,43,828)]),
  ('kulicha', 'Kulicha', 'کولیچە', 7,45,24,425, [('pc','بە دانە',1,9,5,85)]),
  ('kulicha_walnut', 'Kulicha walnut', 'کولیچە بە گویز هندی', 7,53,28,492, [('pc','بە دانە',1,11,6,102)]),
  ('kulicha_date', 'Kulicha date', 'کولیچە بە خورما', 7,57,24,472, [('pc','بە دانە',1,10,4,80)]),
  ('kulicha_pistachio', 'Kulicha pistachio', 'کولیچە بە فستەق', 9,50,30,506, [('pc','بە دانە',2,10,6,102)]),
  ('choc_cake', 'Chocolate cake', 'کیک شکولاتە', 6,52,14,360, [('pc','بە پارچە',6,52,14,360)]),
  ('rizo', 'Rizo', 'ڕیزۆ', 7,23,7,183, [('bowl','بە قاپ',26,87,25,677)]),
  ('rizo_sauce', 'Rizo with sauce', 'ڕیزۆ بە ساس تیکەڵ', 7,23,7,185, [('bowl','بە قاپ',27,97,30,766)]),
  ('rizo_sauce_cheese', 'Rizo sauce cheese', 'ڕیزۆ بە ساس و پەنیر', 8,22,9,202, [('bowl','بە قاپ',31,91,39,840)]),
  ('kentaki_breast_fried', 'Fried chicken breast kentaki', 'کنتاکی سنگی مریشک لە ناو ڕۆن', 22,12,13,253, [('pc','بە دانە',10,5,6,115)]),
  ('kentaki_breast_air', 'Air-fried chicken breast', 'کنتاکی سنگی مریشک بە هەوا', 22,12,5,181, [('pc','بە دانە',10,5,2,78)]),
  ('kentaki_thigh', 'Kentaki chicken thigh', 'کنتاکی ڕانی پانی مریشک', 16,11,17,262, [('pc','بە دانە',29,20,31,475)]),
  ('kentaki_wing_boneless', 'Boneless chicken wing kentaki', 'کنتاکی باڵی مریشک بێ ئیسک', 26,9,19,312, [('pc','بە دانە',11,4,8,135)]),
  ('kentaki_drumstick', 'Kentaki drumstick', 'کنتاکی ڕانی درێژ مریشک', 25,9,19,310, [('pc','بە دانە',20,7,14,235)]),
  ('kentaki_fingers', 'Kentaki in finger sauce', 'کنتاکی مریشک لە ناو فنگەر سۆس', 10,21,15,260, []),
  ('fish_kentaki', 'Fried fish kentaki', 'ماسی کنتاکی', 15,18,15,268, [('pc','بە دانە',21,25,21,375)]),
  ('fig_fresh', 'Fresh fig (Kurdish)', 'هەنجیر', 1,19,0,80, [('pc','بە دانە',0,9,0,36)]),
  ('fig_dried', 'Dried fig (Kurdish)', 'هەنجیری وشکراو', 3,64,1,277, [('pc','بە دانە',0,8,0,32)]),
  ('lamb_breast_boiled', 'Boiled lamb breast', 'کەڵە شیر کوڵاو', 31,0,6,178, []),
  ('chicken_whole_boiled', 'Boiled whole chicken', 'مریشک تەواو کوڵاو', 26,0,6,162, [('whole','یە دانە تەواو',175,0,42,1086)]),
  ('duck_raw_lean', 'Raw lean duck', 'گۆشتی قاز بێ ئیسک بێ ڕۆن خاو', 17,0,28,320, []),
  ('duck_boiled_lean', 'Boiled lean duck', 'گۆشتی قاز کوڵاو بێ ئیسک بێ ڕۆن', 21,0,35,399, []),
  ('duck_boiled_bone', 'Boiled duck with bone', 'گۆشتی قاز بە ئیسک کوڵاو بێ ڕۆن', 14,0,23,265, []),
  ('duck_boiled_oil', 'Boiled duck with oil', 'گۆشتی قاز کوڵاو بێ ئیسک بە ڕۆن', 21,0,38,430, []),
  ('goose_boiled_oil', 'Boiled goose with oil', 'گۆشتی قار کوڵاو بێ ئیسک بە ڕۆن', 14,0,26,290, []),
  ('duck_egg', 'Duck egg', 'هیلکەی قاز', 14,1,13,177, [('pc','بە دانە',20,2,20,270)]),
  ('parde_plaw', 'Parde plaw', 'پردە پڵاو', 10,22,11,225, [('bowl','بە قاپ',34,76,37,780)]),
  ('cucumber_raw', 'Raw cucumber', 'قنگر بە خاوی', 2,6,0,32, [('pc','بە دانە',0.3,2,0,6)]),
  ('cucumber_fried', 'Fried cucumber', 'قنگر سورکراو لە ناو ڕۆن', 2,6,15,170, [('pc','بە دانە',0.5,2,3,37)]),
  ('wheat_white', 'White cracked wheat', 'گەنمە کوتاو سپی', 5,32,2,166, [('spoon','بە کەوچک',1,5,0,24),('bowl','بە قاپ',9,58,4,305)]),
  ('wheat_red', 'Red cracked wheat', 'گەنمە کوتاو سور', 6,38,2,195, [('spoon','بە کەوچک',1,6,0,28),('bowl','بە قاپ',11,69,4,358)]),
  ('qawarma', 'Qawarma', 'قاورمە', 9,27,4,180, []),
  ('rice_soup', 'Rice soup', 'شۆربای برنج', 2,10,3,75, [('bowl','بە قاپ',4,22,5,149)]),
]

label_map = {
  'pc': ('_s1pcEn', '_s1pcKu', '_s1pcAr'),
  'bowl': ('_sBowlEn', '_sBowlKu', '_sBowlAr'),
  'spoon': ('_sSpoonEn', '_sSpoonKu', '_sSpoonAr'),
  'cup': ('_sCupEn', '_sCupKu', '_sCupAr'),
  'whole': ('_sWholeEn', '_sWholeKu', '_sWholeAr'),
}

header = '''import 'package:nutrify/models/food_item.dart';

/// Sweets, fried foods, kentaki, rizo — user Sorani macros.
double _ref(double kcal100, double kcalUnit) => 100 * kcalUnit / kcal100;

const String _s100En = '100g';
const String _s100Ku = '100 گرام';
const String _s100Ar = '100 غرام';
const String _s1pcEn = '1 piece';
const String _s1pcKu = '١ دانە';
const String _s1pcAr = 'قطعة واحدة';
const String _sBowlEn = '1 bowl';
const String _sBowlKu = '١ قاپ';
const String _sBowlAr = 'وعاء واحد';
const String _sSpoonEn = '1 small spoon';
const String _sSpoonKu = '١ کەوچک';
const String _sSpoonAr = 'ملعقة صغيرة';
const String _sCupEn = '1 cup';
const String _sCupKu = '١ کوپ';
const String _sCupAr = 'كوب واحد';
const String _sWholeEn = '1 whole';
const String _sWholeKu = 'یە دانە تەواو';
const String _sWholeAr = 'كامل';

const List<FoodItem> kurdishSweetsFriedFoodsUser = [
'''

lines = [header]
for slug, en, ku, p, c, f, kcal, variants in foods:
    lines.append(
        f"  FoodItem(id: 'kuu_sf_{slug}_100g', name: '{en} (100g)', "
        f"nameKu: '{ku} (100 گرام)', calories: {kcal}, protein: {p}, carbs: {c}, fat: {f}, "
        f"category: 'Kurdish', nutritionReferenceG: 100, servingLabelEn: _s100En, "
        f"servingLabelKu: _s100Ku, servingLabelAr: _s100Ar),"
    )
lines.append('];\n')
lines.append('const List<FoodItem> kurdishSweetsFriedServingVariants = [\n')
for slug, en, ku, p, c, f, kcal, variants in foods:
    for vtype, vku, vp, vc, vf, vk in variants:
        rid = vtype
        le, lku, lar = label_map[vtype]
        rg = ref(kcal, vk)
        lines.append(
            f"  FoodItem(id: 'kuu_sf_{slug}_{rid}', name: '{en}', nameKu: '{ku} ({vku})', "
            f"calories: {vk}, protein: {vp}, carbs: {vc}, fat: {vf}, category: 'Kurdish', "
            f"nutritionReferenceG: {rg}, servingLabelEn: {le}, servingLabelKu: {lku}, "
            f"servingLabelAr: {lar}),"
        )
lines.append('];\n')

# serving switch mappings
lines.append('const Map<String, String> kurdishSweetsFriedIdToGramsCanonical = {\n')
for slug, *_ in foods:
    base = f"kuu_sf_{slug}_100g"
    for vtype, *_ in foods[[f[0] for f in foods].index(slug)][7]:
        lines.append(f"  'kuu_sf_{slug}_{vtype}': '{base}',")
lines.append('};\n')

out = Path('lib/constants/kurdish_sweets_fried_user.dart')
out.write_text('\n'.join(lines), encoding='utf-8')
print(f'Wrote {out} ({len(lines)} lines)')
