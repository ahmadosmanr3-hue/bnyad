import 'native_photo_review_test.dart' as photos;
import 'package:nutrify/widgets/food_browse_tile.dart';
import 'package:nutrify/constants/food_serving_switch.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/demo/demo_backend.dart';
import 'package:nutrify/demo/demo_storage.dart';
import 'package:nutrify/main.dart' show BnyadApp;
import 'package:nutrify/main_iphone_preview.dart'
    show OfflinePreviewHttpOverrides;
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';
import 'package:nutrify/widgets/portion_editor.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native full-app portions, RTL, invalid quantities and navigation', (
    tester,
  ) async {
    HttpOverrides.global = OfflinePreviewHttpOverrides();
    SharedPreferences.setPrefix('bnyad_native_measurement_test.');
    final prefs = await SharedPreferences.getInstance();
    final backend = DemoBackend(prefs);
    final api = ApiService(
      baseUrl: DemoBackend.baseUrl,
      storage: DemoStorage(prefs),
      client: backend.client,
    );
    final state = AppState(
      authService: AuthService(api: api),
      apiService: api,
      initializeOnCreate: false,
      optionalDeviceServicesEnabled: false,
    );
    await state.initializeSession();
    if (!state.isAuthenticated) {
      await state.loginWithPassword('+9647700000010', 'demo-only');
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const BnyadApp()),
    );
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.testTextInput.register();
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    for (final lang in ['en', 'ar', 'ku']) {
      await state.setLang(lang);
      await settle(tester);
      state.setActiveTab(MainShellTab.foodLog);
      await settle(tester);
      for (final fixture in [
        ('usda_sr_168878', 'White rice, cooked'),
        ('usda_sr_170317', 'Cheese pizza, regular crust, frozen baked'),
        ('usda_sr_171265', 'Whole milk'),
      ]) {
        final id = fixture.$1;
        final query = fixture.$2;
        await tester.tap(find.byIcon(Icons.add).first);
        await settle(tester);
        await tester.enterText(find.byType(TextField).first, query);
        await settle(tester);
        final row = state.catalog.browse().firstWhere(
          (r) => r.displayFood.id == id,
        );
        debugPrint('QA row: ${row.nameForLang(lang)} / ${row.displayFood.id}');

        var food = row.displayFood;
        final tile = find
            .ancestor(
              of: find.byKey(ValueKey('favorite-$id')),
              matching: find.byType(FoodBrowseTile),
            )
            .first;
        await tester.ensureVisible(tile);
        await settle(tester);
        await tester.tap(tile);
        await settle(tester);
        var group = row.group;
        while (group != null && find.byType(PortionEditor).evaluate().isEmpty) {
          final option = state.catalog.preparations(group).first;
          await tester.tap(find.text(option.labelForLang(lang)).first);
          await settle(tester);
          if (option.opensSubGroup) {
            group = group.subGroups![option.subGroupKey!];
          } else {
            food = foodById(option.foodId)!;
            break;
          }
        }
        food = foodCanonicalGrams(food);

        debugPrint(
          'QA texts: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | ')}',
        );
        expect(find.byType(PortionEditor), findsOneWidget);
        final units = food.isLiquid
            ? ['liter', 'bottle', 'glass']
            : [
                'tablespoon',
                'small-bowl',
                'large-plate',
                if (query.toLowerCase().contains('pizza')) 'pizza',
              ];
        for (final unit in units) {
          final chip = find.byKey(ValueKey('portion-$unit'));
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await settle(tester);
          final weight = find.byKey(const ValueKey('portion-weight'));
          await tester.ensureVisible(weight);
          await tester.showKeyboard(weight);
          await settle(tester);
          await tester.enterText(weight, unit == 'liter' ? '0.25' : '125');
          await settle(tester);
          FocusManager.instance.primaryFocus?.unfocus();
          await settle(tester);
          final plus = find.byKey(const ValueKey('portion-plus'));
          await tester.ensureVisible(plus);
          for (var tap = 0; tap < 3; tap++) {
            await tester.tap(plus);
          }
          await settle(tester);
          final expected =
              food.calories *
              (unit == 'liter' ? 1000 : 500) /
              food.nutritionReferenceG;
          debugPrint(
            'QA amount/count ${tester.widget<TextField>(find.byKey(const ValueKey('portion-weight'))).controller!.text} / ${tester.widget<TextField>(find.byKey(const ValueKey('portion-count'))).controller!.text} expected $expected',
          );

          expect(find.text(expected.toStringAsFixed(1)), findsWidgets);
          await tester.ensureVisible(find.text(state.t.addFood).last);
          await settle(tester);
          await binding.takeScreenshot(
            '${Platform.operatingSystem}_${lang}_${query.replaceAll(' ', '-')}_$unit',
          );
          expect(tester.takeException(), isNull);
        }
        await state.setTheme('dark');
        await settle(tester);
        await binding.takeScreenshot(
          '${Platform.operatingSystem}_${lang}_${id}_dark',
        );
        await state.setTheme('light');
        await settle(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('portion-weight')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('portion-weight')),
          '-1',
        );
        await settle(tester);
        await tester.ensureVisible(find.text(state.t.addFood).last);
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, state.t.addFood).last,
              )
              .onPressed,
          isNull,
        );
        // close detail sheet, preserving full-app state/navigation
        Navigator.of(tester.element(find.byType(PortionEditor))).pop();
        await settle(tester);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    tester.testTextInput.unregister();
    state.dispose();
  });
  photos.main();
}
