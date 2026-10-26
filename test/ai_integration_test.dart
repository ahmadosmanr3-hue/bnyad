import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/ai_service.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:nutrify/utils/ai_nutrition.dart';
import 'package:nutrify/models/meal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'api_token': 'fixture-token',
      'api_user_id': '7',
    });
  });
  test(
    'server switch blocks generation and can enable it later in the same client',
    () async {
      var available = false;
      var posts = 0;
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            return http.Response('{"data":{"fixture":true}}', 200);
          }
          return http.Response(
            jsonEncode({
              'available': available,
              'enabled': true,
              'version': ApiService.aiConsentVersion,
            }),
            200,
          );
        }),
      );
      addTearDown(api.dispose);
      await api.loadToken();
      expect(
        await api.generateAi('recipe', {
          'ingredients': ['rice'],
        }),
        isNull,
      );
      expect(api.aiServiceAvailable, false);
      expect(api.aiErrorCode, 'disabled');
      expect(posts, 0);
      available = true;
      expect(
        await api.generateAi('recipe', {
          'ingredients': ['rice'],
        }),
        {'fixture': true},
      );
      expect(api.aiServiceAvailable, true);
      expect(posts, 1);
    },
  );
  test(
    'food scan uses authenticated backend, never sends a provider key or client health profile',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode(
              r.url.path.endsWith('consent')
                  ? {'enabled': true, 'version': ApiService.aiConsentVersion}
                  : {
                      'data': {
                        'names': {'en': 'Rice', 'ar': 'أرز', 'ku': 'برنج'},
                        'calories': 130,
                      },
                    },
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await api.loadToken();
      final result = await AiService(api: api).analyzeFood(
        imageBytes: Uint8List.fromList([255, 216, 255, 0]),
        dailyCalories: 2200,
        dailyProtein: 100,
        dailyCarbs: 200,
        dailyFat: 70,
        lang: 'ku',
      );
      expect(result?['calories'], 130);
      final r = requests.last;
      expect(r.url.host, 'example.test');
      expect(r.url.path, '/api/ai/generate');
      expect(r.headers['Authorization'], 'Bearer fixture-token');
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['operation'], 'food');
      expect((body['input'] as Map).keys.toSet(), {'image'});
      expect(r.body.contains('API_KEY'), false);
      expect(r.body.contains('dailyCalories'), false);
    },
  );
  test('development AI is disabled without any network request', () async {
    var requests = 0;
    final api = ApiService(
      baseUrl: 'https://bnyad-development.invalid/api',
      aiEnabled: false,
      client: MockClient((r) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    await api.loadToken();
    expect(await api.generateAi('food', {'image': 'fixture'}), isNull);
    expect(api.aiErrorCode, 'unavailable');
    expect(requests, 0);
  });
  test('declined or revoked consent prevents an AI POST', () async {
    var posts = 0;
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        return http.Response(
          jsonEncode({
            'enabled': false,
            'version': ApiService.aiConsentVersion,
          }),
          200,
        );
      }),
    );
    await api.loadToken();
    expect(
      await api.generateAi('recipe', {
        'ingredients': ['rice'],
      }),
      null,
    );
    expect(posts, 0);
    expect(api.aiErrorCode, 'consentRequired');
  });
  test('consent failure cannot silently enable sharing', () async {
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient((r) async => http.Response('{}', 503)),
    );
    await api.loadToken();
    expect(await api.getAiConsent(), null);
    expect(await api.setAiConsent(true), false);
  });
  test('consent grant and revocation use current version on backend', () async {
    final sent = <Map<String, dynamic>>[];
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient((r) async {
        sent.add(jsonDecode(r.body));
        return http.Response('{}', 200);
      }),
    );
    await api.loadToken();
    expect(await api.setAiConsent(true), true);
    expect(await api.setAiConsent(false), true);
    expect(sent.map((m) => m['enabled']).toList(), [true, false]);
    expect(
      sent.every((m) => m['version'] == ApiService.aiConsentVersion),
      true,
    );
  });
  test(
    'quota, premium, invalid output and provider failures have localizable codes',
    () async {
      for (final entry in {
        429: 'quota',
        403: 'notAuthorized',
        422: 'invalidResult',
        503: 'unavailable',
      }.entries) {
        final api = ApiService(
          baseUrl: 'https://example.test/api',
          client: MockClient(
            (r) async => r.method == 'GET'
                ? http.Response(
                    jsonEncode({
                      'enabled': true,
                      'version': ApiService.aiConsentVersion,
                    }),
                    200,
                  )
                : http.Response(
                    '{"message":"private provider detail"}',
                    entry.key,
                  ),
          ),
        );
        await api.loadToken();
        expect(
          await api.generateAi('recipe', {
            'ingredients': ['rice'],
          }),
          null,
        );
        expect(api.aiErrorCode, entry.value);
        expect(
          AiStrings.get('ku', entry.value).contains('private provider detail'),
          false,
        );
      }
    },
  );
  test('AI result arriving after logout is discarded', () async {
    final delayed = Completer<http.Response>();
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient(
        (r) async => r.method == 'GET'
            ? http.Response(
                jsonEncode({
                  'enabled': true,
                  'version': ApiService.aiConsentVersion,
                }),
                200,
              )
            : delayed.future,
      ),
    );
    await api.loadToken();
    final pending = api.generateAi('recipe', {
      'ingredients': ['rice'],
    });
    await Future<void>.delayed(Duration.zero);
    await api.clearAuth();
    delayed.complete(http.Response('{"data":{"calories":130}}', 200));
    expect(await pending, null);
  });
  test('missing deployed AI route is distinct from declined consent', () async {
    var posts = 0;
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        return http.Response('{}', 404);
      }),
    );
    await api.loadToken();
    expect(
      await api.generateAi('recipe', {
        'ingredients': ['rice'],
      }),
      isNull,
    );
    expect(api.aiErrorCode, 'serviceUpdate');
    expect(posts, 0);
  });
  test('server operational failures remain distinct and localized', () async {
    for (final entry in {
      'ai_disabled': 'disabled',
      'ai_not_configured': 'configuration',
      'ai_provider_access': 'configuration',
      'ai_model_unavailable': 'configuration',
      'ai_provider_quota': 'providerQuota',
    }.entries) {
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient(
          (r) async => r.method == 'GET'
              ? http.Response(
                  jsonEncode({
                    'enabled': true,
                    'version': ApiService.aiConsentVersion,
                  }),
                  200,
                )
              : http.Response(
                  jsonEncode({'code': entry.key}),
                  entry.key == 'ai_provider_quota' ? 429 : 503,
                ),
        ),
      );
      await api.loadToken();
      expect(
        await api.generateAi('recipe', {
          'ingredients': ['rice'],
        }),
        isNull,
      );
      expect(api.aiErrorCode, entry.value);
      for (final language in ['en', 'ar', 'ku']) {
        expect(
          AiStrings.get(language, entry.value),
          isNot(AiStrings.get(language, 'failed')),
        );
      }
    }
  });
  test(
    'all AI consent/error keys have English, Arabic and Sorani coverage',
    () {
      for (final language in ['ar', 'ku']) {
        expect(
          AiStrings.translations[language]!.keys.toSet(),
          AiStrings.translations['en']!.keys.toSet(),
        );
        expect(
          AiStrings.translations[language]!.values.every((s) => s.isNotEmpty),
          true,
        );
      }
      expect(AiStrings.get('ckb', 'confirm'), AiStrings.get('ku', 'confirm'));
    },
  );
  test('scan micros scale independently with edited component grams', () {
    final scan = {
      'micros': {'iron': 5},
      'components': [
        {
          'grams': 200,
          'names': {'en': 'Rice'},
          'micros': {'iron': 2},
        },
        {
          'grams': 100,
          'names': {'en': 'Chicken'},
          'micros': {'iron': 3},
        },
      ],
    };
    expect(scaledAiScanMicros(scan, 300, [200, 100])['iron'], 5);
    expect(scaledAiScanMicros(scan, 200, [100, 100])['iron'], 4);
    expect(
      scaledAiScanMicros(
        {
          'micros': {'iron': 2},
        },
        250,
        null,
      )['iron'],
      5,
    );
    expect(scaledAiScanMicros({}, 250, null), isEmpty);
  });
  test('new recipe logging uses summed catalog ingredient grams', () {
    final m = Meal.fromMap({
      'names': {'en': 'Rice'},
      'ingredients': {
        'en': ['200 g White Rice', '100 g Grilled Chicken Breast'],
      },
      'instructions': {
        'en': ['Cook'],
      },
      'calories': 425,
      'protein': 36,
      'carbs': 56,
      'fat': 4,
    });
    expect(m.portionGrams, 300);
  });
}
