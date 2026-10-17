import 'dart:async';
import 'dart:convert';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/constants/food_serving_switch.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/services/barcode_local_cache.dart';
import 'package:nutrify/utils/food_search_match.dart';

enum BarcodeLookupFailure {
  invalidBarcode,
  offline,
  notFound,
  networkError,
}

class BarcodeLookupResult {
  final BarcodeFoodLookup? lookup;
  final BarcodeLookupFailure? failure;
  final String? resolvedBarcode;

  const BarcodeLookupResult._({
    this.lookup,
    this.failure,
    this.resolvedBarcode,
  });

  BarcodeLookupResult.success(BarcodeFoodLookup lookup, {String? resolvedBarcode})
      : this._(lookup: lookup, resolvedBarcode: resolvedBarcode ?? lookup.barcode);

  const BarcodeLookupResult.failure(BarcodeLookupFailure failure, {String? resolvedBarcode})
      : this._(failure: failure, resolvedBarcode: resolvedBarcode);

  bool get isSuccess => lookup != null;
}

/// Looks up packaged foods by barcode using multiple free databases + local food DB.
class FoodBarcodeService {
  /// Optional transport injection for isolated previews/tests. Normal builds
  /// keep the existing HTTP transport; demo builds supply an in-memory client.
  static http.Client? clientOverride;

  Future<http.Response> _get(Uri uri) => clientOverride != null
      ? clientOverride!.get(uri, headers: _httpHeaders)
      : http.get(uri, headers: _httpHeaders);
  static const _offV2Base = 'https://world.openfoodfacts.org/api/v2/product';
  static const _offV0Base = 'https://world.openfoodfacts.org/api/v0/product';
  static const _offSearchBase = 'https://world.openfoodfacts.org/api/v2/search';
  static const _offCgiSearch = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const _upcItemDbBase = 'https://api.upcitemdb.com/prod/trial/lookup';

  static const _httpHeaders = {
    'User-Agent': 'BNYAD/1.0 (nutrition app; contact@bnyad.app)',
    'Accept': 'application/json',
  };

  final BarcodeLocalCache _cache = BarcodeLocalCache();
  bool _cacheReady = false;

  Future<void> _ensureCache() async {
    if (_cacheReady) return;
    await _cache.load();
    _cacheReady = true;
  }

  Future<BarcodeLookupResult> lookup(String rawBarcode, {required bool isOnline}) async {
    await _ensureCache();

    final candidates = barcodeLookupCandidates(rawBarcode);
    if (candidates.isEmpty) {
      return const BarcodeLookupResult.failure(BarcodeLookupFailure.invalidBarcode);
    }

    final primary = candidates.first;

    // Device cache (includes previously resolved OFF / manual entries).
    for (final barcode in candidates) {
      final cached = _cache.get(barcode);
      if (cached != null) {
        return BarcodeLookupResult.success(cached, resolvedBarcode: barcode);
      }
    }

    for (final barcode in candidates) {
      final local = _lookupBuiltInLocal(barcode);
      if (local != null) {
        await _rememberAll(candidates, local);
        return BarcodeLookupResult.success(local, resolvedBarcode: barcode);
      }
    }

    if (!isOnline) {
      return BarcodeLookupResult.failure(
        BarcodeLookupFailure.offline,
        resolvedBarcode: primary,
      );
    }

    // Parallel direct barcode lookups (Open Food Facts — all endpoints at once).
    final direct = await _firstSuccessful([
      for (final barcode in candidates) ..._directOffFutures(barcode),
    ], timeout: const Duration(seconds: 18));

    if (direct != null) {
      await _rememberAll(candidates, direct);
      return BarcodeLookupResult.success(direct, resolvedBarcode: direct.barcode);
    }

    // Product metadata → name search → local food DB (covers many regional products).
    final metadata = await _lookupUpcItemDb(primary);
    if (metadata != null) {
      final searchQuery = _productSearchQuery(metadata.title, metadata.brand);
      if (searchQuery != null) {
        final byName = await _lookupOpenFoodFactsByName(searchQuery);
        if (byName != null) {
          final resolved = byName.copyWithBarcode(primary);
          await _rememberAll(candidates, resolved);
          return BarcodeLookupResult.success(resolved, resolvedBarcode: primary);
        }

        final localMatch = bestLocalFoodMatch(searchQuery);
        if (localMatch != null) {
          final resolved = BarcodeFoodLookup.fromFoodItem(
            barcode: primary,
            food: localMatch,
            source: 'local_db_name_match',
          );
          await _rememberAll(candidates, resolved);
          return BarcodeLookupResult.success(resolved, resolvedBarcode: primary);
        }
      }
    }

    // Last resort: try OFF text search using digits-only barcode as query.
    final digitSearch = await _lookupOpenFoodFactsByName(primary);
    if (digitSearch != null) {
      final resolved = digitSearch.copyWithBarcode(primary);
      await _rememberAll(candidates, resolved);
      return BarcodeLookupResult.success(resolved, resolvedBarcode: primary);
    }

    return BarcodeLookupResult.failure(
      BarcodeLookupFailure.notFound,
      resolvedBarcode: primary,
    );
  }

  Future<void> remember(String barcode, BarcodeFoodLookup lookup) async {
    await _ensureCache();
    await _cache.put(barcode, lookup);
  }

  Future<void> _rememberAll(List<String> barcodes, BarcodeFoodLookup lookup) async {
    await _ensureCache();
    for (final code in barcodes) {
      if (code == lookup.barcode) {
        await _cache.put(code, lookup);
      } else {
        await _cache.put(code, lookup.copyWithBarcode(code));
      }
    }
  }

  List<Future<BarcodeFoodLookup?>> _directOffFutures(String barcode) => [
        _lookupOpenFoodFactsProduct(barcode, useV0: false),
        _lookupOpenFoodFactsProduct(barcode, useV0: true),
        _lookupOpenFoodFactsSearchByCode(barcode),
        _lookupOpenFoodFactsCgiByCode(barcode),
      ];

  /// Normalizes scanner output into barcode strings to try against databases.
  static List<String> barcodeLookupCandidates(String raw) {
    final digits = normalizeDigits(raw).replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return [];

    final out = <String>[];
    void add(String value) {
      if (value.length >= 8 && !out.contains(value)) out.add(value);
    }

    add(digits);
    if (digits.length == 12) add('0$digits');
    if (digits.length == 13 && digits.startsWith('0')) add(digits.substring(1));
    if (digits.length == 13) add('0$digits');
    if (digits.length == 14 && digits.startsWith('0')) add(digits.substring(1));
    final stripped = digits.replaceFirst(RegExp(r'^0+'), '');
    if (stripped.length >= 8) add(stripped);
    return out;
  }

  /// Best match from the in-app food catalog by product title / brand text.
  @visibleForTesting
  static FoodItem? bestLocalFoodMatch(String query) {
    final q = query.trim();
    if (q.length < 3) return null;

    final normalizedQuery = normalizeForFoodSearch(q);
    if (normalizedQuery.length < 3) return null;

    FoodItem? best;
    var bestScore = 0;

    for (final food in foodDatabase) {
      final score = _scoreFoodMatch(food, normalizedQuery, q);
      if (score > bestScore) {
        bestScore = score;
        best = food;
      }
    }

    // Require a reasonably confident match (avoids random hits on short names).
    if (bestScore >= 4) return best;
    return null;
  }

  static int _scoreFoodMatch(FoodItem food, String normalizedQuery, String rawQuery) {
    var score = 0;
    for (final field in [food.name, food.nameAr, food.nameKu]) {
      if (field == null || field.trim().isEmpty) continue;
      if (foodSearchFieldMatches(field, normalizedQuery)) {
        score += 5;
        final nf = normalizeForFoodSearch(field);
        if (nf == normalizedQuery) score += 4;
        if (nf.contains(normalizedQuery) || normalizedQuery.contains(nf)) {
          score += 2;
        }
      }
    }
    if (score > 0) {
      score += (20 - food.name.length.clamp(0, 20)) ~/ 5;
    }
    if (rawQuery.split(' ').length >= 2 && score < 6) score -= 1;
    return score;
  }

  static String? _productSearchQuery(String? title, String? brand) {
    final t = title?.trim();
    if (t == null || t.length < 3) return null;
    final b = brand?.trim();
    if (b != null && b.isNotEmpty && !t.toLowerCase().contains(b.toLowerCase())) {
      return '$b $t';
    }
    return t;
  }

  BarcodeFoodLookup? _lookupBuiltInLocal(String barcode) {
    final foodId = localBarcodeToFoodId[barcode];
    if (foodId == null) return null;
    final food = foodById(foodId);
    if (food == null) return null;
    return BarcodeFoodLookup.fromFoodItem(barcode: barcode, food: food, source: 'local_map');
  }

  Future<BarcodeFoodLookup?> _lookupOpenFoodFactsProduct(String barcode, {required bool useV0}) async {
    try {
      final base = useV0 ? _offV0Base : _offV2Base;
      final uri = Uri.parse('$base/$barcode.json');
      final response = await _get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      if (!_offProductFound(root)) return null;

      final product = root['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      return _lookupFromOffProduct(barcode, product, source: useV0 ? 'off_v0' : 'off_v2');
    } catch (e) {
      debugPrint('OFF product lookup failed ($barcode): $e');
      return null;
    }
  }

  Future<BarcodeFoodLookup?> _lookupOpenFoodFactsSearchByCode(String barcode) async {
    try {
      final uri = Uri.parse(_offSearchBase).replace(queryParameters: {
        'code': barcode,
        'page_size': '3',
        'fields': 'code,product_name,product_name_en,product_name_ar,product_name_fr,brands,nutriments,serving_size,serving_quantity,product_quantity',
      });
      final response = await _get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final products = root['products'] as List<dynamic>? ?? const [];
      for (final p in products) {
        if (p is! Map) continue;
        final lookup = _lookupFromOffProduct(barcode, Map<String, dynamic>.from(p), source: 'off_search');
        if (lookup != null) return lookup;
      }
      return null;
    } catch (e) {
      debugPrint('OFF code search failed ($barcode): $e');
      return null;
    }
  }

  Future<BarcodeFoodLookup?> _lookupOpenFoodFactsCgiByCode(String barcode) async {
    try {
      final uri = Uri.parse(_offCgiSearch).replace(queryParameters: {
        'action': 'process',
        'json': '1',
        'code': barcode,
        'page_size': '3',
      });
      final response = await _get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final products = root['products'] as List<dynamic>? ?? const [];
      for (final p in products) {
        if (p is! Map) continue;
        final lookup = _lookupFromOffProduct(barcode, Map<String, dynamic>.from(p), source: 'off_cgi');
        if (lookup != null) return lookup;
      }
      return null;
    } catch (e) {
      debugPrint('OFF CGI search failed ($barcode): $e');
      return null;
    }
  }

  Future<BarcodeFoodLookup?> _lookupOpenFoodFactsByName(String searchTerms) async {
    if (searchTerms.trim().length < 3) return null;
    try {
      final uri = Uri.parse(_offSearchBase).replace(queryParameters: {
        'search_terms': searchTerms,
        'page_size': '5',
        'sort_by': 'unique_scans_n',
        'fields': 'code,product_name,product_name_en,product_name_ar,brands,nutriments,serving_size,serving_quantity,product_quantity',
      });
      final response = await _get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final products = root['products'] as List<dynamic>? ?? const [];
      for (final p in products) {
        if (p is! Map) continue;
        final product = Map<String, dynamic>.from(p);
        final code = (product['code'] as String?) ?? (product['_id'] as String?) ?? '';
        if (code.isEmpty) continue;
        final lookup = _lookupFromOffProduct(code, product, source: 'off_name_search');
        if (lookup != null) return lookup;
      }
      return null;
    } catch (e) {
      debugPrint('OFF name search failed ($searchTerms): $e');
      return null;
    }
  }

  Future<({String title, String? brand})?> _lookupUpcItemDb(String barcode) async {
    try {
      final uri = Uri.parse(_upcItemDbBase).replace(queryParameters: {'upc': barcode});
      final response = await _get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      if (root['code'] != 'OK') return null;

      final items = root['items'] as List<dynamic>? ?? const [];
      if (items.isEmpty) return null;

      final item = Map<String, dynamic>.from(items.first as Map);
      final title = (item['title'] as String?)?.trim();
      if (title == null || title.isEmpty) return null;
      final brand = (item['brand'] as String?)?.trim();
      return (title: title, brand: brand?.isEmpty == true ? null : brand);
    } catch (e) {
      debugPrint('UPC Item DB lookup failed ($barcode): $e');
      return null;
    }
  }

  BarcodeFoodLookup? _lookupFromOffProduct(String barcode, Map<String, dynamic> product, {required String source}) {
    final n = product['nutriments'] as Map<String, dynamic>? ?? {};
    final macros = _parseNutriments(n);
    if (macros == null) return null;

    final name = _bestProductName(product);
    final brand = (product['brands'] as String?)?.trim();
    final serving = product['serving_size'] as String?;
    final defaultGrams = parseDefaultGramsFromOffProduct(product);

    return BarcodeFoodLookup(
      barcode: barcode,
      name: name.isEmpty ? 'Scanned product' : name,
      brand: brand?.isEmpty == true ? null : brand,
      caloriesPer100g: macros.$1,
      proteinPer100g: macros.$2,
      carbsPer100g: macros.$3,
      fatPer100g: macros.$4,
      servingSizeLabel: serving,
      defaultGrams: defaultGrams,
      source: source,
    );
  }

  static String _bestProductName(Map<String, dynamic> product) {
    for (final key in [
      'product_name',
      'product_name_en',
      'product_name_ar',
      'product_name_fr',
      'generic_name',
      'generic_name_en',
      'abbreviated_product_name',
    ]) {
      final v = (product[key] as String?)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return 'Scanned product';
  }

  @visibleForTesting
  static double? parseDefaultGramsFromOffProduct(Map<String, dynamic> product) {
    final sq = product['serving_quantity'];
    if (sq is num && sq > 0) return sq.toDouble();

    final pq = product['product_quantity'];
    if (pq is num && pq > 0) return pq.toDouble();

    final label = product['serving_size'] as String?;
    if (label == null) return null;
    return parseGramsFromServingLabel(label);
  }

  @visibleForTesting
  static double? parseGramsFromServingLabel(String label) {
    final normalized = label.toLowerCase().replaceAll(',', '.');
    final gMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g\b').firstMatch(normalized);
    if (gMatch != null) return double.tryParse(gMatch.group(1)!);

    final mlMatch = RegExp(r'(\d+(?:\.\d+)?)\s*ml\b').firstMatch(normalized);
    if (mlMatch != null) return double.tryParse(mlMatch.group(1)!);

    final bare = RegExp(r'^(\d+(?:\.\d+)?)\s*$').firstMatch(normalized.trim());
    if (bare != null) return double.tryParse(bare.group(1)!);

    return null;
  }

  bool _offProductFound(Map<String, dynamic> root) {
    final status = root['status'];
    if (status == 1 || status == '1') return true;
    final verbose = (root['status_verbose'] as String?)?.toLowerCase() ?? '';
    if (verbose.contains('product found')) return true;
    return root['product'] is Map<String, dynamic>;
  }

  (double, double, double, double)? _parseNutriments(Map<String, dynamic> n) {
    double pick(List<String> keys) {
      for (final key in keys) {
        final v = n[key];
        if (v is num) return v.toDouble();
        final parsed = double.tryParse('$v');
        if (parsed != null) return parsed;
      }
      return 0;
    }

    var kcal = pick([
      'energy-kcal_100g',
      'energy-kcal',
      'energy-kcal_serving',
      'energy-kcal_value',
    ]);
    if (kcal <= 0) {
      final kj = pick(['energy_100g', 'energy', 'energy-kj_100g', 'energy-kj']);
      if (kj > 0) kcal = kj / 4.184;
    }

    final protein = pick(['proteins_100g', 'proteins', 'protein_100g', 'proteins_serving']);
    final carbs = pick(['carbohydrates_100g', 'carbohydrates', 'carbohydrates_serving']);
    final fat = pick(['fat_100g', 'fat', 'fat_serving']);

    if (kcal <= 0 && (protein > 0 || carbs > 0 || fat > 0)) {
      kcal = (protein * 4) + (carbs * 4) + (fat * 9);
    }

    if (kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) return null;
    return (kcal, protein, carbs, fat);
  }

  /// Returns the first non-null result from [futures], or null if all fail/timeout.
  static Future<T?> _firstSuccessful<T>(Iterable<Future<T?>> futures, {required Duration timeout}) async {
    if (futures.isEmpty) return null;

    final completer = Completer<T?>();
    var pending = futures.length;

    void onDone(T? value) {
      if (value != null && !completer.isCompleted) {
        completer.complete(value);
      }
      pending--;
      if (pending == 0 && !completer.isCompleted) {
        completer.complete(null);
      }
    }

    for (final future in futures) {
      future.then(onDone).catchError((_) => onDone(null));
    }

    try {
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }
}

extension on BarcodeFoodLookup {
  BarcodeFoodLookup copyWithBarcode(String barcode) {
    return BarcodeFoodLookup(
      barcode: barcode,
      name: name,
      brand: brand,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      servingSizeLabel: servingSizeLabel,
      defaultGrams: defaultGrams,
      fromLocalDatabase: fromLocalDatabase,
      localFoodId: localFoodId,
      source: source,
    );
  }
}

/// Optional: map common regional barcodes to in-app [FoodItem.id]s.
const Map<String, String> localBarcodeToFoodId = {
  // Add product barcodes here as you collect them, e.g.:
  // '8690632001234': 'b14',
};
