// Helpers for AI JSON that may store user-visible text as
// {"en":"...","ar":"...","ku":"..."} with legacy single-string fallbacks.

String normAiLang(String lang) {
  if (lang == 'ar') return 'ar';
  if (lang == 'ku') return 'ku';
  return 'en';
}

String _firstNonEmptyString(Map<String, dynamic> m, Iterable<String> order) {
  for (final k in order) {
    final v = m[k]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}

/// String field: prefer [mapKey] map (en/ar/ku), else [legacyKey] single value.
String trilingualString(
  Map<String, dynamic>? parent, {
  required String mapKey,
  required String legacyKey,
  required String lang,
}) {
  if (parent == null) return '';
  final raw = parent[mapKey];
  if (raw is Map) {
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final k0 = normAiLang(lang);
    final s = _firstNonEmptyString(m, [k0, 'en', 'ar', 'ku']);
    if (s.isNotEmpty) return s;
  }
  final leg = parent[legacyKey]?.toString().trim();
  return leg ?? '';
}

List<String> _parseStringList(dynamic v) {
  if (v is! List) return [];
  return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
}

/// List field: prefer [mapKey] as map of lists, else [legacyKey] as a single list.
List<String> trilingualStringList(
  Map<String, dynamic>? parent, {
  required String mapKey,
  required String legacyKey,
  required String lang,
}) {
  if (parent == null) return [];
  final raw = parent[mapKey];
  if (raw is Map) {
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final k0 = normAiLang(lang);
    for (final k in [k0, 'en', 'ar', 'ku']) {
      final list = _parseStringList(m[k]);
      if (list.isNotEmpty) return list;
    }
  }
  return _parseStringList(parent[legacyKey]);
}

/// Top-level list or trilingual map (e.g. detected items).
List<String> trilingualRootStringList(
  Map<String, dynamic>? root, {
  required String mapKey,
  required String legacyKey,
  required String lang,
}) {
  if (root == null) return [];
  final raw = root[mapKey];
  if (raw is Map) {
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final k0 = normAiLang(lang);
    for (final k in [k0, 'en', 'ar', 'ku']) {
      final list = _parseStringList(m[k]);
      if (list.isNotEmpty) return list;
    }
  }
  return _parseStringList(root[legacyKey]);
}

/// Component rows from food-scan AI JSON (composite dishes).
List<Map<String, dynamic>> parseAiFoodComponents(Map<String, dynamic>? scan) {
  if (scan == null) return [];
  final raw = scan['components'];
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .where((c) {
        final name = trilingualString(c, mapKey: 'names', legacyKey: 'name', lang: 'en');
        return name.isNotEmpty || (c['grams'] as num? ?? 0) > 0;
      })
      .toList();
}
