import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activity/step_health_provider.dart';
import 'activity/step_tracker.dart';
import 'activity/step_widgets.dart';
import 'models/user_profile.dart';
import 'theme/app_theme.dart';

/// Not imported by any BNYAD entry point. No auth/API/demo/Firebase startup.
bool healthTestRuntimeAllowed({
  required bool release,
  required bool web,
  required TargetPlatform platform,
  required bool nativeAllowed,
}) => !release && !web && platform == TargetPlatform.iOS && nativeAllowed;

/// Never let UserProfile's normal onboarding defaults become invented body
/// measurements if diagnostic settings are incomplete or corrupt.
UserProfile? parseHealthTestProfile(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final weight = raw['weight'], height = raw['height'], age = raw['age'];
  if (weight is! num ||
      !weight.isFinite ||
      weight < 20 ||
      weight > 350 ||
      height is! num ||
      !height.isFinite ||
      height < 80 ||
      height > 250 ||
      age is! int ||
      age < 1 ||
      age > 120 ||
      ![
        'sedentary',
        'lightlyActive',
        'moderatelyActive',
        'veryActive',
        'extraActive',
      ].contains(raw['activityLevel']) ||
      raw['disabilities'] is! List ||
      !(raw['disabilities'] as List).every((v) => v == 'cautious')) {
    return null;
  }
  return UserProfile.fromMap(raw);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var nativeAllowed = false;
  if (!kReleaseMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      nativeAllowed =
          await const MethodChannel(
            'com.bnyad.app/steps',
          ).invokeMethod<bool>('healthDiagnosticAllowed') ==
          true;
    } catch (_) {
      /* Missing native guard always fails closed. */
    }
  }
  if (!healthTestRuntimeAllowed(
    release: kReleaseMode,
    web: kIsWeb,
    platform: defaultTargetPlatform,
    nativeAllowed: nativeAllowed,
  )) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Health diagnostic disabled. Use the separate native development bundle.',
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(const HealthTestApp());
}

class HealthTestApp extends StatefulWidget {
  const HealthTestApp({super.key});
  @override
  State<HealthTestApp> createState() => _HealthTestAppState();
}

class _HealthTestAppState extends State<HealthTestApp>
    with WidgetsBindingObserver {
  final store = LocalStepSettingsStore();
  static const profileKey = 'bnyad_healthtest_profile_v1';
  UserProfile? profile;
  late final StepTracker tracker;
  bool ready = false;
  String? error;
  String locale = 'en';
  ThemeMode theme = ThemeMode.system;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tracker = StepTracker(
      provider: NativeStepHealthProvider(),
      store: store,
      profile: () => profile,
    );
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final raw = await store.read(profileKey);
      if (raw != null) profile = parseHealthTestProfile(jsonDecode(raw));
      await tracker.attach('healthkit-diagnostic.local-only');
    } catch (_) {
      error = 'Could not restore local settings. No health data is fabricated.';
    }
    if (mounted) setState(() => ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      tracker.setForeground(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tracker.dispose();
    super.dispose();
  }

  Future<void> _editProfile(BuildContext context) async {
    final value = await showDialog<UserProfile>(
      context: context,
      builder: (_) => _HealthProfileDialog(profile: profile),
    );
    if (value == null) return;
    try {
      // Only user-entered diagnostic preferences, local device keychain only.
      await store.write(
        profileKey,
        jsonEncode({
          'uid': 'health-diagnostic',
          'weight': value.weight,
          'height': value.height,
          'age': value.age,
          'activityLevel': value.activityLevel,
          'disabilities': value.disabilities,
        }),
      );
      if (!mounted) return;
      setState(() {
        profile = value;
        error = null;
      });
      // Existing accepted/manual goals are deliberately not reset.
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not save profile on this device.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BNYAD Health Test',
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: theme,
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      'BNYAD HEALTH TEST · REAL APPLE HEALTH',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'No backend, login, AI or simulated steps. '
                      'No nutrition targets are created or changed.',
                      textAlign: TextAlign.center,
                    ),
                    if (error != null) Text(error!),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: ready ? () => _editProfile(context) : null,
                          child: Text(
                            profile == null
                                ? 'Set your profile'
                                : 'Edit local profile',
                          ),
                        ),
                        DropdownButton<String>(
                          value: locale,
                          onChanged: (v) => setState(() => locale = v!),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('EN')),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                            DropdownMenuItem(value: 'ku', child: Text('کوردی')),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Toggle light/dark theme',
                          onPressed: () => setState(
                            () => theme =
                                Theme.of(context).brightness == Brightness.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          ),
                          icon: const Icon(Icons.brightness_6_outlined),
                        ),
                      ],
                    ),
                    if (profile == null)
                      const Text(
                        'Enter your own weight, height and age '
                        'for calorie estimates and starting-goal suggestions. No sample body data is used.',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ready
                    ? StepDetailsScreen(
                        tracker: tracker,
                        locale: locale,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HealthProfileDialog extends StatefulWidget {
  final UserProfile? profile;
  const _HealthProfileDialog({this.profile});
  @override
  State<_HealthProfileDialog> createState() => _HealthProfileDialogState();
}

class _HealthProfileDialogState extends State<_HealthProfileDialog> {
  final form = GlobalKey<FormState>();
  late final weight = TextEditingController(
    text: widget.profile?.weight.toString(),
  );
  late final height = TextEditingController(
    text: widget.profile?.height.toString(),
  );
  late final age = TextEditingController(text: widget.profile?.age.toString());
  late String activity = widget.profile?.activityLevel ?? 'sedentary';
  late bool gentle = widget.profile?.disabilities.isNotEmpty ?? false;
  @override
  void dispose() {
    weight.dispose();
    height.dispose();
    age.dispose();
    super.dispose();
  }

  Widget field(
    String label,
    TextEditingController controller,
    double min,
    double max, {
    bool whole = false,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(decimal: !whole),
    validator: (text) {
      final value = double.tryParse(text ?? '');
      return value == null ||
              !value.isFinite ||
              value < min ||
              value > max ||
              (whole && value != value.roundToDouble())
          ? 'Enter ${min.toInt()}–${max.toInt()}${whole ? ' (whole number)' : ''}.'
          : null;
    },
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your local test profile'),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Use your own values. Saved only on this iPhone, separately from BNYAD accounts. '
            'No Apple Health weight permission or nutrition calculation is used.',
          ),
          field('Weight (kg)', weight, 20, 350),
          field('Height (cm)', height, 80, 250),
          field('Age', age, 1, 120, whole: true),
          DropdownButtonFormField<String>(
            initialValue: activity,
            decoration: const InputDecoration(labelText: 'Activity level'),
            items: const [
              DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
              DropdownMenuItem(
                value: 'lightlyActive',
                child: Text('Lightly active'),
              ),
              DropdownMenuItem(
                value: 'moderatelyActive',
                child: Text('Moderately active'),
              ),
              DropdownMenuItem(value: 'veryActive', child: Text('Very active')),
              DropdownMenuItem(
                value: 'extraActive',
                child: Text('Extra active'),
              ),
            ],
            onChanged: (value) => activity = value!,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Use cautious goals (limited mobility, pregnancy or breastfeeding)',
            ),
            value: gentle,
            onChanged: (value) => setState(() => gentle = value!),
          ),
          const Text(
            'After saving, review the starting suggestion. '
            'Existing goals stay unchanged; use “Change goal manually” to accept a different target.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(
            context,
            UserProfile.fromMap({
              'uid': 'health-diagnostic',
              'weight': double.parse(weight.text),
              'height': double.parse(height.text),
              'age': double.parse(age.text).toInt(),
              'activityLevel': activity,
              'disabilities': gentle ? ['cautious'] : <String>[],
            }),
          );
        },
        child: const Text('Save on device'),
      ),
    ],
  );
}
