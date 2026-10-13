import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';

/// User-saved barcode → nutrition mappings (device storage).
class BarcodeLocalCache {
  static const _prefsKey = 'barcode_custom_lookups_v1';

  Map<String, BarcodeFoodLookup> _entries = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _entries = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _entries = decoded.map(
        (key, value) => MapEntry(
          key,
          BarcodeFoodLookup.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      _entries = {};
    }
  }

  BarcodeFoodLookup? get(String barcode) => _entries[barcode];

  Future<void> put(String barcode, BarcodeFoodLookup lookup) async {
    _entries[barcode] = lookup;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_prefsKey, encoded);
  }
}
