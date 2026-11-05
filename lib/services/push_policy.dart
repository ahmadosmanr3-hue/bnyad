/// Shared display rules prevent the OS alert and a local alert appearing twice.
bool shouldDisplayBackgroundPush({required bool hasSystemNotification}) =>
    !hasSystemNotification;

/// A null APNs token means registration has not completed, not that push is off.
Future<bool> waitForApnsToken(
  Future<String?> Function() readToken, {
  Future<void> Function(Duration)? delay,
  int attempts = 8,
}) async {
  final pause = delay ?? Future<void>.delayed;
  for (var i = 0; i < attempts; i++) {
    if (await readToken() != null) return true;
    if (i + 1 < attempts) await pause(const Duration(milliseconds: 500));
  }
  return false;
}
