import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrify/config/staging_config.dart';

void main() {
  const url = 'https://bnyad-staging.example.test/api';
  const id = 'bnyad-staging-fixture';
  final ready = {
    'environment': 'staging',
    'environmentId': id,
    'databaseReady': true,
    'aiEnabled': false,
    'contractVersion': 1,
  };

  test(
    'explicit staging URL is normalized, never using API_BASE_URL defaults',
    () {
      final config = StagingConfig.parse('$url/', id);
      expect(config.api.toString(), url);
      expect(config.environmentId, id);
    },
  );
  test(
    'missing, production, local, credential and insecure URLs fail closed',
    () {
      for (final candidate in [
        '',
        'https://bnyad-development.invalid/api',
        'https://nutrify-api-lovat.vercel.app/api',
        'https://nutrify-api-lovat.vercel.app./api',
        'http://bnyad-staging.example.test/api',
        'https://localhost/api',
        'https://127.0.0.1/api',
        'https://10.0.2.2/api',
        'https://[::1]/api',
        'https://user:password@bnyad-staging.example.test/api',
        '$url?token=fixture',
        '$url#fragment',
        'https://bnyad-staging.example.test:8443/api',
        'https://bnyad-staging.example.test/',
      ]) {
        expect(
          () => StagingConfig.parse(candidate, id),
          throwsA(isA<StagingUnavailable>()),
          reason: candidate,
        );
      }
      expect(
        () => StagingConfig.parse(url, ''),
        throwsA(isA<StagingUnavailable>()),
      );
    },
  );
  test(
    'preflight sends only an unauthenticated GET and disables redirects',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$url/staging/readiness');
        expect(request.headers.containsKey('authorization'), false);
        expect(request.body, isEmpty);
        expect(request.followRedirects, false);
        return http.Response(jsonEncode(ready), 200);
      });
      await StagingConfig.parse(url, id).verify(client: client);
    },
  );
  test(
    'wrong identity, enabled AI, unready DB and malformed responses are blocked',
    () async {
      for (final body in [
        {...ready, 'environment': 'production'},
        {...ready, 'environmentId': 'different-staging'},
        {...ready, 'aiEnabled': true},
        {...ready, 'databaseReady': false},
        {...ready, 'contractVersion': 2},
        {},
      ]) {
        await expectLater(
          StagingConfig.parse(url, id).verify(
            client: MockClient(
              (_) async => http.Response(jsonEncode(body), 200),
            ),
          ),
          throwsA(isA<StagingUnavailable>()),
        );
      }
      for (final code in [302, 401, 403, 404, 500, 503]) {
        await expectLater(
          StagingConfig.parse(url, id).verify(
            client: MockClient(
              (_) async => http.Response('hosting login', code),
            ),
          ),
          throwsA(isA<StagingUnavailable>()),
        );
      }
      await expectLater(
        StagingConfig.parse(
          url,
          id,
        ).verify(client: MockClient((_) async => http.Response('<html>', 200))),
        throwsA(isA<StagingUnavailable>()),
      );
    },
  );
  test(
    'connection failures do not expose private diagnostics in the UI',
    () async {
      try {
        await StagingConfig.parse(url, id).verify(
          client: MockClient(
            (_) async => throw Exception('private credentials'),
          ),
        );
        fail('must fail closed');
      } on StagingUnavailable catch (error) {
        expect(error.message, isNot(contains('private credentials')));
        expect(error.message, contains('Could not verify staging'));
      }
    },
  );
}
