import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Only app-owned native rationale text follows this setting. OS dialogs remain OS-controlled.
Future<void> syncNativeLanguage(String language) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await const MethodChannel(
      'com.bnyad.app/localization',
    ).invokeMethod<void>('setLanguage', language);
  } on MissingPluginException {
    // Widget tests / older development binaries have no localization bridge.
  } on PlatformException {
    // Locale synchronization must never block authentication or health reads.
  }
}
