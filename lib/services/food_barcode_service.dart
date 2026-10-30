import 'dart:convert';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/barcode_local_cache.dart';

enum BarcodeLookupFailure { invalidBarcode, offline, notFound, networkError }

class BarcodeLookupResult {
  final BarcodeFoodLookup? lookup;
  final BarcodeLookupFailure? failure;
  final String? resolvedBarcode;
  const BarcodeLookupResult._({
    this.lookup,
    this.failure,
    this.resolvedBarcode,
  });
  BarcodeLookupResult.success(
    BarcodeFoodLookup value, {
    String? resolvedBarcode,
  }) : this._(lookup: value, resolvedBarcode: resolvedBarcode ?? value.barcode);
  const BarcodeLookupResult.failure(
    BarcodeLookupFailure value, {
    String? resolvedBarcode,
  }) : this._(failure: value, resolvedBarcode: resolvedBarcode);
  bool get isSuccess => lookup != null;
}

/// Exact barcode → authenticated backend → provider cache. No name substitution,
/// direct provider fanout, AI call, external API key or guessed nutrition.
class FoodBarcodeService {
  final ApiService? api;
  FoodBarcodeService({this.api});
  final BarcodeLocalCache _cache = BarcodeLocalCache();
  bool _ready = false;
  Future<void> _load() async {
    if (!_ready) {
      await _cache.load();
      _ready = true;
    }
  }

  Future<BarcodeLookupResult> lookup(
    String rawBarcode, {
    required bool isOnline,
    String? format,
  }) async {
    final codes = barcodeLookupCandidates(rawBarcode, format: format);
    if (codes.isEmpty) {
      return const BarcodeLookupResult.failure(
        BarcodeLookupFailure.invalidBarcode,
      );
    }
    await _load();
    for (final code in codes) {
      final saved = _cache.get(code);
      // Keep explicit user mappings, discard old automatic fuzzy/unknown-basis results.
      if (saved != null &&
          saved.isValid &&
          (saved.source == 'manual' ||
              (saved.fromLocalDatabase &&
                  [null, 'local_db'].contains(saved.source)))) {
        return BarcodeLookupResult.success(saved, resolvedBarcode: code);
      }
    }
    if (!isOnline) {
      return BarcodeLookupResult.failure(
        BarcodeLookupFailure.offline,
        resolvedBarcode: codes.first,
      );
    }
    if (api == null) {
      return BarcodeLookupResult.failure(
        BarcodeLookupFailure.networkError,
        resolvedBarcode: codes.first,
      );
    }
    try {
      final response = await api!.getBarcodeProduct(codes.first);
      if (response.statusCode == 404) {
        return BarcodeLookupResult.failure(
          BarcodeLookupFailure.notFound,
          resolvedBarcode: codes.first,
        );
      }
      if (response.statusCode != 200) {
        return BarcodeLookupResult.failure(
          BarcodeLookupFailure.networkError,
          resolvedBarcode: codes.first,
        );
      }
      final data = (jsonDecode(response.body) as Map<String, dynamic>)['data'];
      final product = BarcodeFoodLookup.fromBackend(
        Map<String, dynamic>.from(data as Map),
      );
      final productCodes = barcodeLookupCandidates(product.barcode);
      if (!product.isValid ||
          !productCodes.any(
            (c) => c.padLeft(14, '0') == codes.first.padLeft(14, '0'),
          )) {
        return BarcodeLookupResult.failure(
          BarcodeLookupFailure.networkError,
          resolvedBarcode: codes.first,
        );
      }
      return BarcodeLookupResult.success(product);
    } catch (_) {
      return BarcodeLookupResult.failure(
        BarcodeLookupFailure.networkError,
        resolvedBarcode: codes.first,
      );
    }
  }

  Future<void> remember(String code, BarcodeFoodLookup lookup) async {
    if (!lookup.isValid) throw ArgumentError('Invalid label nutrition');
    await _load();
    for (final candidate in barcodeLookupCandidates(code)) {
      await _cache.put(candidate, lookup);
    }
  }

  static bool validGtin(String code) {
    if (!RegExp(r'^(?:\d{8}|\d{12}|\d{13}|\d{14})$').hasMatch(code)) {
      return false;
    }
    var sum = 0, weight = 3;
    for (var i = code.length - 2; i >= 0; i--) {
      sum += int.parse(code[i]) * weight;
      weight = 4 - weight;
    }
    return (10 - sum % 10) % 10 == int.parse(code[code.length - 1]);
  }

  static String? expandUpce(String code) {
    if (!RegExp(r'^[01]\d{7}$').hasMatch(code)) return null;
    final d = code.substring(1, 7), n = code[0], last = d[5];
    final body = int.parse(last) <= 2
        ? '$n${d.substring(0, 2)}${last}0000${d.substring(2, 5)}'
        : last == '3'
        ? '$n${d.substring(0, 3)}00000${d.substring(3, 5)}'
        : last == '4'
        ? '$n${d.substring(0, 4)}00000${d[4]}'
        : '$n${d.substring(0, 5)}0000$last';
    final result = body + code[7];
    return validGtin(result) ? result : null;
  }

  static List<String> barcodeLookupCandidates(String raw, {String? format}) {
    var code = normalizeDigits(raw).trim();
    final gs1 = RegExp(r'^\(01\)(\d{14})$').firstMatch(code);
    if (gs1 != null) {
      code = gs1[1]!;
    } else if (!RegExp(r'^[\d\s-]+$').hasMatch(code)) {
      return [];
    }
    code = code.replaceAll(RegExp(r'[\s-]'), '');
    if (format == 'upcE') code = expandUpce(code) ?? '';
    if (!validGtin(code)) return [];
    return {
      if (code.length == 12) '0$code',
      code,
      if (code.length == 13 && code.startsWith('0')) code.substring(1),
      if (code.length == 14 && code.startsWith('0')) code.substring(1),
    }.toList();
  }

  /// Explicit search suggestion only; never automatically assigned to a barcode.
  static FoodItem? bestLocalFoodMatch(String query) {
    if (query.trim().length < 3) return null;
    for (final food in foodDatabase) {
      if (food.matchesSearchQuery(query)) return food;
    }
    return null;
  }

  static double? parseGramsFromServingLabel(String text) {
    final m = RegExp(
      r'(\d+(?:\.\d+)?)\s*g\b',
    ).firstMatch(normalizeDecimal(text).toLowerCase());
    return m == null ? null : double.tryParse(m[1]!);
  }
}
