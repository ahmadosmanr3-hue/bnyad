import 'package:nutrify/utils/ai_trilingual_strings.dart';

/// Provider totals are per 100g; component micros are absolute for their
/// original portion. Never invent missing micronutrients or mix these bases.
Map<String, double> scaledAiScanMicros(
  Map<String, dynamic> scan,
  double grams,
  List<double>? componentGrams,
) {
  final components = parseAiFoodComponents(scan);
  final result = <String, double>{};
  if (components.isNotEmpty &&
      componentGrams != null &&
      components.length == componentGrams.length) {
    for (var i = 0; i < components.length; i++) {
      final base = (components[i]['grams'] as num?)?.toDouble() ?? 0;
      final raw = components[i]['micros'];
      if (base <= 0 || raw is! Map) continue;
      for (final e in raw.entries) {
        if (e.value is num &&
            (e.value as num).isFinite &&
            (e.value as num) >= 0) {
          result[e.key.toString()] =
              (result[e.key] ?? 0) +
              (e.value as num).toDouble() * componentGrams[i] / base;
        }
      }
    }
    return result;
  }
  final raw = scan['micros'];
  if (raw is Map) {
    for (final e in raw.entries) {
      if (e.value is num && (e.value as num).isFinite && (e.value as num) >= 0) {
        result[e.key.toString()] = (e.value as num).toDouble() * grams / 100;
      }
    }
  }
  return result;
}
