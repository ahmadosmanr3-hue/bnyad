import 'package:flutter/services.dart';

/// Input normalization only: calculations and persisted numeric values are unchanged.
String normalizeDigits(String value) => String.fromCharCodes(
  value.runes.map((c) {
    if (c >= 0x660 && c <= 0x669) return c - 0x660 + 48;
    if (c >= 0x6f0 && c <= 0x6f9) return c - 0x6f0 + 48;
    return c;
  }),
);

String normalizeDecimal(String value) {
  var text = normalizeDigits(value).trim();
  // Accept explicitly grouped Arabic thousands, never silently strip malformed groups.
  if (text.contains('٬')) {
    if (!RegExp(r'^[+-]?\d{1,3}(٬\d{3})+(?:[٫.]\d+)?$').hasMatch(text)) {
      return '';
    }
    text = text.replaceAll('٬', '');
  }
  return text.replaceAll('٫', '.').replaceAll(',', '.');
}

double? parseLocalizedDouble(String value) {
  final parsed = double.tryParse(normalizeDecimal(value));
  return parsed != null && parsed.isFinite ? parsed : null;
}

int? parseLocalizedInt(String value) =>
    int.tryParse(normalizeDigits(value).trim());

/// Normalize before existing ASCII filters and max-length validation run.
class LocalizedDigitsFormatter extends TextInputFormatter {
  const LocalizedDigitsFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: normalizeDigits(newValue.text));
}

/// Unicode LTR isolate: numeric order stays stable inside a translated RTL sentence.
/// Never use this to reverse the containing layout or change stored values.
String ltrFragment(String value) => '\u2066$value\u2069';

String internalLanguage(String language) => language == 'ckb' ? 'ku' : language;
