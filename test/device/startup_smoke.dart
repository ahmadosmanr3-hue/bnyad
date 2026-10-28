// Physical-device regression harness, never a store entry point. All account,
// storage and HTTP fixtures stay in this process; native RevenueCat remains real.
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/main.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/services/purchases_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final allowed =
      !kReleaseMode &&
      (await PackageInfo.fromPlatform()).packageName ==
          'com.nutrify.bnyad.dev' &&
      await const MethodChannel(
            'com.bnyad.app/steps',
          ).invokeMethod<bool>('offlinePreviewAllowed') ==
          true;
  if (!allowed) {
    throw StateError(
      'Startup smoke checks require the offline development bundle.',
    );
  }
  // Mount a first frame before probing plugins on the scene-based iOS runner.
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('OFFLINE STARTUP QA · AI OFF'))),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  Future<void> stage(String name) async {
    // The existing development-only native bridge logs method names, never
    // fixture/profile values. Unknown diagnostic methods have no side effects.
    try {
      await const MethodChannel('com.bnyad.app/steps').invokeMethod<void>(name);
    } catch (_) {}
  }

  try {
    if (await Purchases.isConfigured.timeout(const Duration(seconds: 8))) {
      throw StateError('Smoke check requires an unconfigured native SDK.');
    }
    await stage('startup_smoke_native_store_unconfigured');
  } catch (error) {
    await stage('startup_smoke_probe_error_${error.runtimeType}');
    rethrow;
  }
  const profile = {
    'onboarded': true,
    'display_name': 'Fictional startup QA',
    'age': 30,
    'weight': 70,
    'height': 170,
    'language': 'ku',
    'daily_calories': 2000,
    'daily_protein': 100,
    'daily_carbs': 250,
    'daily_fat': 67,
  };
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({
    'api_token': 'fictional-startup-token',
    'api_user_id': '7',
    'api_user_snapshot': jsonEncode({'id': 7, 'profile': profile}),
  });
  final api = ApiService(
    baseUrl: 'https://startup.invalid/api',
    aiEnabled: false,
    client: MockClient((request) async {
      if (request.url.path.endsWith('/auth/me')) {
        return http.Response(
          jsonEncode({
            'data': {'id': 7, 'profile': profile},
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/profile')) {
        return http.Response(jsonEncode({'data': profile}), 200);
      }
      if (request.url.path.endsWith('/subscription')) {
        return http.Response('{"isPremium":false}', 200);
      }
      return http.Response('{}', 200);
    }),
  );
  final state = AppState(
    authService: AuthService(api: api),
    apiService: api,
    initializeOnCreate: false,
  );
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          message: 'OFFLINE STARTUP QA · AI OFF',
          location: BannerLocation.topEnd,
          child: BnyadApp(),
        ),
      ),
    ),
  );
  await state.initializeSession();
  await Future<void>.delayed(const Duration(seconds: 8));
  await state.onAppResumed();
  final unavailable = !await PurchasesBootstrap.instance.ensureConfigured();
  if (!state.isAuthenticated ||
      !state.onboardingComplete ||
      state.goals?.calories != 2000 ||
      !unavailable) {
    throw StateError('Startup smoke check failed.');
  }
  await stage('startup_smoke_pass');
  print(
    'BNYAD_STARTUP_SMOKE_PASS: restored fictional dashboard and resume survived with native store unconfigured; AI off, no production requests.',
  );
}
