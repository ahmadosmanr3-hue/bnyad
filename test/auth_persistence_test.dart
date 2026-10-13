import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/models/log_entry.dart';

const user = <String, dynamic>{
  'id': 7,
  'name': 'Test user',
  'profile': {
    'onboarded': true,
    'display_name': 'Test user',
    'daily_calories': 1800,
    'daily_protein': 115,
    'activity_level': 'lightlyActive',
    'language': 'ckb',
    'weight': 65,
    'height': 165,
    'age': 30,
  },
};

ApiService apiWith(http.Response Function(http.Request) respond) => ApiService(
  baseUrl: 'https://example.test/api',
  client: MockClient((r) async => respond(r)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'a stale user response cannot replace a newly signed-in account or pending profile',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'old-token',
        'api_user_id': '7',
        'api_user_snapshot': jsonEncode(user),
        'api_pending_profile': jsonEncode(user['profile']),
      });
      final delayed = Completer<http.Response>();
      final nextUser = {
        ...user,
        'id': 8,
        'name': 'Other account',
        'profile': {'onboarded': false},
      };
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/auth/me')) return delayed.future;
          return http.Response(
            jsonEncode({'token': 'new-token', 'user': nextUser}),
            200,
          );
        }),
      );
      await api.loadToken();
      final stale = api.me();
      await api.loginWithPassword(
        phone: '+9647000000001',
        password: 'test-password',
      );
      delayed.complete(http.Response(jsonEncode({'data': user}), 200));
      expect(await stale, null);
      expect(api.userId, 8);
      expect((await api.cachedUser())?['id'], 8);
      expect(
        await const FlutterSecureStorage().read(key: 'api_pending_profile'),
        null,
      );
      api.dispose();
    },
  );

  test(
    'a stale food response is never cached or displayed for a new account',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'old-token',
        'api_user_id': '7',
      });
      final delayed = Completer<http.Response>();
      var logRequests = 0;
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/auth/login')) {
            return http.Response(
              jsonEncode({
                'token': 'new-token',
                'user': {...user, 'id': 8},
              }),
              200,
            );
          }
          if (++logRequests == 1) return delayed.future;
          return http.Response('{}', 503);
        }),
      );
      await api.loadToken();
      final stale = api.getDailyLogs(date: '2026-10-13');
      await api.loginWithPassword(
        phone: '+9647000000001',
        password: 'test-password',
      );
      delayed.complete(
        http.Response(
          jsonEncode({
            'data': [
              {'id': 1, 'name': 'Private old food'},
            ],
          }),
          200,
        ),
      );
      expect(await stale, isEmpty);
      expect(await api.getDailyLogs(date: '2026-10-13'), isEmpty);
      api.dispose();
    },
  );

  test('fresh install starts without a session', () async {
    final api = apiWith((_) => http.Response('{}', 401));
    await api.loadToken();
    expect(api.hasToken, false);
    expect(await api.cachedUser(), null);
    api.dispose();
  });

  test(
    'successful sign-in survives a new client instance and offline reopen',
    () async {
      final first = apiWith(
        (_) => http.Response(
          jsonEncode({'token': 'saved-token', 'user': user}),
          200,
        ),
      );
      expect(
        await first.loginWithPassword(
          phone: '+9647000000000',
          password: 'test-password',
        ),
        user,
      );
      first.dispose();
      final reopened = apiWith((_) => throw const SocketException('offline'));
      await reopened.loadToken();
      expect(reopened.hasToken, true);
      expect(reopened.userId, 7);
      expect((await reopened.cachedUser())?['profile']['onboarded'], true);
      expect(await reopened.me(), null);
      expect(reopened.hasToken, true);
      reopened.dispose();
    },
  );

  test(
    'server errors and malformed responses preserve credentials and snapshot',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'saved-token',
        'api_user_id': '7',
        'api_user_snapshot': jsonEncode(user),
      });
      for (final response in [
        http.Response('{}', 503),
        http.Response('<html>bad gateway</html>', 200),
      ]) {
        final api = apiWith((_) => response);
        await api.loadToken();
        expect(await api.me(), null);
        expect(api.hasToken, true);
        expect(await api.cachedUser(), user);
        api.dispose();
      }
    },
  );

  test('revoked session clears secure state and notifies its owner', () async {
    FlutterSecureStorage.setMockInitialValues({
      'api_token': 'saved-token',
      'api_user_id': '7',
      'api_user_snapshot': jsonEncode(user),
    });
    final api = apiWith((_) => http.Response('{}', 401));
    var invalidated = 0;
    api.onSessionInvalidated = () => invalidated++;
    await api.loadToken();
    await api.me();
    expect(api.hasToken, false);
    expect(await api.cachedUser(), null);
    expect(invalidated, 1);
    api.dispose();
  });

  test(
    'explicit logout survives reopening even if server is offline',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'saved-token',
        'api_user_id': '7',
      });
      final first = apiWith((_) => throw const SocketException('offline'));
      await first.loadToken();
      await first.logout();
      first.dispose();
      final reopened = apiWith((_) => http.Response('{}', 401));
      await reopened.loadToken();
      expect(reopened.hasToken, false);
      reopened.dispose();
    },
  );

  test('legacy preference credentials migrate into secure storage', () async {
    SharedPreferences.setMockInitialValues({
      'api_token': 'legacy',
      'api_user_id': 7,
    });
    final api = apiWith((_) => http.Response('{}', 503));
    await api.loadToken();
    expect(api.hasToken, true);
    expect(api.userId, 7);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('api_token'), false);
    expect(await const FlutterSecureStorage().read(key: 'api_token'), 'legacy');
    api.dispose();
  });

  test(
    'failed account deletion preserves authentication and cached profile',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'saved-token',
        'api_user_id': '7',
        'api_user_snapshot': jsonEncode(user),
      });
      final api = apiWith((_) => http.Response('{}', 503));
      await api.loadToken();
      expect(await api.deleteAccount(), false);
      expect(api.hasToken, true);
      expect(await api.cachedUser(), user);
      api.dispose();
    },
  );

  test('successful account deletion removes the session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'api_token': 'saved-token',
      'api_user_id': '7',
    });
    final api = apiWith((_) => http.Response('{}', 200));
    await api.loadToken();
    expect(await api.deleteAccount(), true);
    expect(api.hasToken, false);
    api.dispose();
  });

  test(
    'profile adapter preserves snake case macros, preferences and onboarding',
    () async {
      final api = apiWith((_) => http.Response('{}', 503));
      final profile = api.profileFromJson(
        user['profile'] as Map<String, dynamic>,
      );
      expect(profile.dailyCalories, 1800);
      expect(profile.dailyProtein, 115);
      expect(profile.activityLevel, 'lightlyActive');
      expect(profile.language, 'ku');
      expect(profile.onboarded, true);
      expect(profile.displayName, 'Test user');
      api.dispose();
    },
  );

  test(
    'offline onboarding stays pending and survives server profile refresh',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'saved-token',
        'api_user_id': '7',
        'api_user_snapshot': jsonEncode(user),
      });
      final api = apiWith(
        (r) => r.method == 'GET'
            ? http.Response(
                jsonEncode({
                  'data': {
                    ...user,
                    'profile': {'onboarded': false},
                  },
                }),
                200,
              )
            : http.Response('{}', 422),
      );
      await api.loadToken();
      await api.saveUserProfile(
        api.profileFromJson(user['profile'] as Map<String, dynamic>),
      );
      final refreshed = await api.me();
      expect(refreshed?['profile']['onboarded'], true);
      expect(
        await const FlutterSecureStorage().read(key: 'api_pending_profile'),
        isNotNull,
      );
      api.dispose();
    },
  );

  test(
    'current-day food log remains available offline and never leaks across users/dates',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'saved-token',
        'api_user_id': '7',
      });
      final first = apiWith(
        (_) => http.Response(
          jsonEncode({
            'data': [
              {'id': 1, 'name': 'Food', 'calories': 120},
            ],
          }),
          200,
        ),
      );
      await first.loadToken();
      expect(
        (await first.getDailyLogs(date: '2026-10-13')).single.calories,
        120,
      );
      first.dispose();
      final offline = apiWith((_) => throw const SocketException('offline'));
      await offline.loadToken();
      expect(
        (await offline.getDailyLogs(date: '2026-10-13')).single.calories,
        120,
      );
      expect(await offline.getDailyLogs(date: '2026-10-14'), isEmpty);
      await offline.clearAuth();
      expect(await offline.getDailyLogs(date: '2026-10-13'), isEmpty);
      offline.dispose();
    },
  );

  test('snapshot from another account is ignored', () async {
    FlutterSecureStorage.setMockInitialValues({
      'api_token': 'saved-token',
      'api_user_id': '8',
      'api_user_snapshot': jsonEncode(user),
    });
    final api = apiWith((_) => http.Response('{}', 503));
    await api.loadToken();
    expect(await api.cachedUser(), null);
    api.dispose();
  });

  test(
    'invalid login response cannot report successful authentication',
    () async {
      final api = apiWith(
        (_) => http.Response(jsonEncode({'user': user}), 200),
      );
      expect(
        await api.loginWithPassword(
          phone: '+9647000000000',
          password: 'test-password',
        ),
        null,
      );
      expect(api.hasToken, false);
      api.dispose();
    },
  );

  test(
    'new food logs use the server id so immediate deletion targets the correct entry',
    () async {
      final api = apiWith((r) {
        if (r.method == 'DELETE') {
          expect(r.url.path, '/api/logs/123');
          return http.Response('{}', 200);
        }
        return http.Response(
          jsonEncode({
            'data': {'id': 123, 'name': 'Food', 'calories': 120},
          }),
          201,
        );
      });
      final saved = await api.addFoodLog(
        LogEntry(
          id: 'local-id',
          foodId: '',
          name: 'Food',
          amount: 100,
          calories: 120,
          protein: 0,
          carbs: 0,
          fat: 0,
          timestamp: 0,
        ),
      );
      expect(saved?.id, '123');
      expect(await api.removeFoodLog(saved!.id), true);
      api.dispose();
    },
  );

  test('failed food and water writes are not reported as saved', () async {
    final api = apiWith((_) => http.Response('{}', 503));
    expect(await api.updateWater(250), false);
    expect(
      await api.addFoodLog(
        LogEntry(
          id: 'local',
          foodId: '',
          name: 'Food',
          amount: 100,
          calories: 120,
          protein: 0,
          carbs: 0,
          fat: 0,
          timestamp: 0,
        ),
      ),
      null,
    );
    api.dispose();
  });
}
