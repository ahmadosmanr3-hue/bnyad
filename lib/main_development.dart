import 'package:flutter/material.dart';
import 'config/staging_config.dart';
import 'main.dart' as app;

/// No production fallback, Google AI, push, billing or real user data.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StagingStatus('Verifying staging…'));
  try {
    final config = StagingConfig.parse(
      const String.fromEnvironment('STAGING_API_BASE_URL'),
      const String.fromEnvironment('STAGING_ENVIRONMENT_ID'),
    );
    await config.verify();
    await app.runBnyad(
      apiBaseUrl: config.api.toString(),
      aiEnabled: false,
      optionalIntegrations: false,
    );
  } on StagingUnavailable catch (error) {
    runApp(_StagingStatus(error.message));
  }
}

class _StagingStatus extends StatelessWidget {
  final String message;
  const _StagingStatus(this.message);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('BNYAD Dev — staging')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$message\n\nProduction access and Gemini are disabled. '
            'Use fictional test accounts and health information only. '
            'Reopen the app after staging is ready.',
          ),
        ),
      ),
    ),
  );
}
