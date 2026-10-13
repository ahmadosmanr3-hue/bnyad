/// Normalize labels so "Tomato  ", "tomato", "tomato." match.
String normalizeShoppingName(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  s = s.toLowerCase();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'[.,;:!?،؟٫٬]+$'), '');
  return s.trim();
}

enum ShoppingItemAddOutcome { empty, duplicate, added }

/// Result of bulk add (e.g. from meal plan or AI).
class ShoppingBulkAddResult {
  final int addedCount;
  final int skippedDuplicateCount;
  final int skippedEmptyCount;

  const ShoppingBulkAddResult({
    required this.addedCount,
    required this.skippedDuplicateCount,
    required this.skippedEmptyCount,
  });

  bool get anyChange => addedCount > 0;
}
