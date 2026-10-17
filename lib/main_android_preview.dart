import 'main_iphone_preview.dart' show runNativeOfflinePreview;

// Complete existing BnyadApp with local API fixtures and NativeStepHealthProvider.
// Android must pass the debug-only native package/Gradle guard. No fake steps.
Future<void> main() => runNativeOfflinePreview();
