import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('demo reads and reset never touch the normal app namespace', () async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'api_token': 'normal-app-sentinel',
      'weight_history': '{"2000-01-01":88}',
    });
    SharedPreferences.setPrefix('bnyad_demo.');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    final storage = DemoStorage(prefs);
    expect(await storage.read(key: 'api_token'), isNull);
    await storage.write(key: 'api_token', value: DemoBackend.token);
    final backend = DemoBackend(prefs);
    await backend.seedLocalHistory();
    final history = jsonDecode(prefs.getString('weight_history')!) as Map;
    expect(history.length, 14);
    await prefs.setString('weight_history', '{"2000-01-01":75}');
    await backend.seedLocalHistory();
    expect(prefs.getString('weight_history'), '{"2000-01-01":75}');
    for (final key in prefs.getKeys()) {
      await prefs.remove(key);
    }
    expect(prefs.getKeys(), isEmpty);
    SharedPreferences.resetStatic();
    final normal = await SharedPreferences.getInstance();
    expect(normal.getString('api_token'), 'normal-app-sentinel');
    expect(normal.getString('weight_history'), '{"2000-01-01":88}');
    SharedPreferences.resetStatic();
  });
}
