/// Select authored translations on every render so changing language updates the
/// cached inbox too. Legacy/admin/user content is preserved, never guessed.
String notificationText(
  Map<String, dynamic> note,
  String field,
  String language,
) {
  final translations = note['translations'];
  final lang = language == 'ku' ? 'ckb' : language;
  if (translations is Map) {
    final text =
        translations[lang] ?? (lang == 'ckb' ? translations['ku'] : null);
    if (text is Map &&
        text[field] is String &&
        (text[field] as String).trim().isNotEmpty) {
      return text[field] as String;
    }
  }
  return note[field]?.toString() ?? '';
}
