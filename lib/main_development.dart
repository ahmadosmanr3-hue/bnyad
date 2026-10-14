import 'main.dart' as app;

/// Isolated device smoke test: no production backend, Google AI, push or billing.
/// No staging service has been supplied. Authentication and remote features are
/// intentionally unavailable; do not enter real health or account information.
Future<void> main() => app.runBnyad(
  apiBaseUrl: 'https://bnyad-development.invalid/api',
  aiEnabled: false,
  optionalIntegrations: false,
);
