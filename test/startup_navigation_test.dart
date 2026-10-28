import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/main.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/screens/onboarding_screen.dart';
import 'package:nutrify/screens/dashboard_screen.dart';
import 'package:nutrify/l10n/app_localizations.dart';

class StartupState extends AppState {
  StartupState(ApiService api)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
      );
  bool loading = true;
  bool signedIn = false;
  bool retryNeeded = false;
  @override
  bool get authLoading => loading;
  @override
  bool get isLoggedIn => signedIn;
  @override
  bool get sessionNeedsRetry => retryNeeded;
}

Future<void> finishSplash(WidgetTester tester) async {
  for (var i = 0; i < 45; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'restored onboarded account opens and resumes without a configured store',
    (tester) async {
      final unsafeCalls = <String>[];
      const channel = MethodChannel('purchases_flutter');
      const connectivity = MethodChannel(
        'dev.fluttercommunity.plus/connectivity',
      );
      const connectivityEvents = MethodChannel(
        'dev.fluttercommunity.plus/connectivity_status',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(connectivity, (_) async => ['wifi']);
      messenger.setMockMethodCallHandler(connectivityEvents, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(connectivity, null);
        messenger.setMockMethodCallHandler(connectivityEvents, null);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isConfigured') return false;
            unsafeCalls.add(call.method);
            throw StateError('Native SDK access before configuration');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      FlutterSecureStorage.setMockInitialValues({
        'api_token': 'fictional-startup-token',
        'api_user_id': '7',
        'api_user_snapshot': jsonEncode({
          'id': 7,
          'profile': {
            'onboarded': true,
            'display_name': 'Fictional QA',
            'age': 30,
            'weight': 70,
            'height': 170,
            'language': 'ku',
            'daily_calories': 2000,
            'daily_protein': 100,
            'daily_carbs': 250,
            'daily_fat': 67,
          },
        }),
      });
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      final state = AppState(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
      );
      await tester.runAsync(state.initializeSession);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const BnyadApp(),
        ),
      );
      await finishSplash(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(state.onboardingComplete, true);
      await tester.runAsync(state.onAppResumed);
      await tester.pump();
      expect(unsafeCalls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(state.logout);
      expect(unsafeCalls, isEmpty);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      api.dispose();
    },
  );

  testWidgets(
    'startup shows initialization instead of flickering login/onboarding',
    (tester) async {
      final state = StartupState(
        ApiService(baseUrl: 'https://example.test/api'),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const BnyadApp(),
        ),
      );
      await finishSplash(tester);
      expect(find.text(state.t.appLoading), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets(
    'temporarily unavailable saved session offers retry instead of login',
    (tester) async {
      final state = StartupState(
        ApiService(baseUrl: 'https://example.test/api'),
      );
      state.loading = false;
      state.retryNeeded = true;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const BnyadApp(),
        ),
      );
      await finishSplash(tester);
      expect(find.text(state.t.retry), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets('fresh install goes to login after initialization', (
    tester,
  ) async {
    final state = StartupState(ApiService(baseUrl: 'https://example.test/api'));
    state.loading = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const BnyadApp(),
      ),
    );
    await finishSplash(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'canonical ckb uses the Sorani catalog and RTL layout without overflow',
    (tester) async {
      final state = StartupState(
        ApiService(baseUrl: 'https://example.test/api'),
      );
      await state.setLang('ckb');
      expect(state.isRTL, true);
      final t = AppLocalizations('ckb');
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: Column(
                  children: [
                    Text(t.sessionUnavailable),
                    Text(t.monthlyBilling),
                    Text(t.yearlyBilling),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), null);
      expect(
        Directionality.of(tester.element(find.text(t.monthlyBilling))),
        TextDirection.rtl,
      );
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
}
