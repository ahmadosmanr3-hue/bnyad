import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:nutrify/widgets/ai_consent.dart';

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

void main() {
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
