// Helpers for food search across English / Arabic / Kurdish (spacing + light typo tolerance).

/// Collapses whitespace, strips invisible joiners, folds common Arabic-script variants, lowercases Latin.
String normalizeForFoodSearch(String input) {
  if (input.isEmpty) return '';
  var s = input.replaceAll(RegExp(r'[\u200c\u200d\ufeff\u200b]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    buf.write(_foldArabicScriptChar(ch));
  }
  return buf.toString().toLowerCase();
}

String _foldArabicScriptChar(String ch) {
  switch (ch) {
    case 'أ':
    case 'إ':
    case 'آ':
    case 'ٱ':
      return 'ا';
    case 'ة':
      return 'ه';
    case 'ؤ':
      return 'و';
    case 'ك':
      return 'ک';
    case 'ى':
    case 'ي':
    case 'ئ':
      return 'ی';
    case '٫':
    case '٬':
      return '.';
    default:
      return ch;
  }
}

int _min3(int a, int b, int c) {
  if (a <= b && a <= c) return a;
  if (b <= c) return b;
  return c;
}

/// Levenshtein distance (UTF-16 code units; fine for Arabic BMP text).
int levenshtein(String a, String b) {
  final la = a.length;
  final lb = b.length;
  if (la == 0) return lb;
  if (lb == 0) return la;
  final dp = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
  for (var i = 0; i <= la; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= lb; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= la; i++) {
    for (var j = 1; j <= lb; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = _min3(
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      );
    }
  }
  return dp[la][lb];
}

int _maxEditForToken(int tokenLen) {
  if (tokenLen < 3) return 0;
  if (tokenLen <= 6) return 1;
  return 2;
}

Iterable<String> _words(String normalizedHaystack) sync* {
  for (final w in normalizedHaystack.split(RegExp(r'\s+'))) {
    final t = w.trim();
    if (t.isEmpty) continue;
    yield t;
  }
}

bool _fuzzyTokenMatch(String token, String word) {
  if (token.isEmpty) return true;
  if (token == word) return true;
  if (word.contains(token) || token.contains(word)) return true;
  final maxE = _maxEditForToken(token.length);
  if (maxE == 0) return false;
  return levenshtein(token, word) <= maxE;
}

bool _tokenMatchesInHaystack(String token, String hayNorm) {
  if (hayNorm.contains(token)) return true;
  if (token.length < 3) return false;
  for (final w in _words(hayNorm)) {
    if (_fuzzyTokenMatch(token, w)) return true;
  }
  return false;
}

/// Whether [rawField] matches [normalizedQuery] (already [normalizeForFoodSearch]'d).
bool foodSearchFieldMatches(String? rawField, String normalizedQuery) {
  if (rawField == null || rawField.trim().isEmpty) return false;
  final h = normalizeForFoodSearch(rawField);
  if (h.isEmpty) return false;
  if (normalizedQuery.isEmpty) return true;
  if (h.contains(normalizedQuery)) return true;

  if (normalizedQuery.length >= 4 && (normalizedQuery.length - h.length).abs() <= 4) {
    if (levenshtein(normalizedQuery, h) <= 2) return true;
  }

  final tokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return true;
  if (tokens.length == 1) {
    final t = tokens.first;
    if (t.length < 2) return h.contains(t);
    return _tokenMatchesInHaystack(t, h);
  }
  return tokens.every((t) => _tokenMatchesInHaystack(t, h));
}
