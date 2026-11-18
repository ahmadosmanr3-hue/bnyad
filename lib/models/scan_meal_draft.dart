import 'dart:math';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/utils/ai_trilingual_strings.dart';
import 'package:nutrify/utils/food_search_match.dart';

// Same policy as backend lib/scan-review.ts. There are no verified ingredient
// recipes for these prepared catalog dishes; never invent a decomposition.
const preparedScanCategories = {
  'regional-meals',
  'regional-rice',
  'regional-soups',
  'regional-sweets',
  'pizza',
  'shawarma-wraps',
  'prepared-meals',
  'burgers',
  'sandwiches',
  'hot-dogs',
  'salads',
  'breakfast',
  'pasta',
  'fried-chicken',
};

bool validScanFood(FoodItem f) =>
    f.isTrilingual &&
    ['g', 'ml'].contains(f.nutritionUnit) &&
    f.nutritionReferenceG.isFinite &&
    f.nutritionReferenceG > 0 &&
    [f.calories, f.protein, f.carbs, f.fat].every((n) => n.isFinite && n >= 0);

class ScanFoodPortion {
  ScanFoodPortion(this.food, this.amount);
  FoodItem food;
  double? amount;
  Map<String, double> get totals {
    final ratio = (amount ?? 0) / food.nutritionReferenceG;
    return {
      'calories': food.calories * ratio,
      'protein': food.protein * ratio,
      'carbs': food.carbs * ratio,
      'fat': food.fat * ratio,
    };
  }

  Map<String, dynamic> toRequest() => {
    'id': food.id,
    'amount': amount,
    'unit': food.nutritionUnit,
  };
}

class ScanMealDraft {
  ScanMealDraft({required this.title, this.mode = 'components'})
    : requestId = List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
      createdAt = DateTime.now();
  final String requestId;
  final DateTime createdAt;
  String title, mode;
  bool confirmed = false;
  double? weighedGrams;
  final items = <ScanFoodPortion>[];
  final pending = <String>[];
  final candidates = <Map<String, dynamic>>[];

  factory ScanMealDraft.fromScan(
    Map<String, dynamic> scan,
    Map<String, FoodItem> foods,
    Set<String> disabled,
    String lang,
  ) {
    final draft = ScanMealDraft(
      title: trilingualString(
        scan,
        mapKey: 'names',
        legacyKey: 'name',
        lang: lang,
      ),
    );
    final identification = scan['identification'];
    if (identification is Map && identification['candidates'] is List) {
      draft.candidates.addAll(
        (identification['candidates'] as List)
            .whereType<Map>()
            .take(3)
            .map((m) => Map<String, dynamic>.from(m)),
      );
    }
    // Provider macros are never used as a replacement for catalog nutrition.
    for (final row in parseAiFoodComponents(scan)) {
      final f = foods[row['foodId'] ?? row['id']];
      final raw = row['grams'] ?? row['amount'];
      final amount = raw is num ? raw.toDouble() : null;
      if (f == null ||
          !validScanFood(f) ||
          disabled.contains(f.id) ||
          disabled.contains(f.canonicalKey) ||
          amount == null ||
          !amount.isFinite ||
          amount <= 0 ||
          amount > 10000 ||
          (row['unit'] ?? 'g') != f.nutritionUnit ||
          draft.items.any((p) => p.food.canonicalKey == f.canonicalKey)) {
        draft.pending.add(
          trilingualString(row, mapKey: 'names', legacyKey: 'name', lang: lang),
        );
        continue;
      }
      draft.items.add(ScanFoodPortion(f, amount));
    }
    if (draft.items.any(
      (p) => preparedScanCategories.contains(p.food.categoryId),
    )) {
      if (draft.items.length == 1) {
        draft.mode = 'dish';
      } else {
        // A whole dish cannot silently coexist with ingredient totals.
        draft.pending.addAll(
          draft.items.map((p) => p.food.getLocalizedName(lang)),
        );
        draft.items.clear();
      }
    }
    return draft;
  }
  Map<String, double> get totals => {
    for (final key in ['calories', 'protein', 'carbs', 'fat'])
      key: items.fold<double>(0, (sum, p) => sum + p.totals[key]!),
  };
  bool get valid =>
      title.trim().isNotEmpty &&
      title.length <= 200 &&
      items.isNotEmpty &&
      items.length <= 15 &&
      pending.isEmpty &&
      (mode != 'dish' || items.length == 1) &&
      (mode != 'components' ||
          items.every(
            (p) => !preparedScanCategories.contains(p.food.categoryId),
          )) &&
      items.map((p) => p.food.canonicalKey).toSet().length == items.length &&
      items.every(
        (p) =>
            validScanFood(p.food) &&
            p.amount != null &&
            p.amount!.isFinite &&
            p.amount! > 0 &&
            p.amount! <= 10000,
      ) &&
      items
              .where((p) => !p.food.isLiquid)
              .fold<double>(0, (n, p) => n + (p.amount ?? 0)) <=
          2500 &&
      items
              .where((p) => p.food.isLiquid)
              .fold<double>(0, (n, p) => n + (p.amount ?? 0)) <=
          5000;

  Map<String, dynamic> toRequest(int revision, String lang) {
    if (!valid || !confirmed) throw const FormatException('Review required');
    return {
      'requestId': requestId,
      'revision': revision,
      'mode': mode,
      'confirmed': true,
      'title': title.trim(),
      'lang': lang == 'ckb' ? 'ku' : lang,
      'items': items.map((p) => p.toRequest()).toList(),
      'totals': totals,
      'logged_at':
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
      'consumed_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

// Aliases expand *search*, never silently replace an uncertain prepared meal
// with rice/meat. A user must select the exact catalog preparation.
const _regionalSearchGroups = [
  ['biryani', 'biriani', 'بریانی', 'برياني'],
  ['dolma', 'yaprax', 'yaprak', 'دۆڵمە', 'یاپراخ', 'دولمة', 'دولما'],
  ['shawarma', 'شاورما', 'شەوەرمە', 'شاورمە'],
  ['kebab', 'کەباب', 'كباب'],
  ['tikka', 'تکە', 'تكة', 'تیکە'],
  ['stew', 'shla', 'شڵە', 'مرق', 'يخنة'],
  ['soup', 'شۆربا', 'شوربة'],
];
List<FoodItem> scanCatalogMatches(
  Iterable<FoodItem> foods,
  Set<String> disabled,
  Iterable<String> queries,
) {
  final terms = queries
      .map(normalizeForFoodSearch)
      .where((q) => q.isNotEmpty)
      .toSet();
  for (final group in _regionalSearchGroups) {
    if (terms.any(
      (q) => group.any((s) => q.contains(normalizeForFoodSearch(s))),
    )) {
      terms.addAll(group.map(normalizeForFoodSearch));
    }
  }
  final seen = <String>{};
  final result = foods
      .where(
        (f) =>
            validScanFood(f) &&
            !disabled.contains(f.id) &&
            !disabled.contains(f.canonicalKey) &&
            (terms.isEmpty || terms.any(f.matchesSearchQuery)) &&
            seen.add(f.canonicalKey),
      )
      .toList();
  int score(FoodItem f) =>
      [
        f.name,
        f.nameAr ?? '',
        f.nameKu ?? '',
        ...f.synonyms,
      ].map(normalizeForFoodSearch).any(terms.contains)
      ? 0
      : 1;
  result.sort((a, b) {
    final s = score(a).compareTo(score(b));
    return s == 0 ? a.name.compareTo(b.name) : s;
  });
  return result;
}
