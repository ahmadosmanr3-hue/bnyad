import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity/step_health_provider.dart';
import 'activity/step_tracker.dart';
import 'config/local_backend_config.dart';
import 'main.dart' show BnyadApp;
import 'main_health_test.dart'
    show LocalHealthProfileDialog, parseHealthTestProfile;
import 'models/user_profile.dart';
import 'providers/app_state.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

/// Separate entry point. Never imported by production or staging. The Android
/// wrapper requires its own debug-only native guard and cannot arm real AI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var stage = 'configuration';
  try {
    final config = LocalBackendConfig.parse(
      const String.fromEnvironment('LOCAL_API_BASE_URL'),
      allowSupervisedFood: const bool.fromEnvironment(
        'LOCAL_ONE_USE_FOOD_TEST',
      ),
    );
    stage = 'native-development-authorization';
    await config.authorize();
    stage = 'certificate-configuration';
    const certificate = String.fromEnvironment('LOCAL_CA_DER_BASE64');
    if (certificate.isEmpty) {
      throw const FormatException('Local public CA certificate is required.');
    }
    // App-scoped trust of this local development CA only. TLS validity and IP
    // hostname checks remain enabled. No badCertificateCallback/ATS exception.
    final trust = SecurityContext(withTrustedRoots: false);
    final der = base64Decode(certificate);
    try {
      trust.setTrustedCertificatesBytes(der);
    } on TlsException {
      // Some Flutter/Dart iOS runtimes use the PEM parser instead of the
      // historical iOS DER parser. Re-encode the SAME public certificate;
      // this is not a failed-handshake retry or a certificate bypass.
      final encoded = base64Encode(der);
      final lines = [
        for (var i = 0; i < encoded.length; i += 64)
          encoded.substring(
            i,
            i + 64 < encoded.length ? i + 64 : encoded.length,
          ),
      ];
      trust.setTrustedCertificatesBytes(
        utf8.encode(
          '-----BEGIN CERTIFICATE-----\n${lines.join('\n')}\n-----END CERTIFICATE-----\n',
        ),
      );
    }
    final client = LocalBackendClient(
      config,
      IOClient(HttpClient(context: trust)),
    );
    stage = 'private-https-verification';
    await config.verify(client);
    stage = 'local-session-storage';
    SharedPreferences.setPrefix('bnyad_local_iphone_backend.');
    // API credentials/caches get a separate Keychain account, not the offline
    // preview's fixture storage or any published application's credentials.
    const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accountName: 'bnyad_local_iphone_backend',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    final api = ApiService(
      baseUrl: config.api.toString(),
      aiEnabled: true,
      client: client,
      storage: storage,
    );
    final healthStore = LocalStepSettingsStore();
    UserProfile? healthProfile;
    try {
      final raw = await healthStore.read(
        'bnyad_iphone_preview_health_profile_v1',
      );
      if (raw != null) healthProfile = parseHealthTestProfile(jsonDecode(raw));
    } catch (_) {
      /* Missing local values remain unknown, never fictional health data. */
    }
    final state = AppState(
      authService: AuthService(api: api),
      apiService: api,
      optionalDeviceServicesEnabled: false,
      initializeOnCreate: false,
      stepHealthProvider: NativeStepHealthProvider(),
      stepSettingsStore: healthStore,
      stepProfile: () => healthProfile,
    );
    await state.initializeSession();
    runApp(
      ChangeNotifierProvider.value(
        value: state,
        child: _LocalShell(
          config: config,
          onProfile: (context) async {
            final result = await showDialog<UserProfile>(
              context: context,
              builder: (_) => LocalHealthProfileDialog(profile: healthProfile),
            );
            if (result == null) return;
            await healthStore.write(
              'bnyad_iphone_preview_health_profile_v1',
              jsonEncode({
                'weight': result.weight,
                'height': result.height,
                'age': result.age,
                'activityLevel': result.activityLevel,
                'disabilities': result.disabilities,
              }),
            );
            healthProfile = result;
            state.steps.refreshProfilePresentation();
          },
        ),
      ),
    );
  } catch (error) {
    final failure = 'Stage: $stage (${error.runtimeType}).';
    // No raw request, credentials, health data, provider error or TLS bypass.
    stderr.writeln('BNYAD local startup: $failure');
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('BNYAD Dev — local setup')),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '$failure\n\nCould not verify the private HTTPS backend. Keep the Mac backend running, connect both devices to the same private Wi-Fi, and allow Local Network access. No production fallback or Google call was made. After setup, close and reopen BNYAD Dev.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalShell extends StatelessWidget {
  final LocalBackendConfig config;
  final Future<void> Function(BuildContext) onProfile;
  const _LocalShell({required this.onProfile, required this.config});
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().lang;
    final mockLabel = lang == 'ar'
        ? 'اختبار محلي • ذكاء اصطناعي محاكى • لا اتصال بغوغل'
        : ['ku', 'ckb'].contains(lang)
        ? 'تاقیکردنەوەی ناوخۆیی • زیرەکی دەستکردی تاقیکردنەوە • گووگڵ ناچالاکە'
        : 'LOCAL TEST • SIMULATED AI • NO GOOGLE';
    return ValueListenableBuilder<String>(
      valueListenable: config.foodTestStatus,
      builder: (_, status, _) {
        final label = !config.allowSupervisedFood
            ? mockLabel
            : status == 'real-closed'
            ? (lang == 'ar'
                  ? 'نتيجة طعام حقيقية من جيميني • الاتصال المباشر مغلق'
                  : ['ku', 'ckb'].contains(lang)
                  ? 'ئەنجامی خواردنی ڕاستەقینەی جێمینای • دەستگەیشتنی ڕاستەوخۆ داخراوە'
                  : 'REAL GEMINI FOOD RESULT • LIVE ACCESS CLOSED')
            : ['failed-closed', 'closed'].contains(status)
            ? (lang == 'ar'
                  ? 'انتهى اختبار الطعام • لا إعادة محاولة • البقية محاكاة'
                  : ['ku', 'ckb'].contains(lang)
                  ? 'تاقیکردنەوەی خواردن کۆتایی هات • دووبارە مەکەرەوە • ئەوانی تر دەستکردن'
                  : 'FOOD TEST CLOSED • NO RETRY • OTHER AI SIMULATED')
            : (lang == 'ar'
                  ? 'اختبار طعام واحد بإشراف • بقية الذكاء الاصطناعي محاكاة'
                  : ['ku', 'ckb'].contains(lang)
                  ? 'یەک تاقیکردنەوەی خواردن بە چاودێری • زیرەکییەکانی تر دەستکردن'
                  : 'ONE SUPERVISED FOOD TEST • OTHER AI SIMULATED');
        return MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Material(
                    color: const Color(0xFFFFE8A3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (ctx) => IconButton(
                              tooltip: 'Health profile — device only',
                              onPressed: () => onProfile(ctx),
                              icon: const Icon(
                                Icons.directions_walk,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(child: BnyadApp()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
