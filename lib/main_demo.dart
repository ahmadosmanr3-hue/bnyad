import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:nutrify/main.dart' show BnyadApp;
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/services/food_barcode_service.dart';
import 'demo/demo_backend.dart';
import 'demo/demo_guard.dart';
import 'demo/demo_shell.dart';
import 'demo/demo_storage.dart';
import 'demo/demo_url_launcher.dart';

/// Explicit opt-in: production main.dart never imports this entrypoint.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    requireDemoRuntime();
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Demo disabled: use a localhost debug web build.'),
          ),
        ),
      ),
    );
    return;
  }
  SharedPreferences.setPrefix('bnyad_demo.');
  final prefs = await SharedPreferences.getInstance();
  final backend = DemoBackend(prefs);
  await backend.seedLocalHistory();
  UrlLauncherPlatform.instance = DemoUrlLauncher();
  FoodBarcodeService.clientOverride = backend.client;
  final api = ApiService(
    baseUrl: DemoBackend.baseUrl,
    storage: DemoStorage(prefs),
    client: backend.client,
  );
  final state = AppState(
    authService: AuthService(api: api),
    apiService: api,
    initializeOnCreate: false,
  );
  await state.initializeSession();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: DemoShell(backend: backend, child: const BnyadApp()),
    ),
  );
}
