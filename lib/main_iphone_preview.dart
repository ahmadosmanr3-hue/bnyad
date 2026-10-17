import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'activity/step_health_provider.dart';
import 'activity/step_tracker.dart';
import 'demo/demo_backend.dart';
import 'demo/demo_guard.dart';
import 'demo/demo_shell.dart';
import 'demo/demo_storage.dart';
import 'demo/demo_url_launcher.dart';
import 'main.dart' show BnyadApp;
import 'main_health_test.dart'
    show LocalHealthProfileDialog, parseHealthTestProfile;
import 'models/user_profile.dart';
import 'providers/app_state.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/food_barcode_service.dart';

/// Defense in depth: even an accidentally constructed Dart network client
/// cannot send a request in this isolated entry point. MockClient does no IO.
class OfflinePreviewHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw UnsupportedError(
        'Network disabled in BNYAD offline iPhone preview.',
      );
}

/// Not imported by production/main_development/main_demo. Complete existing
/// BnyadApp, fictional local API fixtures, REAL native health, never fake steps.
Future<void> main() => runNativeOfflinePreview();

/// Shared by the isolated iPhone and Android preview launchers only.
Future<void> runNativeOfflinePreview() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await authorizeNativePreview();
    HttpOverrides.global = OfflinePreviewHttpOverrides();
    SharedPreferences.setPrefix(
      defaultTargetPlatform == TargetPlatform.android
          ? 'bnyad_android_preview.'
          : 'bnyad_iphone_preview.',
    );
    final preferences = await SharedPreferences.getInstance();
    final backend = DemoBackend(preferences);
    backend.data['consent'] = false;
    await backend.persist();
    await backend.seedLocalHistory();
    final healthProfile = NativePreviewHealthProfile(LocalStepSettingsStore());
    await healthProfile.restore();
    UrlLauncherPlatform.instance = DemoUrlLauncher();
    FoodBarcodeService.clientOverride = backend.client;
    final api = ApiService(
      baseUrl: DemoBackend.baseUrl,
      aiEnabled: false,
      storage: DemoStorage(preferences),
      client: backend.client,
    );
    final state = AppState(
      authService: AuthService(api: api),
      apiService: api,
      initializeOnCreate: false,
      optionalDeviceServicesEnabled: false,
      stepHealthProvider: NativeStepHealthProvider(),
      stepSettingsStore: LocalStepSettingsStore(),
      stepProfile: () => healthProfile.value,
      stepDiagnostics: (message) =>
          debugPrint('BNYAD preview health: $message'),
    );
    await state.initializeSession();
    // Local fixture session, not a production guest/authentication bypass.
    // Explicit login/onboarding/registration screens remain in local controls.
    if (!state.isAuthenticated) {
      final error = await state.loginWithPassword(
        '+9647700000010',
        'demo-only',
      );
      if (error != null) throw StateError('Local fixture session unavailable.');
    }
    runApp(
      ChangeNotifierProvider.value(
        value: state,
        child: DemoShell(
          backend: backend,
          nativeHealth: true,
          onHealthProfile: (context) async {
            final value = await showDialog<UserProfile>(
              context: context,
              builder: (_) =>
                  LocalHealthProfileDialog(profile: healthProfile.value),
            );
            if (value == null) return;
            try {
              await healthProfile.save(value);
              state.steps.refreshProfilePresentation();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save local Health profile.'),
                  ),
                );
              }
            }
          },
          child: const BnyadApp(),
        ),
      ),
    );
  } catch (_) {
    // Fail closed. No production fallback or misleading unreachable API login.
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'BNYAD offline preview could not start. '
                'Use the dedicated development bundle and preview configuration. '
                'No production server was contacted.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Body information for REAL-step estimates never enters the fictional API,
/// its profile/weight history, analytics or network transport.
class NativePreviewHealthProfile {
  final StepSettingsStore store;
  UserProfile? value;
  static String get key => defaultTargetPlatform == TargetPlatform.android
      ? 'bnyad_android_preview_health_profile_v1'
      : 'bnyad_iphone_preview_health_profile_v1';
  NativePreviewHealthProfile(this.store);
  Future<void> restore() async {
    requireNativePreview();
    final raw = await store.read(key);
    try {
      value = raw == null ? null : parseHealthTestProfile(jsonDecode(raw));
    } catch (_) {
      value = null;
    }
  }

  Future<void> save(UserProfile profile) async {
    requireNativePreview();
    final data = {
      'weight': profile.weight,
      'height': profile.height,
      'age': profile.age,
      'activityLevel': profile.activityLevel,
      'disabilities': profile.disabilities,
    };
    if (parseHealthTestProfile(data) == null) {
      throw const FormatException('Invalid profile');
    }
    await store.write(key, jsonEncode(data));
    value = profile;
  }
}
