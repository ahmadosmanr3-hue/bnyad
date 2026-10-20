import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/config/local_backend_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const url = 'https://192.168.1.117:8443/api';
  final body = jsonEncode({
    'environment': 'local-iphone',
    'environmentId': 'bnyad-local-iphone-v1',
    'databaseReady': true,
    'aiMode': 'mock',
    'liveGoogleAllowed': false,
    'contractVersion': 1,
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.bnyad.app/steps'),
          null,
        );
  });
  test(
    'local configuration rejects public, production, insecure or ambiguous URLs',
    () {
      expect(LocalBackendConfig.parse(url).api.toString(), url);
      for (final value in [
        'http://192.168.1.117:8443/api',
        'https://nutrify-api-lovat.vercel.app/api',
        'https://8.8.8.8:8443/api',
        'https://127.0.0.1:8443/api',
        'https://localhost:8443/api',
        'https://192.168.1.117/api',
        'https://192.168.1.117:8443/api?token=x',
        'https://user@192.168.1.117:8443/api',
      ]) {
        expect(() => LocalBackendConfig.parse(value), throwsFormatException);
      }
    },
  );
  test(
    'native handshake requires marked iOS development application',
    () async {
      final config = LocalBackendConfig.parse(url);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var allowed = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.bnyad.app/steps'),
            (call) async {
              expect(call.method, 'localBackendAllowed');
              return allowed;
            },
          );
      await expectLater(config.authorize(), throwsStateError);
      allowed = true;
      await config.authorize();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await expectLater(config.authorize(), throwsStateError);
    },
  );
  test(
    'readiness requires matching environment, mocks and explicit Google block',
    () {
      final config = LocalBackendConfig.parse(url);
      config.verifyReadiness(body);
      for (final change in [
        {'liveGoogleAllowed': true},
        {'aiMode': 'live'},
        {'databaseReady': false},
        {'environment': 'production'},
        {'environmentId': 'different'},
        {'contractVersion': 2},
      ]) {
        expect(
          () => config.verifyReadiness(
            jsonEncode({
              ...jsonDecode(body) as Map<String, dynamic>,
              ...change,
            }),
          ),
          throwsStateError,
        );
      }
    },
  );
  test('HTTP transport blocks other origins and disables redirects', () async {
    var calls = 0;
    final config = LocalBackendConfig.parse(url);
    final client = LocalBackendClient(
      config,
      MockClient((request) async {
        calls++;
        expect(request.followRedirects, false);
        return http.Response(
          body,
          200,
          headers: {'x-bnyad-test-mode': 'mock-no-google'},
        );
      }),
    );
    await config.verify(client);
    expect(calls, 1);
    await expectLater(
      client.get(Uri.parse('https://production.example/api/auth/me')),
      throwsStateError,
    );
    await expectLater(
      client.get(Uri.parse('http://192.168.1.117:8443/api/auth/me')),
      throwsStateError,
    );
    expect(calls, 1);
  });
  test('redirecting, unlabeled or oversized readiness fails closed', () async {
    final config = LocalBackendConfig.parse(url);
    for (final response in [
      http.Response('', 302),
      http.Response(body, 200),
      http.Response('x' * 4097, 200),
    ]) {
      final client = MockClient((_) async => response);
      await expectLater(config.verify(client), throwsStateError);
    }
  });
}
