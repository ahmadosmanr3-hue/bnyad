import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreTestState extends AppState {
  StoreTestState(this.api)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
      );
  final ApiService api;
  @override
  bool get isAuthenticated => api.hasToken;
}

Map<String, dynamic> customer({bool expired = false}) {
  final date = DateTime.now().toUtc();
  final expiry = date.add(Duration(days: expired ? -1 : 30)).toIso8601String();
  final entitlement = {
    'identifier': 'all_feature',
    'isActive': true,
    'willRenew': true,
    'latestPurchaseDate': date.toIso8601String(),
    'originalPurchaseDate': date.toIso8601String(),
    'productIdentifier': 'fictional.monthly',
    'isSandbox': true,
    'expirationDate': expiry,
  };
  return {
    'entitlements': {
      'all': {'all_feature': entitlement},
      'active': {'all_feature': entitlement},
    },
    'allPurchaseDates': <String, String>{},
    'activeSubscriptions': ['fictional.monthly'],
    'allPurchasedProductIdentifiers': ['fictional.monthly'],
    'nonSubscriptionTransactions': <dynamic>[],
    'firstSeen': date.toIso8601String(),
    'originalAppUserId': '7',
    'allExpirationDates': {'fictional.monthly': expiry},
    'requestDate': date.toIso8601String(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  var expired = false;
  Future<void> Function()? beforeRestore;
  setUp(() {
    expired = false;
    beforeRestore = null;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'api_token': 'fictional-token',
      'api_user_id': '7',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'isConfigured') return true;
          if (call.method == 'logIn') {
            return {'customerInfo': customer(), 'created': false};
          }
          if (call.method == 'restorePurchases') await beforeRestore?.call();
          return customer(expired: expired);
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<(StoreTestState, ApiService)> fixture(
    Future<http.Response> Function(http.Request) respond,
  ) async {
    final api = ApiService(
      baseUrl: 'https://example.test/api',
      client: MockClient(respond),
    );
    await api.loadToken();
    final state = StoreTestState(api);
    addTearDown(state.dispose);
    addTearDown(api.dispose);
    return (state, api);
  }

  test(
    'restore waits for backend verification and its trusted access snapshot',
    () async {
      final pending = Completer<http.Response>();
      final posted = Completer<void>();
      final methods = <String>[];
      final (state, _) = await fixture((request) async {
        methods.add(request.method);
        expect(request.headers['Authorization'], 'Bearer fictional-token');
        if (request.method == 'POST') {
          expect(request.body, '{}'); // No mobile expiry/price claims.
          posted.complete();
          return pending.future;
        }
        return http.Response(
          jsonEncode({
            'isPremium': true,
            'expiresAt': DateTime.now()
                .add(const Duration(days: 10))
                .toIso8601String(),
          }),
          200,
        );
      });
      final result = state.restorePurchases();
      await posted.future;
      expect(state.isPremium, false);
      pending.complete(http.Response('{"ok":true}', 201));
      expect(await result, true);
      expect(methods, ['POST', 'GET']);
      expect(state.isPremium, true);
      expect(state.purchaseVerificationPending, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), true);
      expect(state.premiumUntil!.difference(DateTime.now()).inDays, 9);
    },
  );

  for (final status in [403, 503]) {
    test('HTTP $status cannot grant Premium from SDK success alone', () async {
      final (state, _) = await fixture(
        (_) async => http.Response('{}', status),
      );
      expect(await state.restorePurchases(), false);
      expect(state.isPremium, false);
      expect(state.purchaseVerificationPending, true);
    });
  }

  test('a successful POST without server Premium remains pending', () async {
    final (state, _) = await fixture(
      (request) async => http.Response(
        request.method == 'POST' ? '{"ok":true}' : '{"isPremium":false}',
        request.method == 'POST' ? 201 : 200,
      ),
    );
    expect(await state.restorePurchases(), false);
    expect(state.isPremium, false);
    expect(state.purchaseVerificationPending, true);
  });

  test(
    'a temporary store-verification outage preserves an existing admin grant',
    () async {
      final (state, _) = await fixture((_) async => http.Response('{}', 503));
      final until = DateTime.now().add(const Duration(days: 10));
      await state.setPremium(true, until: until);
      expect(await state.restorePurchases(), true);
      expect(state.isPremium, true);
      expect(state.premiumUntil, until.toUtc());
    },
  );

  test('expired SDK entitlements do not trigger a verification POST', () async {
    expired = true;
    var requests = 0;
    final (state, _) = await fixture((_) async {
      requests++;
      return http.Response('{}', 503);
    });
    expect(await state.restorePurchases(), false);
    expect(requests, 0);
  });

  for (final stage in ['native', 'POST', 'GET']) {
    test('logout during $stage cannot apply a stale entitlement', () async {
      late ApiService api;
      final (state, client) = await fixture((request) async {
        if (request.method == stage) await api.clearAuth();
        return http.Response(
          request.method == 'POST' ? '{"ok":true}' : '{"isPremium":true}',
          request.method == 'POST' ? 201 : 200,
        );
      });
      api = client;
      if (stage == 'native') beforeRestore = api.clearAuth;
      expect(await state.restorePurchases(), false);
      expect(state.isPremium, false);
    });
  }

  for (final lang in ['en', 'ar', 'ku']) {
    test(
      '$lang explains verification delay without inviting another purchase',
      () {
        final text = AppLocalizations(lang).purchaseVerificationPending;
        expect(text, isNotEmpty);
        if (lang == 'en') {
          expect(text, contains('Do not purchase again'));
          expect(text, contains('Restore Purchases'));
        } else {
          expect(RegExp(r'[\u0600-\u06ff]').hasMatch(text), true);
        }
      },
    );
  }
}
