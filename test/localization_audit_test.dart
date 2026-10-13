import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/l10n/app_localizations.dart';

Map<String, String> flatten(Map<String, dynamic> map, [String prefix = '']) {
  final out = <String, String>{};
  for (final e in map.entries) {
    final key = '$prefix${e.key}';
    if (e.value is Map<String, dynamic>) {
      out.addAll(flatten(e.value as Map<String, dynamic>, '$key.'));
    } else if (e.value is List) {
      final items = e.value as List;
      for (var i = 0; i < items.length; i++) {
        out['$key.$i'] = '${items[i]}';
      }
    } else {
      out[key] = '${e.value}';
    }
  }
  return out;
}

void main() {
  test(
    'English, Arabic and Sorani have complete matching translation coverage',
    () {
      final en = flatten(AppLocalizations.translationsFor('en'));
      for (final language in ['ar', 'ku', 'ckb']) {
        final translated = flatten(AppLocalizations.translationsFor(language));
        expect(translated.keys.toSet(), en.keys.toSet(), reason: language);
        for (final entry in en.entries) {
          expect(
            translated[entry.key]!.trim(),
            isNotEmpty,
            reason: '$language/${entry.key}',
          );
          final placeholders = RegExp(r'\{\w+\}');
          expect(
            placeholders
                .allMatches(translated[entry.key]!)
                .map((m) => m[0])
                .toSet(),
            placeholders.allMatches(entry.value).map((m) => m[0]).toSet(),
            reason: '$language/${entry.key}',
          );
        }
      }
    },
  );
  test('canonical Sorani and legacy ku have identical content and RTL', () {
    expect(
      AppLocalizations.translationsFor('ckb'),
      AppLocalizations.translationsFor('ku'),
    );
    expect(AppLocalizations('ckb').isRTL, true);
    expect(AppLocalizations('ar').isRTL, true);
    expect(AppLocalizations('en').isRTL, false);
  });
  test(
    'Sorani login and connection errors never leak English backend text',
    () {
      final t = AppLocalizations('ckb');
      for (final message in [
        'Incorrect phone number or password.',
        'Network error',
        'Too many attempts.',
        'The verification code has expired.',
        'Unexpected failure',
      ]) {
        expect(t.localizeError(message), isNot(message));
        expect(
          RegExp(r'[\u0600-\u06ff]').hasMatch(t.localizeError(message)),
          true,
        );
      }
    },
  );
}
