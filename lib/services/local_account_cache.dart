import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps legacy local-only history/preferences separate when accounts switch.
/// Credentials are never stored here. Existing values are archived, not erased.
Future<void> activateLocalAccount(SharedPreferences prefs, String owner) async {
  final previous = prefs.getString('local_data_owner');
  if (previous == null) {
    await prefs.setString('local_data_owner', owner);
    return;
  }
  if (previous == owner) return;
  bool scoped(String key) =>
      const {
        'nutrition_history',
        'weight_history',
        'favorites',
        'shopping_list',
        'vitamins',
        'saved_recipe',
        'saved_custom_recipes',
        'micro_goals',
        'notif_inbox',
        'notif_last_seen_id',
        'is_premium',
        'premium_until_ms',
        'meal_plan_cuisine',
        'weekly_digest_enabled',
        'last_active_nutrition_date',
      }.contains(key) ||
      key.startsWith('reminder_');
  final values = <String, dynamic>{
    for (final key in prefs.getKeys().where(scoped)) key: prefs.get(key),
  };
  await prefs.setString('local_account_$previous', jsonEncode(values));
  final raw = prefs.getString('local_account_$owner');
  final restored = raw == null
      ? <String, dynamic>{}
      : jsonDecode(raw) as Map<String, dynamic>;
  for (final key in prefs.getKeys().where(scoped).toList()) {
    await prefs.remove(key);
  }
  for (final e in restored.entries) {
    final v = e.value;
    if (v is bool) {
      await prefs.setBool(e.key, v);
    } else if (v is int) {
      await prefs.setInt(e.key, v);
    } else if (v is double) {
      await prefs.setDouble(e.key, v);
    } else if (v is String) {
      await prefs.setString(e.key, v);
    } else if (v is List) {
      await prefs.setStringList(e.key, List<String>.from(v));
    }
  }
  await prefs.setString('local_data_owner', owner);
}
