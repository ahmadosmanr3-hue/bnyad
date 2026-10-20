import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Only the explicitly marked non-release iOS development bundle can use this.
/// Production and ordinary staging keep their existing configuration unchanged.
class LocalBackendConfig {
  final Uri api;
  LocalBackendConfig._(this.api);
  factory LocalBackendConfig.parse(String value) {
    final uri = Uri.tryParse(value);
    final p = uri?.host.split('.').map(int.tryParse).toList() ?? [];
    final private =
        p.length == 4 &&
        p.every((n) => n != null && n >= 0 && n <= 255) &&
        (p[0] == 10 ||
            (p[0] == 192 && p[1] == 168) ||
            (p[0] == 172 && p[1]! >= 16 && p[1]! <= 31));
    if (uri == null ||
        !private ||
        uri.scheme != 'https' ||
        uri.port != 8443 ||
        uri.path != '/api' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'A private-network HTTPS test API is required.',
      );
    }
    return LocalBackendConfig._(uri);
  }
  Future<void> authorize() async {
    if (kIsWeb ||
        kReleaseMode ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        await const MethodChannel(
              'com.bnyad.app/steps',
            ).invokeMethod<bool>('localBackendAllowed') !=
            true) {
      throw StateError(
        'Local backend requires the marked iPhone development build.',
      );
    }
  }

  Future<void> verify(http.Client client) async {
    final request = http.Request(
      'GET',
      Uri.parse('$api/local-development/readiness'),
    )..followRedirects = false;
    final response = await (() async => http.Response.fromStream(
      await client.send(request),
    ))().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 ||
        response.body.length > 4096 ||
        response.headers['x-bnyad-test-mode'] != 'mock-no-google') {
      throw StateError('Local backend unavailable.');
    }
    // Decoding is intentionally below, not based only on a caller-controlled URL.
    verifyReadiness(response.body);
  }

  void verifyReadiness(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['environment'] != 'local-iphone' ||
        data['environmentId'] != 'bnyad-local-iphone-v1' ||
        data['databaseReady'] != true ||
        data['aiMode'] != 'mock' ||
        data['liveGoogleAllowed'] != false ||
        data['contractVersion'] != 1) {
      throw StateError(
        'Local backend identity or mock safeguards did not match.',
      );
    }
  }
}

/// Restricts all API sends to one approved HTTPS origin, with no redirects and
/// normal OS certificate verification. No trust-all callback or ATS bypass.
class LocalBackendClient extends http.BaseClient {
  final LocalBackendConfig config;
  final http.Client inner;
  LocalBackendClient(this.config, this.inner);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.origin != config.api.origin ||
        !request.url.path.startsWith('/api/')) {
      throw StateError('Request outside the local test API was blocked.');
    }
    request.followRedirects = false;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
