import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_fixtures.dart';
import 'package:nutrify/demo/demo_guard.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/demo/demo_url_launcher.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/food_barcode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('only explicit debug web builds on loopback may enter demo', () {
    for (final host in ['localhost', '127.0.0.1', '::1', '[::1]']) {
      expect(
        isAllowedDemoEnvironment(debug: true, web: true, host: host),
        isTrue,
      );
      expect(
        isAllowedDemoEnvironment(debug: false, web: true, host: host),
        isFalse,
      );
      expect(
        isAllowedDemoEnvironment(debug: true, web: false, host: host),
        isFalse,
      );
    }
    for (final host in [
      'bnyad.app',
      'localhost.example.com',
      '192.168.1.3',
      '',
    ]) {
      expect(
        isAllowedDemoEnvironment(debug: true, web: true, host: host),
        isFalse,
      );
    }
    expect(
      requireDemoRuntime,
      throwsStateError,
    ); // VM is not the web entrypoint.
  });

  test('production entrypoints never import demo authentication', () {
    for (final name in ['main.dart', 'main_development.dart']) {
      expect(File('lib/$name').readAsStringSync(), isNot(contains('demo/')));
    }
  });

  Future<(DemoBackend, ApiService)> setup() async {
    final prefs = await SharedPreferences.getInstance();
    final backend = DemoBackend(prefs);
    final api = ApiService(
      baseUrl: DemoBackend.baseUrl,
      client: backend.client,
      storage: DemoStorage(prefs),
    );
    return (backend, api);
  }

  test(
    'mock transport blocks production, external barcode and unknown endpoints',
    () async {
      final (backend, api) = await setup();
      for (final url in [
        'https://nutrify-api-lovat.vercel.app/api/auth/login',
        'https://world.openfoodfacts.org/api/v2/product/123',
        '${DemoBackend.baseUrl}/unknown',
      ]) {
        final response = await backend.client.get(Uri.parse(url));
        expect(response.statusCode, anyOf(401, 404));
      }
      final result = await FoodBarcodeService().lookup(
        '9999999999999',
        isOnline: true,
      );
      expect(result.isSuccess, isFalse);
      api.dispose();
    },
  );

  test(
    'fake login persists only a fictional identity and restores local session',
    () async {
      final (backend, api) = await setup();
      final user = await api.loginWithPassword(
        phone: '+9647700000010',
        password: 'never-store-this',
      );
      expect(user?['id'], 909009);
      expect(user?['name'], 'BNYAD Demo User');
      expect(api.hasToken, isTrue);
      final (restored, restoredApi) = await setup();
      await restoredApi.loadToken();
      expect((await restoredApi.me())?['id'], 909009);
      expect(jsonEncode(backend.data), isNot(contains('never-store-this')));
      final prefs = restored.preferences;
      expect(
        prefs.getKeys().map(prefs.get).join(),
        isNot(contains('never-store-this')),
      );
      await restoredApi.logout();
      expect(restoredApi.hasToken, isFalse);
      api.dispose();
      restoredApi.dispose();
    },
  );

  test(
    'registration has no SMS and accepts only the visible demo OTP',
    () async {
      final (_, api) = await setup();
      expect(await api.checkPhoneRegistered('+9647700000010'), isTrue);
      expect(await api.checkPhoneRegistered('+9647700000011'), isFalse);
      expect(await api.requestOtp('+9647700000011'), isNull);
      expect(
        await api.verifyOtp(phone: '+9647700000011', code: '000000'),
        isNull,
      );
      expect(
        (await api.verifyOtp(
          phone: '+9647700000011',
          code: '123456',
          password: 'demo123',
          name: 'Ignored name',
        ))?['name'],
        'BNYAD Demo User',
      );
      api.dispose();
    },
  );

  test(
    'food, water, profile, weight and meal changes persist locally',
    () async {
      final (backend, api) = await setup();
      await api.loginWithPassword(phone: 'fictional', password: 'demo123');
      expect((await api.getDailyLogs()).length, 2);
      expect(await api.getWaterIntake(), 1000);
      final log = await api.addFoodLog(
        LogEntry(
          id: '',
          foodId: 'local-food',
          name: 'Demo apple',
          amount: 150,
          calories: 80,
          protein: 0,
          carbs: 20,
          fat: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      expect(log?.id, 'demo-1');
      expect(await api.updateWater(1500), isTrue);
      await api.recordWeight(74.5);
      await api.updateProfileField({'language': 'ku'});
      expect(
        await api.saveMealPlan(MealPlanData.fromMap(demoMealPlan())),
        isTrue,
      );
      final (_, reloadedApi) = await setup();
      await reloadedApi.loadToken();
      expect((await reloadedApi.getDailyLogs()).length, 3);
      expect(await reloadedApi.getWaterIntake(), 1500);
      expect((await reloadedApi.getUserProfile())?.language, 'ku');
      expect((await reloadedApi.getMealPlan())?.lunch.name, contains('Demo:'));
      expect(backend.data['weights'], hasLength(1));
      expect(await reloadedApi.removeFoodLog(log!.id), isTrue);
      expect((await reloadedApi.getDailyLogs()).length, 2);
      api.dispose();
      reloadedApi.dispose();
    },
  );

  test(
    'simulated AI requires a local session, premium and local consent',
    () async {
      final (backend, api) = await setup();
      final denied = await backend.client.post(
        Uri.parse('${DemoBackend.baseUrl}/ai/generate'),
        body: jsonEncode({'operation': 'meal-plan'}),
      );
      expect(denied.statusCode, 401);
      await api.loginWithPassword(phone: 'fictional', password: 'demo123');
      await api.setAiConsent(true);
      for (final operation in [
        'meal-plan',
        'meal',
        'details',
        'recipe',
        'fridge',
        'food',
        'shopping',
        'guidance',
      ]) {
        expect(
          await api.generateAi(operation, {}),
          isNotNull,
          reason: operation,
        );
      }
      final response = await api.generateAi('food', {
        'image': {'data': 'discard-image-bytes'},
      });
      expect(response?['requiresConfirmation'], isTrue);
      expect(response?['names']['en'], contains('Demo:'));
      expect(jsonEncode(backend.data), isNot(contains('discard-image-bytes')));
      backend.data['premium'] = false;
      expect(await api.generateAi('food', {}), isNull);
      backend.data['premium'] = true;
      await api.setAiConsent(false);
      expect(await api.generateAi('food', {}), isNull);
      api.dispose();
    },
  );

  test(
    'fixtures parse through existing models with balanced macro estimates and all languages',
    () {
      final plan = MealPlanData.fromMap(demoMealPlan());
      expect(plan.lunch.calories, 484);
      for (final slot in demoMealPlan().values) {
        final meal = Meal.fromMap(Map<String, dynamic>.from(slot));
        expect(meal.calories, meal.protein * 4 + meal.carbs * 4 + meal.fat * 9);
        for (final lang in ['en', 'ar', 'ku']) {
          expect(slot['names'][lang], isNotEmpty);
          expect(slot['instructions'][lang], isNotEmpty);
        }
      }
      expect(demoAiResponse('body-fat', {}), isNull);
    },
  );

  test(
    'external link launcher cannot open production, stores or medical links',
    () async {
      final launcher = DemoUrlLauncher();
      for (final url in [
        'https://nutrify-api-lovat.vercel.app/privacy',
        'https://apps.apple.com',
        'https://pubmed.ncbi.nlm.nih.gov',
      ]) {
        expect(await launcher.canLaunch(url), isFalse);
        expect(await launcher.launchUrl(url, const LaunchOptions()), isFalse);
      }
    },
  );
}
