import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/l10n/framework_localizations.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/models/premium_gift.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/screens/premium_gifts_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final giftJson = {
  'id': '1',
  'campaignId': 'fictional-campaign',
  'name': 'Newroz · نەورۆز · نوروز',
  'reason':
      'A fictional celebration gift · دیارییەکی تاقیکردنەوە · هدية اختبار',
  'days': 7,
  'remainingDays': 6.5,
  'active': true,
  'deferred': false,
  'startsAt': '2026-10-26T12:00:00.000Z',
  'expiresAt': '2026-11-02T12:00:00.000Z',
};

class GiftViewState extends AppState {
  GiftViewState(ApiService api, this.language, this.dark)
    : super(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
      );
  final String language;
  final bool dark;
  @override
  String get lang => language;
  @override
  AppLocalizations get t => AppLocalizations(language);
  @override
  bool get isRTL => t.isRTL;
  @override
  bool get isDark => dark;
  @override
  List<PremiumGift> get premiumGifts => PremiumGift.parse([
    giftJson,
    {
      ...giftJson,
      'id': '2',
      'active': false,
      'deferred': true,
      'startsAt': null,
      'expiresAt': null,
    },
  ]);
  @override
  Future<void> syncPremiumFromServer() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    for (final family in ['NotoSans', 'NotoSansArabic', 'NotoSansSymbols']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('fonts/$family-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('malformed promotional metadata cannot fabricate a gift balance', () {
    expect(
      PremiumGift.parse([
        {'id': 'bad', 'remainingDays': double.nan},
      ]),
      isEmpty,
    );
    expect(
      PremiumGift.parse([
        {...giftJson, 'remainingDays': -1},
      ]),
      isEmpty,
    );
    expect(
      PremiumGift.parse([
        {...giftJson, 'days': 0},
      ]),
      isEmpty,
    );
    expect(PremiumGift.parse([giftJson]).single.remainingDays, 6.5);
  });
  test(
    'server refresh unlocks gifts, preserves targets and tolerates outage',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final demo = DemoBackend(prefs);
      var granted = false, outage = false;
      final api = ApiService(
        baseUrl: DemoBackend.baseUrl,
        storage: DemoStorage(prefs),
        aiEnabled: false,
        client: MockClient((r) async {
          if (r.url.path.endsWith('/subscription')) {
            return http.Response(
              jsonEncode({
                'isPremium': granted,
                'expiresAt': DateTime.now()
                    .add(const Duration(days: 7))
                    .toIso8601String(),
                'gifts': granted ? [giftJson] : [],
              }),
              outage ? 503 : 200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return demo.handle(r);
        }),
      );
      final state = AppState(
        authService: AuthService(api: api),
        apiService: api,
        initializeOnCreate: false,
        optionalDeviceServicesEnabled: false,
      );
      addTearDown(state.dispose);
      await state.initializeSession();
      await state.loginWithPassword('+9647700000010', 'fictional');
      final calories = state.goals!.calories, protein = state.goals!.protein;
      expect(state.isPremium, false);
      granted = true;
      await state.syncPremiumFromServer();
      expect(state.isPremium, true);
      expect(state.premiumGifts.single.id, '1');
      expect(state.goals!.calories, calories);
      expect(state.goals!.protein, protein);
      outage = true;
      await state.syncPremiumFromServer();
      expect(state.isPremium, true);
      expect(state.premiumGifts, hasLength(1));
      outage = false;
      granted = false;
      await state.syncPremiumFromServer();
      expect(state.isPremium, false);
      expect(state.premiumGifts, isEmpty);
      expect(state.goals!.calories, calories);
    },
  );
  for (final lang in ['en', 'ar', 'ku']) {
    for (final width in [320.0, 390.0, 768.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          '$lang gift details at $width dark=$dark have no overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final api = ApiService(baseUrl: 'https://example.test/api');
            final state = GiftViewState(api, lang, dark);
            addTearDown(state.dispose);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundary,
                child: ChangeNotifierProvider<AppState>.value(
                  value: state,
                  child: MaterialApp(
                    locale: bnyadLocale(lang),
                    supportedLocales: bnyadLocales,
                    localizationsDelegates: bnyadDelegates,
                    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                    debugShowCheckedModeBanner: false,
                    home: const PremiumGiftsScreen(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(state.t.premiumGifts), findsOneWidget);
            expect(
              Directionality.of(tester.element(find.byType(ListView))),
              lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
            );
            expect(find.textContaining('Newroz'), findsWidgets);
            expect(tester.takeException(), isNull);
            if (const bool.fromEnvironment('BNYAD_GIFT_SCREENSHOTS') &&
                width == 320 &&
                !dark) {
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory('build/premium-gift-evidence')
                  ..createSync(recursive: true);
                await File(
                  '${folder.path}/gift-widget-fixture-$lang-320.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.drag(find.byType(ListView), const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
