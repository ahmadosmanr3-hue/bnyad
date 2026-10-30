import 'dart:convert';
import 'dart:io';

/// Runs from both native release build systems, even when Flutter is invoked
/// directly instead of through a release helper. Never include values in errors.
void validateStoreBuild({
  required String platform,
  required String configuration,
  required String bundle,
  required String encodedDefines,
  String target = 'lib/main.dart',
}) {
  final mode = configuration.toLowerCase();
  if (!mode.startsWith('release') && !mode.startsWith('profile')) return;
  if (mode.endsWith('-dev') &&
      (bundle == 'com.nutrify.bnyad.dev' ||
          bundle == 'com.nutrify.bnyad.healthtest')) {
    return;
  }
  final expectedBundle = platform == 'ios'
      ? 'com.nutrify.bnyad'
      : 'com.bnyad.app';
  if (bundle != expectedBundle ||
      (target != 'lib/main.dart' && !target.endsWith('/lib/main.dart'))) {
    throw const FormatException('Unexpected store bundle or entry point.');
  }
  final defines = <String, String>{};
  try {
    for (final entry in encodedDefines.split(',')) {
      if (entry.isEmpty) continue;
      final value = utf8.decode(base64.decode(entry));
      final equals = value.indexOf('=');
      if (equals < 1) throw const FormatException();
      defines[value.substring(0, equals)] = value.substring(equals + 1);
    }
  } catch (_) {
    throw const FormatException('Invalid release configuration encoding.');
  }
  const serverOnly = {
    'GEMINI_API_KEY',
    'DATABASE_URL',
    'JWT_SECRET',
    'ADMIN_PASSWORD',
    'REVENUECAT_SECRET_API_KEY',
  };
  if (defines.keys.any(serverOnly.contains)) {
    throw const FormatException(
      'Server credentials must never enter a mobile build.',
    );
  }
  final keyName = platform == 'ios'
      ? 'RC_IOS_PUBLIC_KEY'
      : 'RC_ANDROID_PUBLIC_KEY';
  final prefix = platform == 'ios' ? 'appl_' : 'goog_';
  final key = defines[keyName] ?? '';
  if (!RegExp('^$prefix[A-Za-z0-9_-]{15,}\$').hasMatch(key)) {
    throw FormatException(
      'Missing or invalid $keyName. Build with --dart-define-from-file=release-config.json.',
    );
  }
  if (defines['API_BASE_URL'] != 'https://nutrify-api-lovat.vercel.app/api') {
    throw const FormatException(
      'Store builds require the verified production API_BASE_URL.',
    );
  }
}

void main(List<String> args) {
  try {
    if (args.length != 3 || !['ios', 'android'].contains(args.first)) {
      throw const FormatException(
        'Expected platform, configuration and bundle.',
      );
    }
    validateStoreBuild(
      platform: args[0],
      configuration: args[1],
      bundle: args[2],
      encodedDefines: Platform.environment['DART_DEFINES'] ?? '',
      target: Platform.environment['FLUTTER_TARGET'] ?? 'lib/main.dart',
    );
  } on FormatException catch (error) {
    stderr.writeln('error: BNYAD release preflight: ${error.message}');
    exitCode = 1;
  }
}
