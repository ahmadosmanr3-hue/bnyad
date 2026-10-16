import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _nativePreviewAuthorized = false;

bool isAllowedNativePreview({
  required bool release,
  required bool web,
  required TargetPlatform platform,
  required bool nativeAllowed,
}) => !release && !web && platform == TargetPlatform.iOS && nativeAllowed;

/// Only the explicit iPhone preview entry point calls this. A native check
/// requires the dev bundle, dev compilation and a preview-only plist marker.
Future<void> authorizeNativePreview() async {
  _nativePreviewAuthorized = false;
  if (!isAllowedNativePreview(
    release: kReleaseMode,
    web: kIsWeb,
    platform: defaultTargetPlatform,
    nativeAllowed: true,
  )) {
    throw StateError('Native preview is disabled in this build.');
  }
  final allowed = await const MethodChannel(
    'com.bnyad.app/steps',
  ).invokeMethod<bool>('offlinePreviewAllowed');
  if (allowed != true) {
    throw StateError('Native preview bundle not authorized.');
  }
  _nativePreviewAuthorized = true;
}

void requireNativePreview() {
  if (!_nativePreviewAuthorized ||
      !isAllowedNativePreview(
        release: kReleaseMode,
        web: kIsWeb,
        platform: defaultTargetPlatform,
        nativeAllowed: _nativePreviewAuthorized,
      )) {
    throw StateError('Native preview authorization is required.');
  }
}

/// Browser demos remain restricted to debug on loopback. The separate native
/// preview has its own explicit authorization; this function never permits it.
bool isAllowedDemoEnvironment({
  required bool debug,
  required bool web,
  required String host,
}) =>
    debug &&
    web &&
    const {'localhost', '127.0.0.1', '::1', '[::1]'}.contains(host);

void requireDemoRuntime() {
  if (!isAllowedDemoEnvironment(
    debug: kDebugMode,
    web: kIsWeb,
    host: Uri.base.host,
  )) {
    throw StateError('BNYAD Demo is restricted to localhost debug web builds.');
  }
}

/// Browser fixtures remain debug-only. Profile-mode fixtures require an
/// explicit native dev-bundle handshake; release builds always fail closed.
void requireDemoDebugBuild() {
  if (!kDebugMode &&
      !(_nativePreviewAuthorized &&
          !kReleaseMode &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS)) {
    throw StateError('Demo services are disabled outside debug builds.');
  }
}
