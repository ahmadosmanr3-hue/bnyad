import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/services/local_account_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'account switch hides prior local data and restores it when owner returns',
    () async {
      SharedPreferences.setMockInitialValues({
        'nutrition_history': 'old-history',
        'is_premium': true,
        'lang': 'ku',
      });
      final prefs = await SharedPreferences.getInstance();
      await activateLocalAccount(prefs, '7');
      expect(prefs.getString('nutrition_history'), 'old-history');
      await activateLocalAccount(prefs, '8');
      expect(prefs.getString('nutrition_history'), null);
      expect(prefs.getBool('is_premium'), null);
      expect(prefs.getString('lang'), 'ku');
      await prefs.setString('nutrition_history', 'other-history');
      await activateLocalAccount(prefs, '7');
      expect(prefs.getString('nutrition_history'), 'old-history');
      expect(prefs.getBool('is_premium'), true);
      await activateLocalAccount(prefs, '8');
      expect(prefs.getString('nutrition_history'), 'other-history');
    },
  );
}
