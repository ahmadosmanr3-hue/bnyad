import 'package:nutrify/constants/food_database.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/constants/food_group_registry.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/services/api_service.dart';

/// Bundled fallback, scoped disk cache, then public server snapshot. No user data.
class FoodCatalog extends ChangeNotifier {
  FoodCatalog(this.api);
  final ApiService api;
  List<Map<String, dynamic>> categories = [];
  Map<String, FoodItem> foods = {};
  Set<String> disabled = {};
  bool loading = false, offline = false;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void>? _load;
  DateTime? _lastRefresh;
  int? revision;
  String get _cacheKey => 'food_catalog_v1_${api.baseUrl}';
  Future<void> load({bool refresh = false}) {
    if (_load != null) return _load!;
    if (!refresh &&
        _lastRefresh != null &&
        DateTime.now().difference(_lastRefresh!) < const Duration(minutes: 2)) {
      return Future.value();
    }
    return _load = _read().whenComplete(() => _load = null);
  }

  void accept(Map<String, dynamic> data) {
    if (_disposed) return;
    if (data['schemaVersion'] != 1 ||
        data['foods'] is! List ||
        data['categories'] is! List) {
      throw const FormatException('Unsupported catalog');
    }
    final rows = data['foods'] as List;
    if (rows.length > 10000) throw const FormatException('Oversized catalog');
    final parsed = <String, FoodItem>{};
    for (final row in rows) {
      final food = FoodItem.fromJson(Map<String, dynamic>.from(row));
      if (food.id.isEmpty ||
          !food.isTrilingual ||
          food.nutritionReferenceG <= 0 ||
          ![
            food.calories,
            food.protein,
            food.carbs,
            food.fat,
            food.nutritionReferenceG,
          ].every((n) => n.isFinite && n >= 0)) {
        throw const FormatException('Invalid catalog nutrition');
      }
      parsed[food.id] = food;
    }
    final cats = (data['categories'] as List)
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    final hidden = (data['disabledIds'] as List? ?? [])
        .whereType<String>()
        .toSet();
    revision = (data['revision'] as num?)?.toInt();
    foods = parsed;
    categories = cats;
    disabled = hidden;
    FoodItem.catalogOverrides = foods;
    _notify();
  }

  Future<void> _read() async {
    loading = true;
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (foods.isEmpty) {
        accept(
          jsonDecode(
            await rootBundle.loadString('assets/catalog/catalog.json'),
          ),
        );
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          try {
            accept(jsonDecode(cached));
          } catch (_) {
            await prefs.remove(_cacheKey);
          }
        }
      }
      final response = await api.readFoodCatalog(
        etag: revision == null ? null : '"catalog-v1-$revision"',
      );
      if (response != null) {
        if (response['notModified'] != true) {
          accept(response);
          await prefs.setString(_cacheKey, jsonEncode(response));
        }
        offline = false;
      } else {
        offline = true;
      }
      _lastRefresh = DateTime.now();
    } catch (_) {
      offline = true;
    } finally {
      loading = false;
      _notify();
    }
  }

  String categoryName(Map<String, dynamic> c, String lang) =>
      ((c['names'] as Map)[lang == 'ckb' ? 'ku' : lang] ??
              (c['names'] as Map)['en'])
          .toString();
  String labelFor(FoodItem f, String lang) {
    for (final c in categories) {
      if (c['id'] == f.categoryId) return categoryName(c, lang);
    }
    return f.category;
  }

  List<FoodBrowseRow> browse() {
    final result = <FoodBrowseRow>[], seen = <String>{};
    for (final row in foodsForFoodLogBrowse()) {
      final food = foods[row.displayFood.id] ?? row.displayFood;
      if (disabled.contains(food.id) || disabled.contains(food.canonicalKey)) {
        continue;
      }
      seen.add(food.canonicalKey);
      result.add(FoodBrowseRow(displayFood: food, group: row.group));
    }
    final legacyIds = foodDatabase.map((f) => f.id).toSet();
    for (final f in foods.values) {
      // The legacy registry already groups preparations and hides serving aliases.
      // Append only genuinely new entries; never reintroduce hidden variants.
      if (legacyIds.contains(f.id)) continue;
      if (disabled.contains(f.id) ||
          disabled.contains(f.canonicalKey) ||
          !seen.add(f.canonicalKey)) {
        continue;
      }
      result.add(FoodBrowseRow(displayFood: f));
    }
    return result;
  }

  bool categoryMatches(FoodItem f, String? id) {
    if (id == null) return true;
    if (f.categoryId == id) return true;
    return categories.any(
      (c) => c['id'] == f.categoryId && c['parentId'] == id,
    );
  }
}
