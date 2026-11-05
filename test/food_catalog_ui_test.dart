import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/food_log_screen.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/theme/app_theme.dart';

class FoodUiState extends AppState {
  FoodUiState(ApiService api, this.language, this.dark)
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
  bool get isRTL => language != 'en';
  @override
  bool get isDark => dark;
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['NotoSans', 'NotoSansArabic']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('fonts/$family-Regular.ttf'))).load();
    }
  });
  for (final (lang, width, dark) in [
    ('ku', 320.0, false),
    ('ar', 390.0, true),
    ('en', 430.0, false),
    ('ku', 1024.0, true),
  ]) {
    testWidgets('catalog stars, source and liquid detail $lang $width dark=$dark', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 920);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiService(
        baseUrl: 'https://example.invalid/api',
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      final state = FoodUiState(api, lang, dark);
      state.catalog.accept(
        jsonDecode(File('assets/catalog/catalog.json').readAsStringSync()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Directionality(
                textDirection: state.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: const FoodLogScreen(),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'whole milk');
      await tester.pumpAndSettle();
      final key = const ValueKey('favorite-usda_sr_171265');
      expect(find.byKey(key), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(key)).isSelected, false);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(find.byKey(key)).isSelected, true);
      expect(state.favorites.length, 1);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/catalog_${lang}_${width.toInt()}_${dark ? 'dark' : 'light'}.png',
        ),
      );
      await tester.tap(
        find
            .text(state.catalog.foods['usda_sr_171265']!.getLocalizedName(lang))
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(find.byKey(key)).isSelected, true);
      expect(find.text('1 L'), findsOneWidget);
      await tester.ensureVisible(find.text('1 L'));
      await tester.tap(find.text('1 L'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/catalog_detail_${lang}_${width.toInt()}_${dark ? 'dark' : 'light'}.png',
        ),
      );
      final enterLabel = {
        'en': 'Enter amount',
        'ar': 'إدخال الكمية',
        'ku': 'نووسینی بڕ',
      }[lang]!;
      await tester.ensureVisible(find.text(enterLabel));
      await tester.tap(find.text(enterLabel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        lang == 'en' ? '0.25' : '٠٫٢٥',
      );
      await tester.tap(find.byType(DropdownButton<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('L').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(state.t.save).last);
      await tester.pumpAndSettle();
      expect(find.text('250 mL'), findsWidgets);
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(state.favorites, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      FoodItem.catalogOverrides = {};
    });
  }
}
