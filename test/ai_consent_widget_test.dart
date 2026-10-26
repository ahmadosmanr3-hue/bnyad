import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'package:provider/provider.dart';

class ConsentState extends AppState {
  ConsentState(ApiService api)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
      );
  bool allowed = false;
  final changes = <bool>[];
  @override
  bool get isAuthenticated => true;
  @override
  bool get hasPremiumFeatures => true;
  @override
  Future<bool?> getAiConsent() async => allowed;
  @override
  Future<bool> setAiConsent(bool enabled) async {
    changes.add(enabled);
    allowed = enabled;
    return true;
  }
}

class UnavailableConsentState extends ConsentState {
  UnavailableConsentState(super.api, this.language);
  final String language;
  @override
  String get lang => language;
  @override
  bool get hasPremiumFeatures => false;
  @override
  bool get supportsOptionalDeviceServices => false;
  @override
  bool? get aiServiceAvailable => false;
  @override
  String get aiErrorCode => 'disabled';
  @override
  Future<bool?> getAiConsent() async => null;
}

void main() {
  for (final lang in ['en', 'ar', 'ku']) {
    testWidgets('$lang disabled AI does not upsell or request consent', (
      tester,
    ) async {
      final api = ApiService(baseUrl: 'https://example.test/api');
      final state = UnavailableConsentState(api, lang);
      addTearDown(state.dispose);
      addTearDown(api.dispose);
      bool? accepted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  accepted = await ensureAiConsent(context, state);
                },
                child: const Text('Open AI'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open AI'));
      await tester.pumpAndSettle();
      expect(accepted, false);
      expect(find.text(AiStrings.get(lang, 'disabled')), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(state.changes, isEmpty);
      expect(tester.takeException(), isNull);
    });
    for (final width in [320.0, 390.0]) {
      testWidgets('$lang premium explains AI pause at $width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ApiService(baseUrl: 'https://example.test/api');
        final state = UnavailableConsentState(api, lang);
        addTearDown(state.dispose);
        addTearDown(api.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
              home: Scaffold(
                body: Directionality(
                  textDirection: lang == 'en'
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showPremiumPaywall(context),
                      child: const Text('Premium'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Premium'));
        await tester.pumpAndSettle();
        expect(
          find.text(AiStrings.get(lang, 'premiumAiPaused')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('declining consent does not persist permission', (tester) async {
    final state = ConsentState(ApiService(baseUrl: 'https://example.test/api'));
    bool? accepted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                accepted = await ensureAiConsent(context, state);
              },
              child: const Text('Open AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open AI'));
    await tester.pumpAndSettle();
    expect(find.textContaining(AiStrings.get('en', 'notice')), findsOneWidget);
    await tester.tap(find.text(AiStrings.get('en', 'decline')));
    await tester.pumpAndSettle();
    expect(accepted, false);
    expect(state.changes, isEmpty);
  });
  testWidgets('affirmative consent persists before feature proceeds', (
    tester,
  ) async {
    final state = ConsentState(ApiService(baseUrl: 'https://example.test/api'));
    bool? accepted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                accepted = await ensureAiConsent(context, state);
              },
              child: const Text('Open AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiStrings.get('en', 'allow')));
    await tester.pumpAndSettle();
    expect(accepted, true);
    expect(state.changes, [true]);
  });
  testWidgets('settings revoke optional sharing', (tester) async {
    final state = ConsentState(ApiService(baseUrl: 'https://example.test/api'))
      ..allowed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AiPrivacySettings(state: state)),
      ),
    );
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(state.changes, [false]);
  });
  testWidgets(
    'uncertain food requires explicit confirmation and displays portions',
    (tester) async {
      final state = ConsentState(
        ApiService(baseUrl: 'https://example.test/api'),
      );
      bool? accepted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  accepted = await confirmAiEstimate(
                    context,
                    state,
                    details: '200 g Rice',
                  );
                },
                child: const Text('Save estimate'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save estimate'));
      await tester.pumpAndSettle();
      expect(find.textContaining('200 g Rice'), findsOneWidget);
      expect(accepted, null);
      await tester.tap(find.text(AiStrings.get('en', 'review')));
      await tester.pumpAndSettle();
      expect(accepted, true);
    },
  );
}
