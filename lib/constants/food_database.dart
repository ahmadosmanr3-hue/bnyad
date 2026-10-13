import 'package:nutrify/constants/bakery_foods_list.dart';
import 'package:nutrify/constants/food_prep_variants.dart';
import 'package:nutrify/constants/kurdish_beverages_user.dart';
import 'package:nutrify/constants/kurdish_foods_user.dart';
import 'package:nutrify/constants/kurdish_plates_snacks_user.dart';
import 'package:nutrify/constants/kurdish_sweets_fried_user.dart';
import 'package:nutrify/constants/food_oil_prep_variants.dart';
import 'package:nutrify/constants/protein_supplements_list.dart';
import 'package:nutrify/constants/fast_foods_list.dart';
import 'package:nutrify/constants/shla_foods_list.dart';
import 'package:nutrify/constants/shla_no_oil_variants.dart';
import 'package:nutrify/models/food_item.dart';

/// Micronutrient keys: vitA(mcg), vitC(mg), vitD(mcg), vitB12(mcg), iron(mg), calcium(mg), potassium(mg), zinc(mg)
/// All nutritional values are per 100g.
final List<FoodItem> foodDatabase = [
  // ─── Kurdish / Iraqi Foods ────────────────────────────
  FoodItem(id: 'k1', name: 'Dolma (Kurdish)', nameAr: 'دولمة كوردية', nameKu: 'دۆڵمەی کوردی', calories: 150, protein: 5, carbs: 22, fat: 6, category: 'Kurdish', micros: {'vitA': 40, 'vitC': 8, 'iron': 1.5, 'calcium': 35, 'potassium': 200, 'zinc': 0.8}),
  FoodItem(id: 'k2', name: 'Kurdish Biryani', nameAr: 'برياني كوردي', nameKu: 'بریانی کوردی', calories: 210, protein: 10, carbs: 30, fat: 6, category: 'RiceDishes', micros: {'vitA': 5, 'vitC': 1, 'iron': 1.2, 'calcium': 20, 'potassium': 150, 'zinc': 1.5}),
  FoodItem(id: 'k3', name: 'Kubba', nameAr: 'كبة', nameKu: 'کوبە', calories: 220, protein: 12, carbs: 28, fat: 8, category: 'Kurdish', micros: {'vitA': 8, 'vitB12': 1.0, 'iron': 2.2, 'calcium': 20, 'potassium': 180, 'zinc': 2.5}),
  FoodItem(id: 'k4', name: 'Tashreeb', nameAr: 'تشريب', nameKu: 'تەشرێب', calories: 250, protein: 18, carbs: 15, fat: 12, category: 'Kurdish', micros: {'vitA': 15, 'vitB12': 1.8, 'iron': 2.0, 'calcium': 30, 'potassium': 250, 'zinc': 3.0}),
  // Naan / Kurdish flatbread — per 100g (typical tandoor-style naan; log by g or by piece).
  FoodItem(id: 'k5', name: 'Kurdish Naan (flatbread)', nameAr: 'خبز نان كوردي', nameKu: 'نانی کوردی (نان)', calories: 293, protein: 9.6, carbs: 50, fat: 5.5, category: 'Bread', micros: {'iron': 2.4, 'calcium': 45, 'potassium': 105, 'zinc': 0.85}),
  FoodItem(id: 'k6', name: 'Tepsi Baytinijan', nameAr: 'تبسي باذنجان', nameKu: 'تەپسی باتنجان', calories: 130, protein: 4, carbs: 12, fat: 8, category: 'Kurdish', micros: {'vitA': 25, 'vitC': 6, 'iron': 0.8, 'calcium': 18, 'potassium': 230, 'zinc': 0.5}),
  FoodItem(id: 'k7', name: 'Parcha (Trotter Soup)', nameAr: 'باجة', nameKu: 'پاچە', calories: 200, protein: 22, carbs: 2, fat: 12, category: 'Soup', micros: {'vitB12': 2.5, 'iron': 2.8, 'calcium': 60, 'potassium': 150, 'zinc': 4.0}),
  FoodItem(id: 'k8', name: 'Qeema', nameAr: 'قيمة', nameKu: 'قیمە', calories: 180, protein: 14, carbs: 10, fat: 10, category: 'Kurdish', micros: {'vitA': 20, 'vitC': 10, 'vitB12': 1.5, 'iron': 2.5, 'calcium': 25, 'potassium': 300, 'zinc': 3.2}),
  FoodItem(id: 'k9', name: 'Fasolia (Bean Stew)', nameAr: 'فاصوليا', nameKu: 'فاسولیا', calories: 140, protein: 8, carbs: 20, fat: 4, category: 'Kurdish', micros: {'vitA': 15, 'vitC': 12, 'iron': 2.2, 'calcium': 50, 'potassium': 400, 'zinc': 1.0}),
  FoodItem(id: 'k10', name: 'Bamya (Okra Stew)', nameAr: 'بامية', nameKu: 'بامیە', calories: 120, protein: 6, carbs: 14, fat: 5, category: 'Kurdish', micros: {'vitA': 36, 'vitC': 23, 'iron': 1.0, 'calcium': 80, 'potassium': 300, 'zinc': 0.6}),
  FoodItem(id: 'k12', name: 'Shorba (Lentil)', nameAr: 'شوربة عدس', nameKu: 'شۆربای نیسک', calories: 116, protein: 9, carbs: 20, fat: 0.4, category: 'Soup', micros: {'vitA': 8, 'vitC': 3, 'iron': 3.3, 'calcium': 19, 'potassium': 370, 'zinc': 1.3}),
  FoodItem(id: 'k13', name: 'Yaprax', nameAr: 'يبرق', nameKu: 'یەپراخ', calories: 160, protein: 6, carbs: 20, fat: 7, category: 'Kurdish', micros: {'vitA': 50, 'vitC': 10, 'iron': 1.8, 'calcium': 40, 'potassium': 220, 'zinc': 0.9}),
  FoodItem(id: 'k14', name: 'Kuba Halab', nameAr: 'كبة حلب', nameKu: 'کوبەی حەلەب', calories: 230, protein: 10, carbs: 25, fat: 10, category: 'Kurdish', micros: {'vitB12': 0.8, 'iron': 2.0, 'calcium': 25, 'potassium': 170, 'zinc': 2.0}),

  // ─── Arabic / Middle Eastern ─────────────────────────
  FoodItem(id: 'a1', name: 'Hummus', nameAr: 'حمص', nameKu: 'حومس', calories: 166, protein: 8, carbs: 14, fat: 10, category: 'Arabic', micros: {'vitA': 6, 'vitC': 8, 'iron': 2.4, 'calcium': 49, 'potassium': 228, 'zinc': 1.8}),
  FoodItem(id: 'a2', name: 'Falafel', nameAr: 'فلافل', nameKu: 'فەلافل', calories: 333, protein: 13, carbs: 32, fat: 18, category: 'Arabic', micros: {'vitC': 4, 'iron': 3.4, 'calcium': 54, 'potassium': 585, 'zinc': 1.5}),
  FoodItem(id: 'a3', name: 'Shawarma (Chicken)', nameAr: 'شاورما دجاج', nameKu: 'شاوەرمەی مریشک', calories: 230, protein: 20, carbs: 10, fat: 12, category: 'Arabic', micros: {'vitA': 15, 'vitB12': 0.3, 'iron': 1.2, 'calcium': 20, 'potassium': 220, 'zinc': 1.8}),
  FoodItem(id: 'a4', name: 'Mansaf', nameAr: 'منسف', nameKu: 'مەنسەف', calories: 350, protein: 25, carbs: 40, fat: 15, category: 'Arabic', micros: {'vitA': 20, 'vitB12': 2.0, 'iron': 2.0, 'calcium': 80, 'potassium': 300, 'zinc': 4.0}),
  FoodItem(id: 'a5', name: 'Tabbouleh', nameAr: 'تبولة', nameKu: 'تەبولە', calories: 100, protein: 2.6, carbs: 9, fat: 6, category: 'Arabic', micros: {'vitA': 90, 'vitC': 30, 'iron': 2.0, 'calcium': 35, 'potassium': 250, 'zinc': 0.4}),
  FoodItem(id: 'a6', name: 'Fattoush', nameAr: 'فتوش', nameKu: 'فەتووش', calories: 100, protein: 2, carbs: 12, fat: 5, category: 'Arabic', micros: {'vitA': 80, 'vitC': 25, 'iron': 1.0, 'calcium': 30, 'potassium': 200, 'zinc': 0.3}),
  FoodItem(id: 'a7', name: 'Baba Ganoush', nameAr: 'بابا غنوج', nameKu: 'بابا غەنوج', calories: 80, protein: 2, carbs: 8, fat: 5, category: 'Arabic', micros: {'vitC': 5, 'iron': 0.6, 'calcium': 15, 'potassium': 180, 'zinc': 0.4}),
  FoodItem(id: 'a8', name: 'Labneh', nameAr: 'لبنة', nameKu: 'لەبنە', calories: 150, protein: 8, carbs: 4, fat: 11, category: 'Arabic', micros: {'vitA': 80, 'vitB12': 0.8, 'calcium': 180, 'potassium': 150, 'zinc': 0.8}),
  FoodItem(id: 'a9', name: 'Kibbeh', nameAr: 'كبة', nameKu: 'کوبە', calories: 240, protein: 14, carbs: 18, fat: 12, category: 'Arabic', micros: {'vitB12': 1.5, 'iron': 2.5, 'calcium': 25, 'potassium': 200, 'zinc': 3.5}),
  FoodItem(id: 'a10', name: 'Musakhan', nameAr: 'مسخن', nameKu: 'موسەخەن', calories: 280, protein: 18, carbs: 25, fat: 12, category: 'Arabic', micros: {'vitA': 10, 'vitC': 5, 'iron': 1.5, 'calcium': 25, 'potassium': 250, 'zinc': 2.0}),
  FoodItem(id: 'a11', name: 'Koshari', nameAr: 'كشري', nameKu: 'کوشەری', calories: 160, protein: 5, carbs: 30, fat: 3, category: 'Arabic', micros: {'vitC': 5, 'iron': 2.0, 'calcium': 20, 'potassium': 150, 'zinc': 0.8}),
  FoodItem(id: 'a12', name: 'Ful Medames', nameAr: 'فول مدمس', nameKu: 'فوول', calories: 110, protein: 8, carbs: 15, fat: 2, category: 'Arabic', micros: {'vitC': 2, 'iron': 2.5, 'calcium': 36, 'potassium': 420, 'zinc': 1.0}),
  FoodItem(id: 'a13', name: 'Sambousek', nameAr: 'سمبوسك', nameKu: 'سەمبووسەک', calories: 260, protein: 8, carbs: 22, fat: 16, category: 'Arabic', micros: {'iron': 1.2, 'calcium': 15, 'potassium': 100, 'zinc': 0.8}),
  FoodItem(id: 'a14', name: 'Mahshi (Stuffed Zucchini)', nameAr: 'محشي كوسا', nameKu: 'مەحشی کوسە', calories: 140, protein: 5, carbs: 18, fat: 6, category: 'Arabic', micros: {'vitA': 30, 'vitC': 12, 'iron': 1.2, 'calcium': 25, 'potassium': 260, 'zinc': 0.7}),
  FoodItem(id: 'a15', name: 'Kunafeh', nameAr: 'كنافة', nameKu: 'کونافە', calories: 380, protein: 6, carbs: 45, fat: 20, category: 'Arabic', micros: {'vitA': 40, 'calcium': 100, 'potassium': 80, 'zinc': 0.5}),

  // ─── Proteins ─────────────────────────────────────────
  FoodItem(id: 'p1', name: 'Grilled Chicken Breast', nameAr: 'صدر دجاج مشوي', nameKu: 'سنگی مریشکی برژاو', calories: 165, protein: 31, carbs: 0, fat: 3.6, category: 'Protein', micros: {'vitA': 6, 'vitB12': 0.3, 'vitD': 0.4, 'iron': 1.0, 'calcium': 15, 'potassium': 256, 'zinc': 1.0}),
  FoodItem(id: 'p2', name: 'Salmon Fillet', nameAr: 'فيليه سلمون', nameKu: 'فیلەی سەلمۆن', calories: 208, protein: 20, carbs: 0, fat: 13, category: 'Protein', micros: {'vitA': 12, 'vitB12': 3.2, 'vitD': 11.0, 'iron': 0.8, 'calcium': 12, 'potassium': 363, 'zinc': 0.6}),
  FoodItem(id: 'p3', name: 'Beef Steak', nameAr: 'ستيك لحم بقري', nameKu: 'ستیکی گۆشتی مانگا', calories: 250, protein: 26, carbs: 0, fat: 15, category: 'Protein', micros: {'vitB12': 5.9, 'vitD': 0.1, 'iron': 2.6, 'calcium': 18, 'potassium': 318, 'zinc': 6.3}),
  FoodItem(id: 'p4', name: 'Ground Beef', nameAr: 'لحم مفروم', nameKu: 'گۆشتی هاڕاو', calories: 250, protein: 17, carbs: 0, fat: 20, category: 'Protein', micros: {'vitB12': 2.6, 'iron': 2.2, 'calcium': 12, 'potassium': 270, 'zinc': 4.8}),
  FoodItem(id: 'p5', name: 'Lamb Chop', nameAr: 'ريش غنم', nameKu: 'پارچەی بەرخ', calories: 280, protein: 25, carbs: 0, fat: 20, category: 'Protein', micros: {'vitB12': 2.5, 'iron': 1.9, 'calcium': 17, 'potassium': 310, 'zinc': 4.5}),
  FoodItem(id: 'p6', name: 'Tuna (Canned)', nameAr: 'تونة معلبة', nameKu: 'تونەی کانزەکراو', calories: 130, protein: 28, carbs: 0, fat: 1, category: 'Protein', micros: {'vitB12': 2.2, 'vitD': 2.0, 'iron': 1.3, 'calcium': 11, 'potassium': 237, 'zinc': 0.8}),
  FoodItem(id: 'p7', name: 'Shrimp', nameAr: 'جمبري', nameKu: 'میگۆ', calories: 99, protein: 24, carbs: 0, fat: 0.3, category: 'Protein', micros: {'vitB12': 1.1, 'vitD': 0.5, 'iron': 2.4, 'calcium': 70, 'potassium': 259, 'zinc': 1.6}),
  FoodItem(id: 'p8', name: 'Whole Egg', nameAr: 'بيضة كاملة', nameKu: 'هێلکە', calories: 155, protein: 11, carbs: 1.1, fat: 11, category: 'Protein', micros: {'vitA': 160, 'vitB12': 0.9, 'vitD': 2.0, 'iron': 1.8, 'calcium': 56, 'potassium': 138, 'zinc': 1.3}),
  FoodItem(id: 'p9', name: 'Egg White', nameAr: 'بياض بيضة', nameKu: 'سپێناوی هێلکە', calories: 52, protein: 11, carbs: 0.7, fat: 0.2, category: 'Protein', micros: {'vitB12': 0.1, 'calcium': 7, 'potassium': 163, 'zinc': 0.03}),
  FoodItem(id: 'p10', name: 'Turkey Breast', nameAr: 'صدر ديك رومي', nameKu: 'سنگی قەلەڕەش', calories: 135, protein: 30, carbs: 0, fat: 1, category: 'Protein', micros: {'vitB12': 0.4, 'iron': 1.4, 'calcium': 10, 'potassium': 293, 'zinc': 2.0}),
  FoodItem(id: 'p11', name: 'Chicken Thigh', nameAr: 'فخذ دجاج', nameKu: 'ڕانی مریشک', calories: 210, protein: 26, carbs: 0, fat: 11, category: 'Protein', micros: {'vitA': 20, 'vitB12': 0.3, 'iron': 1.3, 'calcium': 12, 'potassium': 222, 'zinc': 2.4}),
  FoodItem(id: 'p12', name: 'Sardines', nameAr: 'سردين', nameKu: 'ساردین', calories: 208, protein: 25, carbs: 0, fat: 11, category: 'Protein', micros: {'vitB12': 8.9, 'vitD': 4.8, 'iron': 2.9, 'calcium': 382, 'potassium': 397, 'zinc': 1.3}),

  // ─── Dairy ────────────────────────────────────────────
  FoodItem(id: 'd1', name: 'Greek Yogurt', nameAr: 'زبادي يوناني', nameKu: 'ماستی یۆنانی', calories: 59, protein: 10, carbs: 3.6, fat: 0.4, category: 'Dairy', micros: {'vitA': 7, 'vitB12': 0.8, 'calcium': 110, 'potassium': 141, 'zinc': 0.5}),
  FoodItem(id: 'd2', name: 'Whole Milk', nameAr: 'حليب كامل الدسم', nameKu: 'شیری تەواو', calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, category: 'Dairy', micros: {'vitA': 46, 'vitB12': 0.4, 'vitD': 1.3, 'calcium': 113, 'potassium': 132, 'zinc': 0.4}),
  FoodItem(id: 'd3', name: 'Cheddar Cheese', nameAr: 'جبنة شيدر', nameKu: 'پەنیری چیدەر', calories: 403, protein: 25, carbs: 1.3, fat: 33, category: 'Dairy', micros: {'vitA': 265, 'vitB12': 0.8, 'vitD': 0.6, 'calcium': 721, 'potassium': 98, 'zinc': 3.1}),
  FoodItem(id: 'd4', name: 'Cottage Cheese', nameAr: 'جبنة قريش', nameKu: 'پەنیری کۆتیج', calories: 98, protein: 11, carbs: 3.4, fat: 4.3, category: 'Dairy', micros: {'vitA': 37, 'vitB12': 0.4, 'calcium': 83, 'potassium': 104, 'zinc': 0.4}),
  FoodItem(id: 'd5', name: 'Mozzarella', nameAr: 'موزاريلا', nameKu: 'مۆزارێلا', calories: 280, protein: 28, carbs: 3.1, fat: 17, category: 'Dairy', micros: {'vitA': 179, 'vitB12': 2.3, 'calcium': 505, 'potassium': 76, 'zinc': 2.9}),
  FoodItem(id: 'd6', name: 'Butter', nameAr: 'زبدة', nameKu: 'کەرە', calories: 717, protein: 0.9, carbs: 0.1, fat: 81, category: 'Dairy', micros: {'vitA': 684, 'vitD': 1.5, 'calcium': 24, 'potassium': 24}),
  FoodItem(id: 'd7', name: 'Cream Cheese', nameAr: 'جبنة كريمية', nameKu: 'پەنیری کریمی', calories: 342, protein: 6, carbs: 4, fat: 34, category: 'Dairy', micros: {'vitA': 362, 'calcium': 98, 'potassium': 138, 'zinc': 0.5}),
  FoodItem(id: 'd8', name: 'Yogurt (Plain)', nameAr: 'زبادي سادة', nameKu: 'ماست', calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3, category: 'Dairy', micros: {'vitA': 27, 'vitB12': 0.4, 'calcium': 121, 'potassium': 155, 'zinc': 0.6}),

  // ─── Grains & Carbs ──────────────────────────────────
  FoodItem(id: 'g1', name: 'Brown Rice', nameAr: 'أرز بني', nameKu: 'برنجی قاوەیی', calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: 'Grains', micros: {'iron': 0.4, 'calcium': 10, 'potassium': 43, 'zinc': 0.6}),
  FoodItem(id: 'g2', name: 'White Rice', nameAr: 'أرز أبيض', nameKu: 'برنجی سپی', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, category: 'Grains', micros: {'iron': 1.2, 'calcium': 10, 'potassium': 35, 'zinc': 0.5}),
  FoodItem(id: 'g3', name: 'Oatmeal (Cooked)', nameAr: 'شوفان (مطبوخ)', nameKu: 'شۆفان (لێنراو)', calories: 68, protein: 2.4, carbs: 12, fat: 1.4, category: 'Grains', micros: {'iron': 1.6, 'calcium': 9, 'potassium': 61, 'zinc': 1.0}),
  FoodItem(id: 'g4', name: 'Whole Wheat Bread', nameAr: 'خبز قمح كامل', nameKu: 'نانی گەنمی تەواو', calories: 247, protein: 13, carbs: 41, fat: 3.4, category: 'Bread', micros: {'iron': 2.5, 'calcium': 107, 'potassium': 254, 'zinc': 1.8}),
  FoodItem(id: 'g5', name: 'White Bread', nameAr: 'خبز أبيض', nameKu: 'نانی سپی', calories: 265, protein: 9, carbs: 49, fat: 3.2, category: 'Bread', micros: {'iron': 3.6, 'calcium': 151, 'potassium': 115, 'zinc': 0.8}),
  FoodItem(id: 'g6', name: 'Pasta (Cooked)', nameAr: 'معكرونة مسلوقة', nameKu: 'پاستا (لێنراو)', calories: 131, protein: 5, carbs: 25, fat: 1.1, category: 'Grains', micros: {'iron': 1.3, 'calcium': 7, 'potassium': 44, 'zinc': 0.5}),
  FoodItem(id: 'g7', name: 'Quinoa', nameAr: 'كينوا', nameKu: 'کینوا', calories: 120, protein: 4.4, carbs: 21, fat: 1.9, category: 'Grains', micros: {'iron': 1.5, 'calcium': 17, 'potassium': 172, 'zinc': 1.1}),
  FoodItem(id: 'g8', name: 'Sweet Potato', nameAr: 'بطاطا حلوة', nameKu: 'بەتاتەی شیرین', calories: 86, protein: 1.6, carbs: 20, fat: 0.1, category: 'Grains', micros: {'vitA': 709, 'vitC': 2.4, 'iron': 0.6, 'calcium': 30, 'potassium': 337, 'zinc': 0.3}),
  FoodItem(id: 'g9', name: 'Potato (Boiled)', nameAr: 'بطاطس مسلوقة', nameKu: 'بەتاتەی لێنراو', calories: 87, protein: 1.9, carbs: 20, fat: 0.1, category: 'Grains', micros: {'vitC': 13, 'iron': 0.3, 'calcium': 5, 'potassium': 379, 'zinc': 0.3}),
  FoodItem(id: 'g10', name: 'Corn Tortilla', nameAr: 'خبز تورتيلا ذرة', nameKu: 'نانی تۆرتیلای گەنمەشامی', calories: 218, protein: 6, carbs: 44, fat: 3, category: 'Bread', micros: {'iron': 1.5, 'calcium': 46, 'potassium': 140, 'zinc': 0.6}),
  FoodItem(id: 'g11', name: 'Bulgur', nameAr: 'برغل', nameKu: 'بورگل', calories: 83, protein: 3.1, carbs: 19, fat: 0.2, category: 'Grains', micros: {'iron': 1.0, 'calcium': 10, 'potassium': 68, 'zinc': 0.6}),
  FoodItem(id: 'g12', name: 'Couscous', nameAr: 'كسكس', nameKu: 'کوسکوس', calories: 112, protein: 3.8, carbs: 23, fat: 0.2, category: 'Grains', micros: {'iron': 0.4, 'calcium': 8, 'potassium': 58, 'zinc': 0.3}),

  // ─── Fruits ───────────────────────────────────────────
  FoodItem(id: 'f1', name: 'Apple', nameAr: 'تفاحة', nameKu: 'سێو', calories: 52, protein: 0.3, carbs: 14, fat: 0.2, category: 'Fruit', micros: {'vitA': 3, 'vitC': 4.6, 'calcium': 6, 'potassium': 107, 'iron': 0.1}),
  FoodItem(id: 'f2', name: 'Banana', nameAr: 'موز', nameKu: 'مۆز', calories: 89, protein: 1.1, carbs: 23, fat: 0.3, category: 'Fruit', micros: {'vitC': 8.7, 'vitB12': 0, 'iron': 0.3, 'calcium': 5, 'potassium': 358, 'zinc': 0.2}),
  FoodItem(id: 'f3', name: 'Orange', nameAr: 'برتقال', nameKu: 'پرتەقاڵ', calories: 47, protein: 0.9, carbs: 12, fat: 0.1, category: 'Fruit', micros: {'vitA': 11, 'vitC': 53, 'calcium': 40, 'potassium': 181, 'iron': 0.1}),
  FoodItem(id: 'f4', name: 'Strawberry', nameAr: 'فراولة', nameKu: 'تووتەفرەنگی', calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, category: 'Fruit', micros: {'vitC': 59, 'iron': 0.4, 'calcium': 16, 'potassium': 153, 'zinc': 0.1}),
  FoodItem(id: 'f5', name: 'Watermelon', nameAr: 'بطيخ', nameKu: 'شووتی', calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, category: 'Fruit', micros: {'vitA': 28, 'vitC': 8.1, 'calcium': 7, 'potassium': 112}),
  FoodItem(id: 'f6', name: 'Grapes', nameAr: 'عنب', nameKu: 'ترێ', calories: 69, protein: 0.7, carbs: 18, fat: 0.2, category: 'Fruit', micros: {'vitC': 3.2, 'calcium': 10, 'potassium': 191, 'iron': 0.4}),
  FoodItem(id: 'f7', name: 'Mango', nameAr: 'مانجو', nameKu: 'مانگۆ', calories: 60, protein: 0.8, carbs: 15, fat: 0.4, category: 'Fruit', micros: {'vitA': 54, 'vitC': 36, 'calcium': 11, 'potassium': 168, 'iron': 0.2}),
  FoodItem(id: 'f8', name: 'Pomegranate', nameAr: 'رمان', nameKu: 'هەنار', calories: 83, protein: 1.7, carbs: 19, fat: 1.2, category: 'Fruit', micros: {'vitC': 10.2, 'iron': 0.3, 'calcium': 10, 'potassium': 236, 'zinc': 0.4}),
  FoodItem(id: 'f9', name: 'Dates', nameAr: 'تمر', nameKu: 'خورما', calories: 277, protein: 1.8, carbs: 75, fat: 0.2, category: 'Fruit', micros: {'iron': 0.9, 'calcium': 64, 'potassium': 696, 'zinc': 0.4}),
  FoodItem(id: 'f11', name: 'Peach', nameAr: 'خوخ', nameKu: 'قۆخ', calories: 39, protein: 0.9, carbs: 10, fat: 0.3, category: 'Fruit', micros: {'vitA': 16, 'vitC': 6.6, 'calcium': 6, 'potassium': 190, 'iron': 0.3}),
  FoodItem(id: 'f13', name: 'Blueberry', nameAr: 'توت أزرق', nameKu: 'تووتی شین', calories: 57, protein: 0.7, carbs: 14, fat: 0.3, category: 'Fruit', micros: {'vitC': 9.7, 'vitA': 3, 'calcium': 6, 'potassium': 77, 'iron': 0.3}),
  FoodItem(id: 'f14', name: 'Avocado', nameAr: 'أفوكادو', nameKu: 'ئاڤۆکادۆ', calories: 160, protein: 2, carbs: 8.5, fat: 15, category: 'Fruit', micros: {'vitC': 10, 'vitA': 7, 'iron': 0.6, 'calcium': 12, 'potassium': 485, 'zinc': 0.6}),
  FoodItem(id: 'f15', name: 'Pineapple', nameAr: 'أناناس', nameKu: 'ئەناناس', calories: 50, protein: 0.5, carbs: 13, fat: 0.1, category: 'Fruit', micros: {'vitC': 47.8, 'calcium': 13, 'potassium': 109, 'iron': 0.3}),

  // ─── Vegetables ───────────────────────────────────────
  FoodItem(id: 'v1', name: 'Broccoli', nameAr: 'بروكلي', nameKu: 'بروکۆلی', calories: 34, protein: 2.8, carbs: 7, fat: 0.4, category: 'Vegetable', micros: {'vitA': 31, 'vitC': 89, 'calcium': 47, 'potassium': 316, 'iron': 0.7, 'zinc': 0.4}),
  FoodItem(id: 'v2', name: 'Spinach', nameAr: 'سبانخ', nameKu: 'سپیناغ', calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, category: 'Vegetable', micros: {'vitA': 469, 'vitC': 28, 'iron': 2.7, 'calcium': 99, 'potassium': 558, 'zinc': 0.5}),
  FoodItem(id: 'v3', name: 'Tomato', nameAr: 'طماطم', nameKu: 'تەماتە', calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, category: 'Vegetable', micros: {'vitA': 42, 'vitC': 14, 'calcium': 10, 'potassium': 237, 'iron': 0.3}),
  FoodItem(id: 'v4', name: 'Cucumber', nameAr: 'خيار', nameKu: 'خیار', calories: 15, protein: 0.7, carbs: 3.6, fat: 0.1, category: 'Vegetable', micros: {'vitC': 2.8, 'vitA': 5, 'calcium': 16, 'potassium': 147, 'iron': 0.3}),
  FoodItem(id: 'v5', name: 'Carrot', nameAr: 'جزر', nameKu: 'گێزەر', calories: 41, protein: 0.9, carbs: 10, fat: 0.2, category: 'Vegetable', micros: {'vitA': 835, 'vitC': 5.9, 'calcium': 33, 'potassium': 320, 'iron': 0.3}),
  FoodItem(id: 'v6', name: 'Eggplant', nameAr: 'باذنجان', nameKu: 'باتنجان', calories: 25, protein: 1, carbs: 6, fat: 0.2, category: 'Vegetable', micros: {'vitC': 2.2, 'calcium': 9, 'potassium': 229, 'iron': 0.2}),
  FoodItem(id: 'v7', name: 'Onion', nameAr: 'بصل', nameKu: 'پیاز', calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, category: 'Vegetable', micros: {'vitC': 7.4, 'calcium': 23, 'potassium': 146, 'iron': 0.2}),
  FoodItem(id: 'v8', name: 'Bell Pepper', nameAr: 'فلفل حلو', nameKu: 'بیبەری شیرین', calories: 31, protein: 1, carbs: 6, fat: 0.3, category: 'Vegetable', micros: {'vitA': 157, 'vitC': 128, 'calcium': 7, 'potassium': 211, 'iron': 0.4}),
  FoodItem(id: 'v9', name: 'Lettuce', nameAr: 'خس', nameKu: 'کاهوو', calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, category: 'Vegetable', micros: {'vitA': 370, 'vitC': 9.2, 'calcium': 36, 'potassium': 194, 'iron': 0.9}),
  FoodItem(id: 'v10', name: 'Zucchini', nameAr: 'كوسا', nameKu: 'کوسە', calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, category: 'Vegetable', micros: {'vitA': 10, 'vitC': 18, 'calcium': 16, 'potassium': 261, 'iron': 0.4}),
  FoodItem(id: 'v11', name: 'Cauliflower', nameAr: 'قرنبيط', nameKu: 'گوڵەکەلەم', calories: 25, protein: 1.9, carbs: 5, fat: 0.3, category: 'Vegetable', micros: {'vitC': 48, 'calcium': 22, 'potassium': 299, 'iron': 0.4}),
  FoodItem(id: 'v12', name: 'Green Beans', nameAr: 'فاصوليا خضراء', nameKu: 'لووبیای سەوز', calories: 31, protein: 1.8, carbs: 7, fat: 0.2, category: 'Vegetable', micros: {'vitA': 35, 'vitC': 12, 'calcium': 37, 'potassium': 211, 'iron': 1.0}),
  FoodItem(id: 'v13', name: 'Mushroom', nameAr: 'فطر', nameKu: 'کارک', calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, category: 'Vegetable', micros: {'vitD': 0.2, 'iron': 0.5, 'calcium': 3, 'potassium': 318, 'zinc': 0.5}),
  FoodItem(id: 'v14', name: 'Garlic', nameAr: 'ثوم', nameKu: 'سیر', calories: 149, protein: 6.4, carbs: 33, fat: 0.5, category: 'Vegetable', micros: {'vitC': 31, 'vitB12': 0, 'iron': 1.7, 'calcium': 181, 'potassium': 401, 'zinc': 1.2}),

  // ─── Nuts & Seeds ─────────────────────────────────────
  FoodItem(id: 'n1', name: 'Almonds', nameAr: 'لوز', nameKu: 'بادەم', calories: 579, protein: 21, carbs: 22, fat: 50, category: 'Nuts', micros: {'vitA': 0, 'iron': 3.7, 'calcium': 269, 'potassium': 733, 'zinc': 3.1}),
  FoodItem(id: 'n2', name: 'Walnuts', nameAr: 'جوز', nameKu: 'گوێز', calories: 654, protein: 15, carbs: 14, fat: 65, category: 'Nuts', micros: {'iron': 2.9, 'calcium': 98, 'potassium': 441, 'zinc': 3.1}),
  FoodItem(id: 'n3', name: 'Peanuts', nameAr: 'فول سوداني', nameKu: 'فستقی زەوی', calories: 567, protein: 26, carbs: 16, fat: 49, category: 'Nuts', micros: {'iron': 4.6, 'calcium': 92, 'potassium': 705, 'zinc': 3.3}),
  FoodItem(id: 'n4', name: 'Pistachios', nameAr: 'فستق', nameKu: 'فستق', calories: 562, protein: 20, carbs: 28, fat: 45, category: 'Nuts', micros: {'vitA': 26, 'vitC': 5, 'iron': 3.9, 'calcium': 105, 'potassium': 1025, 'zinc': 2.2}),
  FoodItem(id: 'n5', name: 'Cashews', nameAr: 'كاجو', nameKu: 'کاجوو', calories: 553, protein: 18, carbs: 30, fat: 44, category: 'Nuts', micros: {'iron': 6.7, 'calcium': 37, 'potassium': 660, 'zinc': 5.8}),
  FoodItem(id: 'n6', name: 'Sunflower Seeds', nameAr: 'بذور عباد الشمس', nameKu: 'تۆوی گوڵبەرۆژە', calories: 584, protein: 21, carbs: 20, fat: 51, category: 'Nuts', micros: {'iron': 5.3, 'calcium': 78, 'potassium': 645, 'zinc': 5.0}),
  FoodItem(id: 'n7', name: 'Chia Seeds', nameAr: 'بذور الشيا', nameKu: 'تۆوی چیا', calories: 486, protein: 17, carbs: 42, fat: 31, category: 'Nuts', micros: {'vitC': 1.6, 'iron': 7.7, 'calcium': 631, 'potassium': 407, 'zinc': 4.6}),
  FoodItem(id: 'n8', name: 'Flaxseed', nameAr: 'بذور الكتان', nameKu: 'تۆوی کەتان', calories: 534, protein: 18, carbs: 29, fat: 42, category: 'Nuts', micros: {'iron': 5.7, 'calcium': 255, 'potassium': 813, 'zinc': 4.3}),

  // ─── Legumes ──────────────────────────────────────────
  FoodItem(id: 'l1', name: 'Chickpeas (Cooked)', nameAr: 'حمص مسلوق', nameKu: 'نۆکی لێنراو', calories: 164, protein: 9, carbs: 27, fat: 2.6, category: 'Legumes', micros: {'vitC': 1.3, 'iron': 2.9, 'calcium': 49, 'potassium': 291, 'zinc': 1.5}),
  FoodItem(id: 'l2', name: 'Black Beans', nameAr: 'فاصوليا سوداء', nameKu: 'لووبیای ڕەش', calories: 132, protein: 9, carbs: 24, fat: 0.5, category: 'Legumes', micros: {'iron': 2.1, 'calcium': 27, 'potassium': 355, 'zinc': 1.1}),
  FoodItem(id: 'l3', name: 'Red Lentils', nameAr: 'عدس أحمر', nameKu: 'نیسکی سوور', calories: 116, protein: 9, carbs: 20, fat: 0.4, category: 'Legumes', micros: {'iron': 3.3, 'calcium': 19, 'potassium': 369, 'zinc': 1.3}),
  FoodItem(id: 'l4', name: 'Green Peas', nameAr: 'بازلاء', nameKu: 'بزاڵیا', calories: 81, protein: 5, carbs: 14, fat: 0.4, category: 'Legumes', micros: {'vitA': 38, 'vitC': 40, 'iron': 1.5, 'calcium': 25, 'potassium': 244, 'zinc': 1.2}),

  // ─── International / Fast Food ────────────────────────
  FoodItem(id: 'i1', name: 'Pizza Margherita', nameAr: 'بيتزا مارغريتا', nameKu: 'پیتزا مارگریتا', calories: 250, protein: 10, carbs: 30, fat: 10, category: 'International', micros: {'vitA': 60, 'calcium': 180, 'potassium': 170, 'iron': 1.5, 'zinc': 1.2}),
  FoodItem(id: 'i2', name: 'Cheeseburger', nameAr: 'تشيز برجر', nameKu: 'چیزبەرگەر', calories: 303, protein: 17, carbs: 24, fat: 15, category: 'International', micros: {'vitB12': 1.5, 'iron': 2.5, 'calcium': 120, 'potassium': 220, 'zinc': 3.5}),
  FoodItem(id: 'i3', name: 'French Fries', nameAr: 'بطاطس مقلية', nameKu: 'بەتاتەی سوورکراو', calories: 312, protein: 3.4, carbs: 41, fat: 15, category: 'International', micros: {'vitC': 9, 'iron': 0.8, 'calcium': 12, 'potassium': 400, 'zinc': 0.3}),
  FoodItem(id: 'i4', name: 'Fried Chicken', nameAr: 'دجاج مقلي', nameKu: 'مریشکی سوورکراو', calories: 260, protein: 20, carbs: 10, fat: 16, category: 'International', micros: {'vitB12': 0.3, 'iron': 1.2, 'calcium': 18, 'potassium': 200, 'zinc': 1.8}),
  FoodItem(id: 'i5', name: 'Sushi (Salmon)', nameAr: 'سوشي سلمون', nameKu: 'سوشی سەلمۆن', calories: 140, protein: 6, carbs: 20, fat: 4, category: 'International', micros: {'vitB12': 1.2, 'vitD': 3.0, 'iron': 0.5, 'calcium': 10, 'potassium': 120, 'zinc': 0.4}),
  FoodItem(id: 'i6', name: 'Pad Thai', nameAr: 'باد تاي', nameKu: 'پاد تای', calories: 190, protein: 8, carbs: 25, fat: 7, category: 'International', micros: {'vitC': 5, 'iron': 1.5, 'calcium': 30, 'potassium': 180, 'zinc': 1.0}),
  FoodItem(id: 'i7', name: 'Caesar Salad', nameAr: 'سلطة سيزر', nameKu: 'سەلاتەی سیزار', calories: 170, protein: 7, carbs: 8, fat: 13, category: 'International', micros: {'vitA': 150, 'vitC': 10, 'calcium': 80, 'potassium': 200, 'iron': 1.0}),
  FoodItem(id: 'i8', name: 'Lentil Soup', nameAr: 'شوربة عدس', nameKu: 'شۆربای نیسک', calories: 116, protein: 9, carbs: 20, fat: 0.4, category: 'International', micros: {'vitA': 8, 'vitC': 3, 'iron': 3.3, 'calcium': 19, 'potassium': 370, 'zinc': 1.3}),
  FoodItem(id: 'i9', name: 'Pancakes', nameAr: 'بان كيك', nameKu: 'پانکەیک', calories: 227, protein: 6, carbs: 28, fat: 10, category: 'International', micros: {'vitA': 50, 'calcium': 100, 'potassium': 120, 'iron': 1.5, 'zinc': 0.5}),
  FoodItem(id: 'i10', name: 'Pasta Bolognese', nameAr: 'باستا بولونيز', nameKu: 'پاستا بۆلۆنێز', calories: 160, protein: 8, carbs: 20, fat: 5, category: 'International', micros: {'vitA': 30, 'vitC': 6, 'vitB12': 0.8, 'iron': 1.8, 'calcium': 20, 'potassium': 250, 'zinc': 1.5}),

  // ─── Beverages ────────────────────────────────────────
  FoodItem(id: 'b1', name: 'Black Coffee', nameAr: 'قهوة سوداء', nameKu: 'قاوەی ڕەش', calories: 2, protein: 0.3, carbs: 0, fat: 0, category: 'Beverage', micros: {'potassium': 49}),
  FoodItem(id: 'b2', name: 'Black Tea', nameAr: 'شاي أسود', nameKu: 'چایی ڕەش', calories: 1, protein: 0.1, carbs: 0.3, fat: 0, category: 'Beverage', micros: {'potassium': 37}),
  FoodItem(id: 'b3', name: 'Orange Juice', nameAr: 'عصير برتقال', nameKu: 'ئاوی پرتەقاڵ', calories: 45, protein: 0.7, carbs: 10, fat: 0.2, category: 'Beverage', micros: {'vitC': 50, 'calcium': 11, 'potassium': 200}),
  FoodItem(id: 'b4', name: 'Coca-Cola', nameAr: 'كوكا كولا', nameKu: 'کۆکا کۆلا', calories: 42, protein: 0, carbs: 11, fat: 0, category: 'Beverage', micros: {}),
  FoodItem(id: 'b5', name: 'Green Tea', nameAr: 'شاي أخضر', nameKu: 'چایی سەوز', calories: 1, protein: 0.2, carbs: 0, fat: 0, category: 'Beverage', micros: {'vitC': 0.3, 'potassium': 8}),

  // ─── Snacks & Sweets ──────────────────────────────────
  FoodItem(id: 's1', name: 'Dark Chocolate (70%)', nameAr: 'شوكولاتة داكنة', nameKu: 'چکلێتی تاریک', calories: 598, protein: 8, carbs: 46, fat: 43, category: 'Snacks', micros: {'iron': 11.9, 'calcium': 73, 'potassium': 715, 'zinc': 3.3}),
  FoodItem(id: 's2', name: 'Honey', nameAr: 'عسل', nameKu: 'هەنگوین', calories: 328, protein: 0.3, carbs: 82, fat: 0, category: 'Snacks', micros: {'vitC': 0.5, 'calcium': 6, 'potassium': 52, 'iron': 0.4}),
  FoodItem(id: 's3', name: 'Peanut Butter', nameAr: 'زبدة فول سوداني', nameKu: 'کەرەی فستقی زەوی', calories: 588, protein: 25, carbs: 20, fat: 50, category: 'Snacks', micros: {'iron': 1.9, 'calcium': 43, 'potassium': 649, 'zinc': 2.8}),
  FoodItem(id: 's4', name: 'Granola Bar', nameAr: 'لوح جرانولا', nameKu: 'بار گرانۆلا', calories: 471, protein: 10, carbs: 64, fat: 20, category: 'Snacks', micros: {'iron': 3.0, 'calcium': 60, 'potassium': 300, 'zinc': 2.0}),
  FoodItem(id: 's5', name: 'Popcorn (Air-Popped)', nameAr: 'فشار (بدون زيت)', nameKu: 'پۆپکۆرن (بێ ڕۆن)', calories: 375, protein: 12, carbs: 74, fat: 4.3, category: 'Snacks', micros: {'iron': 3.2, 'calcium': 7, 'potassium': 329, 'zinc': 3.1}),
  FoodItem(id: 's6', name: 'Baklava', nameAr: 'بقلاوة', nameKu: 'بەقلاوە', calories: 430, protein: 6, carbs: 48, fat: 25, category: 'Snacks', micros: {'iron': 1.5, 'calcium': 30, 'potassium': 120, 'zinc': 1.0}),
  FoodItem(id: 's7', name: 'Rice Cake', nameAr: 'كعكة أرز', nameKu: 'کێکی برنج', calories: 387, protein: 8, carbs: 81, fat: 2.8, category: 'Snacks', micros: {'iron': 0.7, 'calcium': 4, 'potassium': 86, 'zinc': 1.2}),

  // ─── Oils & Fats ──────────────────────────────────────
  FoodItem(id: 'o1', name: 'Olive Oil', nameAr: 'زيت زيتون', nameKu: 'ڕۆنی زەیتوون', calories: 884, protein: 0, carbs: 0, fat: 100, category: 'Oil', micros: {'vitA': 0, 'iron': 0.6, 'calcium': 1, 'potassium': 1}),
  FoodItem(id: 'o2', name: 'Coconut Oil', nameAr: 'زيت جوز هند', nameKu: 'ڕۆنی گوێزی هیندی', calories: 862, protein: 0, carbs: 0, fat: 100, category: 'Oil', micros: {'iron': 0.04}),
  FoodItem(id: 'o3', name: 'Tahini', nameAr: 'طحينة', nameKu: 'ڕاشی', calories: 595, protein: 17, carbs: 22, fat: 54, category: 'Oil', micros: {'iron': 8.9, 'calcium': 420, 'potassium': 414, 'zinc': 4.6}),
  FoodItem(id: 'o4', name: 'Ghee', nameAr: 'سمن', nameKu: 'ڕۆنی حەیوانی', calories: 900, protein: 0, carbs: 0, fat: 100, category: 'Oil', micros: {'vitA': 840, 'vitD': 1.5, 'calcium': 4, 'potassium': 5}),
  FoodItem(id: 'o5', name: 'Sesame Oil', nameAr: 'زيت سمسم', nameKu: 'ڕۆنی کونجی', calories: 884, protein: 0, carbs: 0, fat: 100, category: 'Oil', micros: {'iron': 0.2, 'calcium': 2, 'potassium': 1}),

  // ─── Additional Kurdish / Iraqi ─────────────────────
  FoodItem(id: 'k16', name: 'Tikka (Chicken)', nameAr: 'تكة دجاج', nameKu: 'تیکەی مریشک', calories: 190, protein: 28, carbs: 3, fat: 7, category: 'Kurdish', micros: {'vitB12': 0.3, 'iron': 1.2, 'calcium': 15, 'potassium': 250, 'zinc': 2.0}),
  FoodItem(id: 'k18', name: 'Margat Bamya', nameAr: 'مرقة بامية', nameKu: 'مەرگەی بامیە', calories: 110, protein: 5, carbs: 12, fat: 5, category: 'Soup', micros: {'vitA': 30, 'vitC': 20, 'iron': 1.0, 'calcium': 75, 'potassium': 280, 'zinc': 0.6}),
  FoodItem(id: 'k19', name: 'Kleicha (Date Cookie)', nameAr: 'كليجة', nameKu: 'کلێچە', calories: 350, protein: 5, carbs: 55, fat: 13, category: 'Kurdish', micros: {'iron': 1.2, 'calcium': 30, 'potassium': 150, 'zinc': 0.5}),
  FoodItem(id: 'k20', name: 'Makhlama (Egg Scramble)', nameAr: 'مخلمة', nameKu: 'مەخلەمە', calories: 180, protein: 12, carbs: 5, fat: 13, category: 'Kurdish', micros: {'vitA': 140, 'vitB12': 0.8, 'iron': 1.5, 'calcium': 50, 'potassium': 170, 'zinc': 1.2}),
  FoodItem(id: 'k21', name: 'Kahi (Fried Dough)', nameAr: 'قاهي', nameKu: 'قاهی', calories: 420, protein: 5, carbs: 50, fat: 22, category: 'Kurdish', micros: {'iron': 1.0, 'calcium': 20, 'potassium': 60}),
  FoodItem(id: 'k22', name: 'Gaymer (Clotted Cream)', nameAr: 'قيمر', nameKu: 'گەیمەر', calories: 340, protein: 2, carbs: 3, fat: 36, category: 'Kurdish', micros: {'vitA': 400, 'vitD': 0.8, 'calcium': 60, 'potassium': 40}),
  FoodItem(id: 'k23', name: 'Timman Zafaran (Saffron Rice)', nameAr: 'تمن زعفران', nameKu: 'تمەنی زەعفەران', calories: 170, protein: 3, carbs: 34, fat: 2, category: 'RiceDishes', micros: {'iron': 0.8, 'calcium': 10, 'potassium': 50, 'zinc': 0.5}),

  // ─── Additional Arabic / Middle Eastern ──────────────
  FoodItem(id: 'a16', name: 'Shakshuka', nameAr: 'شكشوكة', nameKu: 'شەکشووکە', calories: 160, protein: 10, carbs: 10, fat: 9, category: 'Arabic', micros: {'vitA': 100, 'vitC': 20, 'iron': 2.0, 'calcium': 50, 'potassium': 300, 'zinc': 1.0}),
  FoodItem(id: 'a17', name: 'Maqluba', nameAr: 'مقلوبة', nameKu: 'مەقلووبە', calories: 220, protein: 12, carbs: 28, fat: 8, category: 'Arabic', micros: {'vitA': 30, 'vitC': 5, 'iron': 1.5, 'calcium': 30, 'potassium': 250, 'zinc': 1.8}),
  FoodItem(id: 'a18', name: 'Maamoul', nameAr: 'معمول', nameKu: 'مەعموول', calories: 400, protein: 6, carbs: 50, fat: 20, category: 'Arabic', micros: {'iron': 1.5, 'calcium': 35, 'potassium': 180, 'zinc': 0.8}),
  FoodItem(id: 'a19', name: 'Mulukhiyah', nameAr: 'ملوخية', nameKu: 'مەلوخیە', calories: 90, protein: 5, carbs: 8, fat: 4, category: 'Arabic', micros: {'vitA': 250, 'vitC': 15, 'iron': 3.0, 'calcium': 210, 'potassium': 350, 'zinc': 0.5}),
  FoodItem(id: 'a20', name: 'Warak Enab (Grape Leaves)', nameAr: 'ورق عنب', nameKu: 'بەرگی ترێ', calories: 160, protein: 5, carbs: 22, fat: 6, category: 'Arabic', micros: {'vitA': 50, 'vitC': 8, 'iron': 2.0, 'calcium': 45, 'potassium': 200, 'zinc': 0.7}),
  FoodItem(id: 'a21', name: 'Shish Tawook', nameAr: 'شيش طاووق', nameKu: 'شیش تاووک', calories: 175, protein: 28, carbs: 5, fat: 5, category: 'Arabic', micros: {'vitB12': 0.3, 'iron': 1.0, 'calcium': 15, 'potassium': 230, 'zinc': 1.5}),
  FoodItem(id: 'a22', name: 'Manakeesh', nameAr: 'مناقيش', nameKu: 'مەناقیش', calories: 290, protein: 8, carbs: 35, fat: 13, category: 'Arabic', micros: {'vitA': 10, 'iron': 2.0, 'calcium': 45, 'potassium': 100, 'zinc': 0.8}),

  // ─── Additional Proteins ─────────────────────────────
  FoodItem(id: 'p13', name: 'Chicken Wings', nameAr: 'أجنحة دجاج', nameKu: 'باڵی مریشک', calories: 290, protein: 27, carbs: 0, fat: 19, category: 'Protein', micros: {'vitA': 15, 'vitB12': 0.3, 'iron': 1.2, 'calcium': 15, 'potassium': 200, 'zinc': 1.8}),
  FoodItem(id: 'p14', name: 'Liver (Beef)', nameAr: 'كبد بقري', nameKu: 'جگەری مانگا', calories: 135, protein: 21, carbs: 4, fat: 4, category: 'Protein', micros: {'vitA': 9442, 'vitB12': 59.3, 'vitC': 1.3, 'iron': 6.5, 'calcium': 5, 'potassium': 313, 'zinc': 4.0}),
  FoodItem(id: 'p15', name: 'Lamb Shoulder', nameAr: 'كتف خروف', nameKu: 'شانی بەرخ', calories: 240, protein: 20, carbs: 0, fat: 17, category: 'Protein', micros: {'vitB12': 2.3, 'iron': 2.0, 'calcium': 15, 'potassium': 280, 'zinc': 4.2}),
  FoodItem(id: 'p16', name: 'Tilapia', nameAr: 'بلطي', nameKu: 'تیلاپیا', calories: 128, protein: 26, carbs: 0, fat: 2.6, category: 'Protein', micros: {'vitB12': 1.6, 'vitD': 3.1, 'iron': 0.7, 'calcium': 14, 'potassium': 302, 'zinc': 0.4}),
  FoodItem(id: 'p17', name: 'Duck Breast', nameAr: 'صدر بط', nameKu: 'سنگی مراوی', calories: 201, protein: 24, carbs: 0, fat: 11, category: 'Protein', micros: {'vitB12': 0.4, 'iron': 2.7, 'calcium': 11, 'potassium': 271, 'zinc': 1.9}),
  FoodItem(id: 'p18', name: 'Tofu', nameAr: 'توفو', nameKu: 'تۆفوو', calories: 76, protein: 8, carbs: 1.9, fat: 4.8, category: 'Protein', micros: {'iron': 5.4, 'calcium': 350, 'potassium': 121, 'zinc': 0.8}),
  FoodItem(id: 'p19', name: 'Beef Tongue', nameAr: 'لسان بقر', nameKu: 'زمانی مانگا', calories: 224, protein: 16, carbs: 3, fat: 16, category: 'Protein', micros: {'vitB12': 3.8, 'iron': 2.9, 'calcium': 6, 'potassium': 315, 'zinc': 4.4}),
  FoodItem(id: 'p20', name: 'Crab Meat', nameAr: 'لحم سلطعون', nameKu: 'گۆشتی قرژاڵ', calories: 97, protein: 19, carbs: 0, fat: 1.5, category: 'Protein', micros: {'vitB12': 9.0, 'iron': 0.7, 'calcium': 46, 'potassium': 329, 'zinc': 6.5}),

  // ─── Additional Dairy ────────────────────────────────
  FoodItem(id: 'd9', name: 'Feta Cheese', nameAr: 'جبنة فيتا', nameKu: 'پەنیری فیتا', calories: 264, protein: 14, carbs: 4, fat: 21, category: 'Dairy', micros: {'vitA': 125, 'vitB12': 1.7, 'calcium': 493, 'potassium': 62, 'zinc': 2.9}),
  FoodItem(id: 'd10', name: 'Parmesan', nameAr: 'جبنة بارميزان', nameKu: 'پەنیری پارمیزان', calories: 431, protein: 38, carbs: 4, fat: 29, category: 'Dairy', micros: {'vitA': 165, 'vitB12': 1.2, 'calcium': 1184, 'potassium': 92, 'zinc': 2.8}),
  FoodItem(id: 'd11', name: 'Skim Milk', nameAr: 'حليب خالي الدسم', nameKu: 'شیری بێ چەوری', calories: 34, protein: 3.4, carbs: 5, fat: 0.1, category: 'Dairy', micros: {'vitA': 5, 'vitB12': 0.4, 'vitD': 1.3, 'calcium': 122, 'potassium': 156, 'zinc': 0.4}),
  FoodItem(id: 'd13', name: 'Ricotta', nameAr: 'ريكوتا', nameKu: 'ڕیکۆتا', calories: 174, protein: 11, carbs: 3, fat: 13, category: 'Dairy', micros: {'vitA': 120, 'vitB12': 0.3, 'calcium': 207, 'potassium': 105, 'zinc': 1.2}),
  FoodItem(id: 'd14', name: 'Kefir', nameAr: 'كفير', nameKu: 'کەفیر', calories: 63, protein: 3.5, carbs: 4.7, fat: 3.5, category: 'Dairy', micros: {'vitA': 30, 'vitB12': 0.3, 'vitD': 1.0, 'calcium': 130, 'potassium': 164, 'zinc': 0.5}),

  // ─── Additional Grains ───────────────────────────────
  FoodItem(id: 'g13', name: 'Basmati Rice', nameAr: 'أرز بسمتي', nameKu: 'برنجی بەسمەتی', calories: 150, protein: 3, carbs: 32, fat: 0.4, category: 'Grains', micros: {'iron': 0.6, 'calcium': 8, 'potassium': 30, 'zinc': 0.4}),
  FoodItem(id: 'g14', name: 'Pita Bread', nameAr: 'خبز بيتا', nameKu: 'نانی پیتا', calories: 275, protein: 9, carbs: 55, fat: 1.2, category: 'Bread', micros: {'iron': 2.6, 'calcium': 86, 'potassium': 120, 'zinc': 0.8}),
  FoodItem(id: 'g15', name: 'Vermicelli (Dry)', nameAr: 'شعيرية (جافة)', nameKu: 'شعیریە (وشک)', calories: 354, protein: 12, carbs: 72, fat: 1.5, category: 'Grains', micros: {'iron': 3.5, 'calcium': 15, 'potassium': 130, 'zinc': 1.1}),
  FoodItem(id: 'g16', name: 'Cornflakes', nameAr: 'رقائق الذرة', nameKu: 'کۆرنفلێکس', calories: 357, protein: 8, carbs: 84, fat: 0.4, category: 'Grains', micros: {'iron': 8.0, 'calcium': 3, 'potassium': 100, 'zinc': 0.5}),
  FoodItem(id: 'g17', name: 'Tortilla (Flour)', nameAr: 'تورتيلا دقيق', nameKu: 'تۆرتیلای ئارد', calories: 312, protein: 8, carbs: 52, fat: 8, category: 'Bread', micros: {'iron': 3.0, 'calcium': 110, 'potassium': 130, 'zinc': 0.7}),
  FoodItem(id: 'g18', name: 'Freekeh', nameAr: 'فريكة', nameKu: 'فرێکە', calories: 130, protein: 5, carbs: 25, fat: 1, category: 'Grains', micros: {'iron': 1.5, 'calcium': 15, 'potassium': 110, 'zinc': 1.0}),

  // ─── Additional Fruits ───────────────────────────────
  FoodItem(id: 'f17', name: 'Cherry', nameAr: 'كرز', nameKu: 'گێلاس', calories: 50, protein: 1, carbs: 12, fat: 0.3, category: 'Fruit', micros: {'vitA': 3, 'vitC': 7, 'calcium': 13, 'potassium': 222, 'iron': 0.4}),
  FoodItem(id: 'f18', name: 'Lemon', nameAr: 'ليمون', nameKu: 'لیمۆ', calories: 29, protein: 1.1, carbs: 9, fat: 0.3, category: 'Fruit', micros: {'vitC': 53, 'calcium': 26, 'potassium': 138, 'iron': 0.6}),
  FoodItem(id: 'f19', name: 'Apricot', nameAr: 'مشمش', nameKu: 'قەیسی', calories: 48, protein: 1.4, carbs: 11, fat: 0.4, category: 'Fruit', micros: {'vitA': 96, 'vitC': 10, 'calcium': 13, 'potassium': 259, 'iron': 0.4}),
  FoodItem(id: 'f20', name: 'Coconut (Fresh)', nameAr: 'جوز هند طازج', nameKu: 'گوێزی هیندی تازە', calories: 354, protein: 3.3, carbs: 15, fat: 33, category: 'Fruit', micros: {'iron': 2.4, 'calcium': 14, 'potassium': 356, 'zinc': 1.1}),
  FoodItem(id: 'f21', name: 'Papaya', nameAr: 'بابايا', nameKu: 'پاپایا', calories: 43, protein: 0.5, carbs: 11, fat: 0.3, category: 'Fruit', micros: {'vitA': 47, 'vitC': 61, 'calcium': 20, 'potassium': 182, 'iron': 0.3}),
  FoodItem(id: 'f22', name: 'Plum', nameAr: 'برقوق', nameKu: 'ئالوو', calories: 46, protein: 0.7, carbs: 11, fat: 0.3, category: 'Fruit', micros: {'vitA': 17, 'vitC': 9.5, 'calcium': 6, 'potassium': 157, 'iron': 0.2}),
  FoodItem(id: 'f23', name: 'Mulberry', nameAr: 'توت', nameKu: 'تووت', calories: 43, protein: 1.4, carbs: 10, fat: 0.4, category: 'Fruit', micros: {'vitC': 36, 'iron': 1.9, 'calcium': 39, 'potassium': 194}),
  FoodItem(id: 'f24', name: 'Cantaloupe', nameAr: 'شمام', nameKu: 'قاوون', calories: 34, protein: 0.8, carbs: 8, fat: 0.2, category: 'Fruit', micros: {'vitA': 169, 'vitC': 37, 'calcium': 9, 'potassium': 267, 'iron': 0.2}),

  // ─── Additional Vegetables ───────────────────────────
  FoodItem(id: 'v15', name: 'Cabbage', nameAr: 'ملفوف', nameKu: 'کەلەم', calories: 25, protein: 1.3, carbs: 6, fat: 0.1, category: 'Vegetable', micros: {'vitA': 5, 'vitC': 36, 'calcium': 40, 'potassium': 170, 'iron': 0.5}),
  FoodItem(id: 'v16', name: 'Celery', nameAr: 'كرفس', nameKu: 'کەرەفس', calories: 14, protein: 0.7, carbs: 3, fat: 0.2, category: 'Vegetable', micros: {'vitA': 22, 'vitC': 3, 'calcium': 40, 'potassium': 260, 'iron': 0.2}),
  FoodItem(id: 'v17', name: 'Leek', nameAr: 'كراث', nameKu: 'گەندەڵ', calories: 61, protein: 1.5, carbs: 14, fat: 0.3, category: 'Vegetable', micros: {'vitA': 33, 'vitC': 12, 'calcium': 59, 'potassium': 180, 'iron': 2.1}),
  FoodItem(id: 'v18', name: 'Radish', nameAr: 'فجل', nameKu: 'تووڕب', calories: 16, protein: 0.7, carbs: 3.4, fat: 0.1, category: 'Vegetable', micros: {'vitC': 14.8, 'calcium': 25, 'potassium': 233, 'iron': 0.3}),
  FoodItem(id: 'v19', name: 'Turnip', nameAr: 'لفت', nameKu: 'شەلغەم', calories: 28, protein: 0.9, carbs: 6, fat: 0.1, category: 'Vegetable', micros: {'vitC': 21, 'calcium': 30, 'potassium': 191, 'iron': 0.3}),
  FoodItem(id: 'v20', name: 'Beetroot', nameAr: 'شمندر', nameKu: 'جوقندەر', calories: 43, protein: 1.6, carbs: 10, fat: 0.2, category: 'Vegetable', micros: {'vitC': 4.9, 'iron': 0.8, 'calcium': 16, 'potassium': 325, 'zinc': 0.4}),
  FoodItem(id: 'v21', name: 'Asparagus', nameAr: 'هليون', nameKu: 'مارچووبە', calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, category: 'Vegetable', micros: {'vitA': 38, 'vitC': 5.6, 'iron': 2.1, 'calcium': 24, 'potassium': 202, 'zinc': 0.5}),
  FoodItem(id: 'v22', name: 'Artichoke', nameAr: 'خرشوف', nameKu: 'ئەنگینار', calories: 47, protein: 3.3, carbs: 11, fat: 0.2, category: 'Vegetable', micros: {'vitC': 12, 'iron': 1.3, 'calcium': 44, 'potassium': 370, 'zinc': 0.5}),
  FoodItem(id: 'v23', name: 'Sweet Corn', nameAr: 'ذرة حلوة', nameKu: 'گەنمەشامی شیرین', calories: 86, protein: 3.3, carbs: 19, fat: 1.2, category: 'Vegetable', micros: {'vitA': 9, 'vitC': 7, 'iron': 0.5, 'calcium': 2, 'potassium': 270, 'zinc': 0.5}),
  FoodItem(id: 'v24', name: 'Parsley', nameAr: 'بقدونس', nameKu: 'جەعفەری', calories: 36, protein: 3, carbs: 6, fat: 0.8, category: 'Vegetable', micros: {'vitA': 421, 'vitC': 133, 'iron': 6.2, 'calcium': 138, 'potassium': 554, 'zinc': 1.1}),
  FoodItem(id: 'v25', name: 'Mint (Fresh)', nameAr: 'نعناع طازج', nameKu: 'پوونەی تازە', calories: 44, protein: 3.3, carbs: 8, fat: 0.7, category: 'Vegetable', micros: {'vitA': 212, 'vitC': 13, 'iron': 5.1, 'calcium': 199, 'potassium': 458}),

  // ─── Additional Nuts & Seeds ─────────────────────────
  FoodItem(id: 'n9', name: 'Hazelnuts', nameAr: 'بندق', nameKu: 'فندق', calories: 628, protein: 15, carbs: 17, fat: 61, category: 'Nuts', micros: {'iron': 4.7, 'calcium': 114, 'potassium': 680, 'zinc': 2.5}),
  FoodItem(id: 'n10', name: 'Macadamia', nameAr: 'مكاديميا', nameKu: 'ماکادامیا', calories: 718, protein: 8, carbs: 14, fat: 76, category: 'Nuts', micros: {'iron': 3.7, 'calcium': 85, 'potassium': 368, 'zinc': 1.3}),
  FoodItem(id: 'n11', name: 'Pumpkin Seeds', nameAr: 'بذور القرع', nameKu: 'تۆوی کوڵەکە', calories: 559, protein: 30, carbs: 11, fat: 49, category: 'Nuts', micros: {'iron': 8.8, 'calcium': 46, 'potassium': 809, 'zinc': 7.8}),
  FoodItem(id: 'n12', name: 'Pine Nuts', nameAr: 'صنوبر', nameKu: 'سنۆبەر', calories: 673, protein: 14, carbs: 13, fat: 68, category: 'Nuts', micros: {'iron': 5.5, 'calcium': 16, 'potassium': 597, 'zinc': 6.4}),

  // ─── Additional Legumes ──────────────────────────────
  FoodItem(id: 'l5', name: 'Kidney Beans', nameAr: 'فاصوليا حمراء', nameKu: 'لووبیای سوور', calories: 127, protein: 9, carbs: 22, fat: 0.5, category: 'Legumes', micros: {'vitC': 1.2, 'iron': 2.9, 'calcium': 28, 'potassium': 403, 'zinc': 1.0}),
  FoodItem(id: 'l6', name: 'White Beans', nameAr: 'فاصوليا بيضاء', nameKu: 'لووبیای سپی', calories: 139, protein: 10, carbs: 25, fat: 0.4, category: 'Legumes', micros: {'iron': 3.7, 'calcium': 90, 'potassium': 561, 'zinc': 1.4}),
  FoodItem(id: 'l7', name: 'Green Lentils', nameAr: 'عدس أخضر', nameKu: 'نیسکی سەوز', calories: 116, protein: 9, carbs: 20, fat: 0.4, category: 'Legumes', micros: {'iron': 3.3, 'calcium': 19, 'potassium': 369, 'zinc': 1.3}),
  FoodItem(id: 'l8', name: 'Soybeans (Cooked)', nameAr: 'فول الصويا مطبوخ', nameKu: 'سۆیای لێنراو', calories: 173, protein: 17, carbs: 10, fat: 9, category: 'Legumes', micros: {'iron': 5.1, 'calcium': 102, 'potassium': 515, 'zinc': 1.2}),
  FoodItem(id: 'l9', name: 'Broad Beans (Fava)', nameAr: 'فول أخضر', nameKu: 'باقلای سەوز', calories: 88, protein: 8, carbs: 13, fat: 0.7, category: 'Legumes', micros: {'vitC': 3, 'iron': 1.5, 'calcium': 36, 'potassium': 268, 'zinc': 1.0}),

  // ─── Additional International ────────────────────────
  FoodItem(id: 'i11', name: 'Tacos (Beef)', nameAr: 'تاكو لحم', nameKu: 'تاکۆی گۆشت', calories: 226, protein: 12, carbs: 20, fat: 11, category: 'International', micros: {'vitA': 30, 'vitB12': 1.0, 'iron': 2.0, 'calcium': 80, 'potassium': 200, 'zinc': 2.5}),
  FoodItem(id: 'i12', name: 'Spring Roll', nameAr: 'سبرنغ رول', nameKu: 'سپرینگ ڕۆڵ', calories: 200, protein: 5, carbs: 25, fat: 9, category: 'International', micros: {'vitA': 15, 'vitC': 3, 'iron': 1.0, 'calcium': 15, 'potassium': 100}),
  FoodItem(id: 'i13', name: 'Fish & Chips', nameAr: 'سمك وبطاطا مقلية', nameKu: 'ماسی و بەتاتە', calories: 250, protein: 13, carbs: 25, fat: 12, category: 'International', micros: {'vitB12': 1.0, 'vitC': 6, 'iron': 0.8, 'calcium': 20, 'potassium': 300, 'zinc': 0.5}),
  FoodItem(id: 'i14', name: 'Ramen', nameAr: 'رامن', nameKu: 'ڕامێن', calories: 190, protein: 8, carbs: 28, fat: 5, category: 'International', micros: {'iron': 1.5, 'calcium': 15, 'potassium': 130, 'zinc': 0.8}),
  FoodItem(id: 'i15', name: 'Butter Chicken', nameAr: 'دجاج بالزبدة', nameKu: 'مریشکی کەرەیی', calories: 200, protein: 18, carbs: 8, fat: 11, category: 'International', micros: {'vitA': 60, 'vitB12': 0.3, 'iron': 1.5, 'calcium': 40, 'potassium': 250, 'zinc': 1.5}),
  FoodItem(id: 'i16', name: 'Biryani (Indian)', nameAr: 'برياني هندي', nameKu: 'بریانی هیندی', calories: 210, protein: 10, carbs: 30, fat: 6, category: 'International', micros: {'vitA': 15, 'iron': 1.2, 'calcium': 20, 'potassium': 150, 'zinc': 1.0}),
  FoodItem(id: 'i17', name: 'Doner Kebab', nameAr: 'دونر كباب', nameKu: 'دۆنەر کەباب', calories: 230, protein: 18, carbs: 12, fat: 13, category: 'International', micros: {'vitB12': 2.0, 'iron': 2.2, 'calcium': 20, 'potassium': 220, 'zinc': 3.5}),
  FoodItem(id: 'i18', name: 'Gyro (Lamb)', nameAr: 'جايرو لحم', nameKu: 'گایرۆی بەرخ', calories: 260, protein: 19, carbs: 15, fat: 14, category: 'International', micros: {'vitB12': 2.0, 'iron': 2.0, 'calcium': 30, 'potassium': 250, 'zinc': 3.8}),

  // ─── Additional Beverages ────────────────────────────
  FoodItem(id: 'b6', name: 'Apple Juice', nameAr: 'عصير تفاح', nameKu: 'ئاوی سێو', calories: 46, protein: 0.1, carbs: 11, fat: 0.1, category: 'Beverage', micros: {'vitC': 1, 'calcium': 8, 'potassium': 101}),
  FoodItem(id: 'b7', name: 'Lemonade', nameAr: 'عصير ليمون', nameKu: 'لیمۆناتە', calories: 40, protein: 0.1, carbs: 10, fat: 0, category: 'Beverage', micros: {'vitC': 18, 'calcium': 3, 'potassium': 50}),
  FoodItem(id: 'b8', name: 'Pomegranate Juice', nameAr: 'عصير رمان', nameKu: 'ئاوی هەنار', calories: 54, protein: 0.2, carbs: 13, fat: 0.3, category: 'Beverage', micros: {'vitC': 0.3, 'calcium': 11, 'potassium': 214}),
  FoodItem(id: 'b9', name: 'Hot Chocolate', nameAr: 'شوكولاتة ساخنة', nameKu: 'چکلێتی گەرم', calories: 95, protein: 3.5, carbs: 13, fat: 3.5, category: 'Beverage', micros: {'vitA': 20, 'calcium': 115, 'potassium': 170, 'iron': 0.5}),
  FoodItem(id: 'b10', name: 'Chai Tea', nameAr: 'شاي ماسالا', nameKu: 'چایی چای', calories: 30, protein: 0.5, carbs: 5, fat: 1, category: 'Beverage', micros: {'calcium': 30, 'potassium': 40}),
  FoodItem(id: 'b11', name: 'Ayran', nameAr: 'عيران', nameKu: 'دۆو', calories: 35, protein: 2, carbs: 3, fat: 1.5, category: 'Beverage', micros: {'calcium': 90, 'potassium': 100, 'vitB12': 0.3}),

  // ─── Additional Snacks & Sweets ──────────────────────
  FoodItem(id: 's8', name: 'Milk Chocolate', nameAr: 'شوكولاتة بالحليب', nameKu: 'چکلێتی شیری', calories: 535, protein: 8, carbs: 60, fat: 30, category: 'Snacks', micros: {'vitA': 60, 'calcium': 189, 'potassium': 372, 'iron': 2.4, 'zinc': 2.3}),
  FoodItem(id: 's9', name: 'Ice Cream (Vanilla)', nameAr: 'آيس كريم فانيلا', nameKu: 'ئایس کریمی ڤانیلیا', calories: 207, protein: 3.5, carbs: 24, fat: 11, category: 'Snacks', micros: {'vitA': 80, 'calcium': 128, 'potassium': 199, 'zinc': 0.7}),
  FoodItem(id: 's10', name: 'Protein Bar', nameAr: 'لوح بروتين', nameKu: 'بار پرۆتین', calories: 220, protein: 20, carbs: 25, fat: 7, category: 'Snacks', micros: {'iron': 2.5, 'calcium': 100, 'potassium': 200, 'zinc': 2.0}),
  FoodItem(id: 's11', name: 'Energy Balls', nameAr: 'كرات الطاقة', nameKu: 'تۆپەکانی وزە', calories: 350, protein: 8, carbs: 40, fat: 18, category: 'Snacks', micros: {'iron': 2.0, 'calcium': 40, 'potassium': 300, 'zinc': 1.5}),
  FoodItem(id: 's12', name: 'Dried Apricots', nameAr: 'مشمش مجفف', nameKu: 'قەیسی وشک', calories: 241, protein: 3.4, carbs: 63, fat: 0.5, category: 'Snacks', micros: {'vitA': 180, 'iron': 2.7, 'calcium': 55, 'potassium': 1162, 'zinc': 0.4}),
  FoodItem(id: 's13', name: 'Trail Mix', nameAr: 'خلطة المكسرات', nameKu: 'تێکەڵەی گوێز', calories: 462, protein: 13, carbs: 45, fat: 29, category: 'Snacks', micros: {'iron': 3.0, 'calcium': 70, 'potassium': 500, 'zinc': 2.5}),
  FoodItem(id: 's14', name: 'Turkish Delight', nameAr: 'راحة الحلقوم', nameKu: 'ڕاحەتی حەلقووم', calories: 350, protein: 0.5, carbs: 88, fat: 0.2, category: 'Snacks', micros: {'calcium': 5, 'potassium': 10}),
  FoodItem(id: 's15', name: 'Halva', nameAr: 'حلاوة طحينية', nameKu: 'حەلوا', calories: 469, protein: 12, carbs: 55, fat: 22, category: 'Snacks', micros: {'iron': 5.0, 'calcium': 200, 'potassium': 250, 'zinc': 2.5}),

  // ─── Additional Common Foods ──────────────────────
  FoodItem(id: 'p21', name: 'Chicken Liver', nameAr: 'كبد دجاج', nameKu: 'جگەری مریشک', calories: 167, protein: 24, carbs: 1, fat: 7, category: 'Protein', micros: {'vitA': 3300, 'vitB12': 16.6, 'vitC': 18, 'iron': 9.0, 'calcium': 8, 'potassium': 230, 'zinc': 2.7}),
  FoodItem(id: 'p22', name: 'Lamb Kebab', nameAr: 'كباب لحم غنم', nameKu: 'کەبابی بەرخ', calories: 245, protein: 20, carbs: 2, fat: 17, category: 'Protein', micros: {'vitB12': 2.3, 'iron': 2.0, 'calcium': 15, 'potassium': 270, 'zinc': 4.5}),
  FoodItem(id: 'p23', name: 'Bone Broth', nameAr: 'مرق عظام', nameKu: 'ئاوگۆشتی ئێسک', calories: 15, protein: 2.5, carbs: 0.5, fat: 0.2, category: 'Protein', micros: {'calcium': 7, 'potassium': 60, 'iron': 0.2}),
  FoodItem(id: 'v26', name: 'Okra (Raw)', nameAr: 'بامية خام', nameKu: 'بامیەی خام', calories: 33, protein: 1.9, carbs: 7, fat: 0.2, category: 'Vegetable', micros: {'vitA': 36, 'vitC': 23, 'calcium': 82, 'potassium': 299, 'iron': 0.6}),
  FoodItem(id: 'v27', name: 'Pumpkin', nameAr: 'يقطين', nameKu: 'کوڵەکە', calories: 26, protein: 1, carbs: 7, fat: 0.1, category: 'Vegetable', micros: {'vitA': 426, 'vitC': 9, 'calcium': 21, 'potassium': 340, 'iron': 0.8}),
  FoodItem(id: 'v28', name: 'Spring Onion', nameAr: 'بصل أخضر', nameKu: 'پیازی سەوز', calories: 32, protein: 1.8, carbs: 7, fat: 0.2, category: 'Vegetable', micros: {'vitA': 50, 'vitC': 19, 'calcium': 72, 'potassium': 276, 'iron': 1.5}),
  FoodItem(id: 'g19', name: 'Samoon (Iraqi Bread)', nameAr: 'صمون', nameKu: 'سەمون', calories: 275, protein: 9, carbs: 52, fat: 2.5, category: 'Bread', micros: {'iron': 3.0, 'calcium': 50, 'potassium': 115, 'zinc': 0.8}),
  FoodItem(id: 'g20', name: 'Tannour Bread', nameAr: 'خبز تنور', nameKu: 'نانی تەنوور', calories: 260, protein: 8, carbs: 50, fat: 2, category: 'Bread', micros: {'iron': 2.8, 'calcium': 40, 'potassium': 100, 'zinc': 0.7}),
  FoodItem(id: 'k24', name: 'Biryani Dajaj (Chicken)', nameAr: 'برياني دجاج', nameKu: 'بریانی مریشک', calories: 190, protein: 14, carbs: 22, fat: 5, category: 'RiceDishes', micros: {'vitB12': 0.3, 'iron': 1.0, 'calcium': 15, 'potassium': 180, 'zinc': 1.2}),
  FoodItem(id: 'k25', name: 'Dolma Silq (Chard Dolma)', nameAr: 'دولمة سلق', nameKu: 'دۆڵمەی سەلق', calories: 145, protein: 5, carbs: 20, fat: 5, category: 'Kurdish', micros: {'vitA': 60, 'vitC': 12, 'iron': 2.0, 'calcium': 50, 'potassium': 250, 'zinc': 0.8}),
  FoodItem(id: 'a23', name: 'Arayes (Meat Pita)', nameAr: 'عرايس', nameKu: 'عەرایەس', calories: 270, protein: 15, carbs: 25, fat: 12, category: 'Arabic', micros: {'vitB12': 1.5, 'iron': 2.5, 'calcium': 30, 'potassium': 200, 'zinc': 3.0}),
  FoodItem(id: 'a24', name: 'Jawaneh (Chicken Wings)', nameAr: 'جوانح', nameKu: 'جوانح', calories: 250, protein: 22, carbs: 5, fat: 16, category: 'Arabic', micros: {'vitB12': 0.3, 'iron': 1.2, 'calcium': 15, 'potassium': 200, 'zinc': 1.8}),
  FoodItem(id: 'b12', name: 'Turkish Coffee', nameAr: 'قهوة تركية', nameKu: 'قاوەی تورکی', calories: 5, protein: 0.3, carbs: 0.7, fat: 0, category: 'Beverage', micros: {'potassium': 55}),
  FoodItem(id: 'b13', name: 'Jallab', nameAr: 'جلاب', nameKu: 'جەلاب', calories: 70, protein: 0.2, carbs: 18, fat: 0, category: 'Beverage', micros: {'calcium': 10, 'potassium': 30}),
  FoodItem(
    id: 'b14',
    name: 'Nesquik cereal drink',
    nameAr: 'نيسكويك حبوب',
    nameKu: 'نیسکویک دانەوێڵە',
    calories: 375,
    protein: 8,
    carbs: 75,
    fat: 3,
    category: 'Beverage',
    micros: {'calcium': 120, 'potassium': 200},
  ),
  FoodItem(id: 'd15', name: 'Akkawi Cheese', nameAr: 'جبنة عكاوي', nameKu: 'پەنیری عەکاوی', calories: 289, protein: 18, carbs: 2, fat: 23, category: 'Dairy', micros: {'vitA': 100, 'calcium': 500, 'potassium': 70, 'zinc': 2.5}),
  FoodItem(id: 'd16', name: 'Kashkaval', nameAr: 'قشقوان', nameKu: 'قەشقەوان', calories: 377, protein: 25, carbs: 2, fat: 30, category: 'Dairy', micros: {'vitA': 200, 'calcium': 700, 'potassium': 80, 'zinc': 3.0}),
  FoodItem(id: 's16', name: 'Znoud el Sit', nameAr: 'زنود الست', nameKu: 'زنوودەلسیت', calories: 340, protein: 5, carbs: 42, fat: 17, category: 'Snacks', micros: {'vitA': 30, 'calcium': 50, 'potassium': 60, 'zinc': 0.3}),
  FoodItem(id: 's17', name: 'Qatayef', nameAr: 'قطايف', nameKu: 'قەتایف', calories: 310, protein: 6, carbs: 45, fat: 12, category: 'Snacks', micros: {'calcium': 40, 'potassium': 80, 'iron': 1.0}),
  FoodItem(id: 'l10', name: 'Mung Beans (Cooked)', nameAr: 'ماش مطبوخ', nameKu: 'ماشی لێنراو', calories: 105, protein: 7, carbs: 19, fat: 0.4, category: 'Legumes', micros: {'iron': 1.4, 'calcium': 27, 'potassium': 266, 'zinc': 0.8}),
  FoodItem(id: 'i19', name: 'Chicken Shawarma Plate', nameAr: 'صحن شاورما دجاج', nameKu: 'ساینی شاوەرمەی مریشک', calories: 195, protein: 22, carbs: 8, fat: 8, category: 'International', micros: {'vitB12': 0.3, 'iron': 1.2, 'calcium': 20, 'potassium': 230, 'zinc': 1.8}),
  FoodItem(id: 'i20', name: 'Chicken Nuggets', nameAr: 'ناغتس دجاج', nameKu: 'ناگێتسی مریشک', calories: 296, protein: 15, carbs: 18, fat: 18, category: 'International', micros: {'vitB12': 0.2, 'iron': 1.0, 'calcium': 20, 'potassium': 180, 'zinc': 1.0}),

  // ─── Protein powders & supplements ───────────────────
  ...proteinSupplementsList,

  // ─── Fast food chains (McDonald's, KFC, etc.) ───────
  ...fastFoodsList,

  // ─── Preparation variants (oil / cooking style) ─────
  ...foodPrepVariants,

  // ─── User Kurdish / Iraqi (custom macros) ───────────
  ...kurdishFoodsUser,

  ...kurdishBeverageFoodsUser,

  ...kurdishPlateSnackFoodsUser,

  ...kurdishSweetsFriedFoodsUser,

  // ─── Shla (Kurdish thin soups — bowl + gram via serving switch) ──
  ...shlaFoodsUser,

  // ─── Shla no-oil variants ─────────────────────────────
  ...shlaNoOilVariants,

  // ─── Oil × prep extras (fried / stewed rows) ───────────
  ...buildShlaOilPrepVariantRows(),
  ...legumeOilPrepExtraVariants,

  // ─── Bakery list (Sorani source — per user file) ─────
  ...bakeryFoodsList,
];

/// Keys tracked across food logging, meal plans, and the nutrients dashboard.
const List<String> kTrackedMicroKeys = [
  'vitA',
  'vitC',
  'vitD',
  'vitE',
  'vitK',
  'vitB6',
  'vitB12',
  'folate',
  'iron',
  'calcium',
  'potassium',
  'magnesium',
  'phosphorus',
  'zinc',
  'selenium',
  'sodium',
  'fiber',
];

/// Daily recommended intake values (adult baseline; personalized via [computeMicroGoals]).
const Map<String, double> dailyRecommended = {
  'vitA': 900,       // mcg RAE
  'vitC': 90,        // mg
  'vitD': 20,        // mcg
  'vitE': 15,        // mg
  'vitK': 120,       // mcg
  'vitB6': 1.7,      // mg
  'vitB12': 2.4,     // mcg
  'folate': 400,     // mcg DFE
  'iron': 8,         // mg (male default)
  'calcium': 1000,   // mg
  'potassium': 3500, // mg
  'magnesium': 420,  // mg
  'phosphorus': 700, // mg
  'zinc': 11,        // mg
  'selenium': 55,    // mcg
  'sodium': 2300,    // mg (upper limit)
  'fiber': 28,       // g
};

const Map<String, String> microUnits = {
  'vitA': 'mcg',
  'vitC': 'mg',
  'vitD': 'mcg',
  'vitE': 'mg',
  'vitK': 'mcg',
  'vitB6': 'mg',
  'vitB12': 'mcg',
  'folate': 'mcg',
  'iron': 'mg',
  'calcium': 'mg',
  'potassium': 'mg',
  'magnesium': 'mg',
  'phosphorus': 'mg',
  'zinc': 'mg',
  'selenium': 'mcg',
  'sodium': 'mg',
  'fiber': 'g',
};

/// Comma-separated list for AI prompts (units included).
String get microKeysForAiPrompt => kTrackedMicroKeys
    .map((k) => '$k(${microUnits[k]})')
    .join(', ');

/// Empty micros object for AI JSON examples.
String get microJsonTemplate =>
    '{${kTrackedMicroKeys.map((k) => '"$k":0').join(',')}}';

const Map<String, double> activityMultipliers = {
  'sedentary': 1.2,
  'lightlyActive': 1.375,
  'moderatelyActive': 1.55,
  'veryActive': 1.725,
  'extraActive': 1.9,
};

const List<String> sicknessList = [
  'diabetes1', 'diabetes2', 'hypertension', 'celiac',
  'ibs', 'kidney', 'heart', 'obesity', 'anemia',
  'hypo', 'hyper', 'gout', 'reflux',
];

const List<String> allergiesList = [
  'peanuts', 'treeNuts', 'milk', 'egg', 'wheat', 'soy', 'fish',
  'shellfish', 'sesame', 'gluten', 'lactose', 'corn', 'mustard',
];

const List<String> disabilitiesList = [
  'wheelchair', 'mobility', 'visual', 'hearing', 'amputation', 'none',
];

// ─── Extended onboarding ────────────────────────────

const List<String> paceList = ['relaxed', 'moderate', 'aggressive'];

const List<String> pregnancyStatusList = [
  'none',
  'pregnant',
  'breastfeeding',
  'planning',
];

const List<String> dietaryPatternList = [
  'omnivore',
  'vegetarian',
  'vegan',
  'pescatarian',
  'keto',
  'lowCarb',
  'mediterranean',
  'halal',
  'kosher',
];

const List<String> dislikedFoodsList = [
  'pork',
  'beef',
  'redMeat',
  'lamb',
  'chicken',
  'fishDislike',
  'shellfishDislike',
  'dairyDislike',
  'eggsDislike',
  'mushrooms',
  'olives',
  'onions',
  'spicy',
  'cilantro',
  'sweets',
  'processed',
  'fried',
];

const List<String> cuisinePreferenceList = [
  'mixed',
  'kurdish',
  'arabic',
  'mediterranean',
  'asian',
  'western',
];

const List<String> mealsPerDayList = ['two', 'three', 'four', 'five'];

const List<String> fastingWindowList = [
  'fastingNone',
  'fasting12',
  'fasting14',
  'fasting16',
  'fasting18',
  'fasting20',
];

const List<String> stressLevelList = ['stressLow', 'stressMedium', 'stressHigh'];

const List<String> workoutTypeList = [
  'workoutNone',
  'workoutCardio',
  'workoutStrength',
  'workoutBoth',
  'workoutSport',
];

const List<String> cookingSkillList = [
  'cookingBeginner',
  'cookingIntermediate',
  'cookingAdvanced',
];

const List<String> cookingTimeList = [
  'cookingTimeUnder15',
  'cookingTimeUnder30',
  'cookingTimeUnder60',
  'cookingTimeAny',
];
