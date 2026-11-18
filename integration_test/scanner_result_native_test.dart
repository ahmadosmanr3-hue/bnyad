import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/main.dart' show BnyadApp;
import 'package:nutrify/main_iphone_preview.dart'
    show OfflinePreviewHttpOverrides;
import 'package:nutrify/models/scan_meal_draft.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/scanner_screen.dart';
import 'package:nutrify/screens/scan_result_editor.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/scan_result_editor_test.dart' show scanFixture;
import 'fixtures/dolma_image.dart';
import 'native_photo_review_test.dart' as photos;

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await frames(tester, 3);
  await tester.tap(f);
  await frames(tester);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native camera-response-editor-save and corrected catalog cases', (
    tester,
  ) async {
    HttpOverrides.global = OfflinePreviewHttpOverrides();
    SharedPreferences.setPrefix('bnyad_scanner_results_native_qa.');
    final prefs = await SharedPreferences.getInstance();
    final backend = DemoBackend(prefs);
    await backend.reset();
    backend.data['premium'] = true;
    backend.data['consent'] = true;
    await backend.persist();
    var fixture = {
      ...scanFixture(['f8']),
      'names': {'en': 'Pomegranate', 'ar': 'رمان', 'ku': 'هەنار'},
    };
    int generated = 0;
    int savedRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/ai/generate') {
        generated++;
        expect(jsonDecode(request.body)['input']['recognitionVersion'], 2);
        return http.Response(
          jsonEncode({'data': fixture, 'simulated': true}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/logs/scan') savedRequests++;
      return backend.handle(request);
    });
    final api = ApiService(
      baseUrl: DemoBackend.baseUrl,
      storage: DemoStorage(prefs),
      client: client,
    );
    var state = AppState(
      authService: AuthService(api: api),
      apiService: api,
      initializeOnCreate: false,
      optionalDeviceServicesEnabled: false,
    );
    await state.initializeSession();
    if (!state.isAuthenticated) {
      await state.loginWithPassword('+9647700000010', 'demo-only');
    }
    await state.setLang('en');
    await state.catalog.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const BnyadApp()),
    );
    await frames(tester, 40);
    tester.testTextInput.register();
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final navigator = Navigator.of(tester.element(find.byType(Scaffold).first));
    // Actual production ScannerScreen, fixture photo picker and HTTP transport.
    // No real camera permission, real food recognition or Google call is claimed.
    navigator.push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: ScannerScreen(
            picker: photos.LocalFixturePicker(licensedDolmaPhoto),
          ),
        ),
      ),
    );
    await frames(tester);
    await tap(tester, find.widgetWithIcon(OutlinedButton, Icons.upload).first);
    expect(find.text('Analyze meal'), findsOneWidget);
    await tap(tester, find.text('Analyze meal'));
    for (
      var i = 0;
      i < 80 && find.byType(ScanResultEditor).evaluate().isEmpty;
      i++
    ) {
      await frames(tester, 2);
    }
    expect(find.byType(ScanResultEditor), findsOneWidget);
    expect(generated, 1);
    expect(find.textContaining('SIMULATED AI'), findsOneWidget);
    await binding.takeScreenshot(
      '${Platform.operatingSystem}_scanner-full-flow-en',
    );
    final before = state.dailyLog.length;
    await tap(tester, find.byKey(const ValueKey('scan-confirm')));
    await tap(tester, find.byKey(const ValueKey('scan-save')));
    for (var wait = 0; wait < 80 && state.dailyLog.length == before; wait++) {
      await frames(tester, 2);
    }
    debugPrint(
      'Scanner QA save: requests=$savedRequests code=${api.scanSaveError}  logs=${state.dailyLog.length}',
    );
    expect(state.dailyLog.length, before + 1);
    expect(savedRequests, 1);
    navigator.pop();
    await frames(tester);
    final volume = state.catalog.foods.values.firstWhere((f) => f.isLiquid);
    for (final entry in <(String, List<String>, bool)>[
      ('components', ['g2', 'p1', 'v3'], false),
      ('rice-meat', ['g2', 'p3'], false),
      ('biryani', ['k2_chicken'], false),
      ('dolma', ['k1'], false),
      ('drink', [volume.id], false),
      ('ambiguous', [], true),
      ('unknown', ['unknown-food'], false),
      ('bad-nutrition', ['g2'], false),
    ]) {
      final scan = scanFixture(entry.$2, unresolved: entry.$3);
      if (entry.$2.isNotEmpty && state.catalog.foods[entry.$2.first] != null) {
        final f = state.catalog.foods[entry.$2.first]!;
        scan['names'] = {'en': f.name, 'ar': f.nameAr, 'ku': f.nameKu};
      }
      if (entry.$1 == 'drink') {
        scan['components'] = [
          {
            'id': volume.id,
            'unit': 'ml',
            'amount': 330,
            'names': {'en': volume.name},
          },
        ];
      }
      if (entry.$1 == 'bad-nutrition') {
        scan['components'] = [
          {
            'id': 'g2',
            'grams': 150,
            'calories': -999,
            'protein': null,
            'names': {'en': 'Rice'},
          },
        ];
      }
      await state.setLang('ku');
      await state.setTheme('dark');
      final draft = ScanMealDraft.fromScan(scan, state.catalog.foods, {}, 'ku');
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ScanResultEditor(
            draft: draft,
            foods: state.catalog.foods,
            disabled: {},
            lang: 'ku',
            simulated: true,
            onSave: (d) => state.addReviewedScan(
              d.toRequest(state.catalog.revision!, 'ku'),
            ),
          ),
        ),
      );
      await frames(tester);
      if (!draft.valid) {
        if (entry.$3) {
          await tap(tester, find.byKey(const ValueKey('scan-candidate-0')));
        } else {
          // Explicitly discard the unrecognized component, then choose a verified food.
          if (draft.pending.isNotEmpty) {
            await tap(tester, find.text('لابردن').first);
          }
          await tap(tester, find.byKey(const ValueKey('scan-add')));
        }
        await tester.enterText(
          find.byKey(const ValueKey('scan-search')),
          'Kurdish Biryani with Chicken',
        );
        await frames(tester);
        if (!entry.$3) {
          // prepared dishes require the mutually exclusive whole-dish mode
          navigator.pop();
          await frames(tester);
          await tap(tester, find.byKey(const ValueKey('scan-mode-dish')));
          await tap(tester, find.byKey(const ValueKey('scan-add')));
          await tester.enterText(
            find.byKey(const ValueKey('scan-search')),
            'Kurdish Biryani with Chicken',
          );
          await frames(tester);
        }
        await tap(tester, find.byKey(const ValueKey('scan-food-k2_chicken')));
        await tester.enterText(
          find.byKey(const ValueKey('portion-weight')),
          '٢٠٠',
        );
        await frames(tester);
        tester.testTextInput.hide();
        await frames(tester);
        await tap(tester, find.byKey(const ValueKey('scan-apply-portion')));
      } else {
        await tap(tester, find.byKey(const ValueKey('scan-portion-0')));
        await tester.enterText(
          find.byKey(const ValueKey('portion-weight')),
          '٢٥٠',
        );
        await frames(tester);
        tester.testTextInput.hide();
        await frames(tester);
        await tap(tester, find.byKey(const ValueKey('scan-apply-portion')));
      }
      expect(draft.valid, isTrue, reason: entry.$1);
      final expected = draft.totals;
      final existing = state.dailyLog.length;
      final count = draft.items.length;
      await binding.takeScreenshot(
        '${Platform.operatingSystem}_scanner-${entry.$1}-ku-dark',
      );
      await tap(tester, find.byKey(const ValueKey('scan-confirm')));
      await tap(tester, find.byKey(const ValueKey('scan-save')));
      expect(state.dailyLog.length, existing + count);
      expect(
        state.dailyLog.skip(existing).fold<double>(0, (s, e) => s + e.calories),
        closeTo(expected['calories']!, .00001),
      );
      expect(tester.takeException(), isNull, reason: entry.$1);
    }
    for (final lang in ['en', 'ar', 'ku']) {
      for (final dark in [false, true]) {
        await state.setLang(lang);
        await state.setTheme(dark ? 'dark' : 'light');
        final d = ScanMealDraft.fromScan(
          scanFixture(['g2', 'p1']),
          state.catalog.foods,
          {},
          lang,
        );
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ScanResultEditor(
              draft: d,
              foods: state.catalog.foods,
              disabled: {},
              lang: lang,
              simulated: true,
              onSave: (_) async => false,
            ),
          ),
        );
        await frames(tester);
        await binding.takeScreenshot(
          '${Platform.operatingSystem}_scanner-$lang-${dark ? 'dark' : 'light'}',
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('scan-save'))).bottom,
          lessThanOrEqualTo(
            tester.view.physicalSize.height / tester.view.devicePixelRatio,
          ),
        );
        navigator.pop();
        await frames(tester);
        expect(tester.takeException(), isNull);
      }
    }
    final saved = state.dailyLog.map((e) => e.toMap()).toList();
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
    state.dispose();
    // Recreate the backend, session and app state as on an app restart.
    final restarted = DemoBackend(prefs);
    final restartedApi = ApiService(
      baseUrl: DemoBackend.baseUrl,
      storage: DemoStorage(prefs),
      client: restarted.client,
    );
    state = AppState(
      authService: AuthService(api: restartedApi),
      apiService: restartedApi,
      initializeOnCreate: false,
      optionalDeviceServicesEnabled: false,
    );
    await state.initializeSession();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const BnyadApp()),
    );
    for (
      var wait = 0;
      wait < 100 && state.dailyLog.length != saved.length;
      wait++
    ) {
      await frames(tester, 2);
    }
    expect(state.isAuthenticated, isTrue);
    expect(state.dailyLog.map((e) => e.toMap()).toList(), saved);
    expect(state.lang, 'ku');
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
    state.dispose();
    tester.testTextInput.unregister();
  });
  photos.main();
}
