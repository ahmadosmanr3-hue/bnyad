import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/food_log_screen.dart';
import 'package:nutrify/services/api_service.dart';
import 'food_catalog_ui_test.dart' show FoodUiState;

class SaveState extends FoodUiState {
  SaveState(ApiService api) : super(api, 'en', false);
  int calls = 0;
  final completion = Completer<bool>();
  LogEntry? submitted;
  @override
  Future<bool> addLogEntry(LogEntry entry) {
    calls++;
    submitted = entry;
    return completion.future;
  }
}

void main() {
  testWidgets(
    'rapid save invokes logging once and opts into server calculation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ApiService(
        baseUrl: 'https://example.invalid/api',
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      final state = SaveState(api);
      state.catalog.accept(
        jsonDecode(File('assets/catalog/catalog.json').readAsStringSync()),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(home: const Scaffold(body: FoodLogScreen())),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'whole milk');
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(state.catalog.foods['usda_sr_171265']!.getLocalizedName('en'))
            .first,
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(ElevatedButton, state.t.addFood).last;
      await tester.ensureVisible(save);
      final callback = tester.widget<ElevatedButton>(save).onPressed!;
      callback();
      callback();
      await tester.pump();
      expect(state.calls, 1);
      expect(state.submitted!.catalogCalculation, true);
      expect(state.submitted!.amountUnit, 'ml');
      state.completion.complete(false);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
}
