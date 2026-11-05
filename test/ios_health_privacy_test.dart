import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every native configuration declares both HealthKit purpose strings',
    () {
      for (final name in [
        'Info',
        'Development-Info',
        'LocalBackend-Info',
        'OfflinePreview-Info',
        'HealthTest-Info',
      ]) {
        final plist = File('ios/Runner/$name.plist').readAsStringSync();
        for (final key in [
          'NSHealthShareUsageDescription',
          'NSHealthUpdateUsageDescription',
        ]) {
          expect(
            RegExp('<key>$key</key>\\s*<string>[^<]+</string>').hasMatch(plist),
            true,
            reason: '$name must pass native privacy validation',
          );
        }
      }
    },
  );
  test(
    'health privacy descriptions are localized in every supported iOS locale',
    () {
      for (final locale in ['en', 'ar', 'ku', 'ckb']) {
        final text = File(
          'ios/Runner/$locale.lproj/InfoPlist.strings',
        ).readAsStringSync();
        for (final key in [
          'NSHealthShareUsageDescription',
          'NSHealthUpdateUsageDescription',
        ]) {
          expect(
            RegExp('"$key"\\s*=\\s*"[^"]+";').hasMatch(text),
            true,
            reason: '$locale missing $key',
          );
        }
      }
    },
  );
  test('adding validator metadata does not authorize HealthKit writes', () {
    final native = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final authorization = RegExp(
      r'store\.requestAuthorization\(toShare:\s*\[\],\s*read:\s*types\)',
    );
    expect(authorization.hasMatch(native), true);
    expect(
      RegExp(
        r'store\.(save|delete|enableBackgroundDelivery)\(',
      ).hasMatch(native),
      false,
    );
  });
}
