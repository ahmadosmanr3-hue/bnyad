import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../tool/validate_store_build.dart';

String encoded(Map<String, String> values) => values.entries
    .map((e) => base64.encode(utf8.encode('${e.key}=${e.value}')))
    .join(',');

void main() {
  const config = {
    'API_BASE_URL': 'https://nutrify-api-lovat.vercel.app/api',
    'RC_IOS_PUBLIC_KEY': 'appl_fictional_public_sdk_key',
    'RC_ANDROID_PUBLIC_KEY': 'goog_fictional_public_sdk_key',
  };
  for (final platform in ['ios', 'android']) {
    final bundle = platform == 'ios' ? 'com.nutrify.bnyad' : 'com.bnyad.app';
    void check(Map<String, String> values, {String target = 'lib/main.dart'}) =>
        validateStoreBuild(
          platform: platform,
          configuration: 'Release',
          bundle: bundle,
          encodedDefines: encoded(values),
          target: target,
        );
    test('$platform rejects a release with no private build configuration', () {
      expect(() => check({}), throwsFormatException);
    });
    test(
      '$platform accepts existing public SDK and production API configuration',
      () {
        expect(() => check(config), returnsNormally);
      },
    );
    test(
      '$platform rejects local API, mock entry points and server secrets without printing values',
      () {
        expect(
          () => check({...config, 'API_BASE_URL': 'http://127.0.0.1:3000/api'}),
          throwsFormatException,
        );
        expect(
          () => check(config, target: 'lib/main_demo.dart'),
          throwsFormatException,
        );
        try {
          check({...config, 'GEMINI_API_KEY': 'fictional-do-not-print'});
          fail('Server key accepted');
        } on FormatException catch (error) {
          expect(error.message, isNot(contains('fictional-do-not-print')));
        }
      },
    );
  }
  test(
    'development health and offline previews remain separate from store builds',
    () {
      expect(
        () => validateStoreBuild(
          platform: 'ios',
          configuration: 'Profile-dev',
          bundle: 'com.nutrify.bnyad.dev',
          encodedDefines: '',
          target: 'lib/main_local_backend.dart',
        ),
        returnsNormally,
      );
    },
  );
  test('malformed encoded configuration reports a sanitized error', () {
    expect(
      () => validateStoreBuild(
        platform: 'ios',
        configuration: 'Release',
        bundle: 'com.nutrify.bnyad',
        encodedDefines: '%%%',
      ),
      throwsFormatException,
    );
  });
}
