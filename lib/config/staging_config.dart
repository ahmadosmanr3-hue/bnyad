import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Public staging identity, not an API secret. Never falls back to production.
class StagingConfig {
  final Uri api;
  final String environmentId;
  const StagingConfig._(this.api, this.environmentId);

  factory StagingConfig.parse(String baseUrl, String environmentId) {
    final uri = Uri.tryParse(baseUrl.trim());
    final host = uri?.host.toLowerCase() ?? '';
    if (uri == null ||
        uri.scheme != 'https' ||
        host.isEmpty ||
        !host.contains('.') ||
        host.endsWith('.') ||
        host.contains('..') ||
        RegExp(r'^[0-9.:]+$').hasMatch(host) ||
        host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.invalid') ||
        host == 'nutrify-api-lovat.vercel.app' ||
        host.endsWith('.nutrify-api-lovat.vercel.app') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.port != 443 ||
        !['/api', '/api/'].contains(uri.path) ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,80}$').hasMatch(environmentId)) {
      throw const StagingUnavailable(
        'A verified HTTPS staging API URL ending in /api and a staging '
        'environment ID are required. Production and local addresses are blocked.',
      );
    }
    return StagingConfig._(uri.replace(path: '/api'), environmentId);
  }

  Future<void> verify({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      // Do not follow redirects to another environment, even for the preflight.
      final request = http.Request('GET', Uri.parse('$api/staging/readiness'))
        ..followRedirects = false;
      final response = await httpClient
          .send(request)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const StagingUnavailable(
          'Staging is not ready or is protected by a hosting login.',
        );
      }
      final raw = await response.stream.bytesToString().timeout(
        const Duration(seconds: 12),
      );
      if (raw.length > 4096) throw const FormatException();
      final body = jsonDecode(raw);
      if (body is! Map<String, dynamic> ||
          body['environment'] != 'staging' ||
          body['environmentId'] != environmentId ||
          body['databaseReady'] != true ||
          body['aiEnabled'] != false ||
          body['contractVersion'] != 1) {
        throw const StagingUnavailable(
          'The server did not confirm the approved staging environment with AI disabled.',
        );
      }
    } on StagingUnavailable {
      rethrow;
    } catch (_) {
      // Never include remote bodies, credentials or connection strings.
      throw const StagingUnavailable(
        'Could not verify staging. Check its DNS, HTTPS, deployment and database configuration.',
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

class StagingUnavailable implements Exception {
  final String message;
  const StagingUnavailable(this.message);
}
