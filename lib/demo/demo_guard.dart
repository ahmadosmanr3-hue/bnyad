import 'package:flutter/foundation.dart';

/// A separate entrypoint is not sufficient: release/profile and remote hosts
/// must fail closed before constructing any demo authentication or services.
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

/// Services are testable on the VM, but unavailable in release/profile builds.
void requireDemoDebugBuild() {
  if (!kDebugMode) {
    throw StateError('Demo services are disabled outside debug builds.');
  }
}
