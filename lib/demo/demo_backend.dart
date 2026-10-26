import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/services/api_service.dart';
import 'demo_fixtures.dart';
import 'demo_guard.dart';

/// All responses stay in this isolated preview. No real HTTP transport/API key.
class DemoBackend {
  static const baseUrl = 'https://bnyad-demo.invalid/api';
  static const token = 'fictional-local-demo-session';
  final SharedPreferences preferences;
  late Map<String, dynamic> data;
  late final http.Client client;

  DemoBackend(this.preferences) {
    requireDemoDebugBuild();
    final saved = preferences.getString('demo_backend_v1');
    try {
      data = saved == null
          ? demoSeed()
          : jsonDecode(saved) as Map<String, dynamic>;
    } catch (_) {
      data = demoSeed();
    }
    client = MockClient(handle);
  }

  Map<String, dynamic> get profile => data['profile'] as Map<String, dynamic>;
  Map<String, dynamic> get user => {
    'id': 909009,
    'name': 'BNYAD Demo User',
    'phone': '+9647700000010',
    'profile': profile,
  };

  Future<void> persist() =>
      preferences.setString('demo_backend_v1', jsonEncode(data));

  Future<void> reset() async {
    data = demoSeed();
    await persist();
  }

  Future<void> seedLocalHistory() async {
    if (preferences.containsKey('weight_history')) return;
    final today = DateTime.now();
    await preferences.setString(
      'weight_history',
      jsonEncode({
        for (var day = 13; day >= 0; day--)
          demoDate(today.subtract(Duration(days: day))): 75.0 + day * 0.06,
      }),
    );
  }

  http.Response _reply(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    // Also intercept barcode-provider requests; never fall back to real HTTP.
    if (request.url.origin != Uri.parse(baseUrl).origin ||
        !request.url.path.startsWith('/api/')) {
      return _reply({
        'message': 'External requests are disabled in Demo Mode.',
      }, 404);
    }
    final path = request.url.path.substring(4);
    final method = request.method;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (path == '/auth/check-phone') {
      return _reply({'registered': !body['phone'].toString().endsWith('11')});
    }
    if (path == '/auth/request-otp') {
      return _reply({
        'message': 'Demo only: use code 123456. No SMS was sent.',
      });
    }
    if (path == '/auth/login' || path == '/auth/verify-otp') {
      if (path.endsWith('verify-otp') && body['code'] != '123456') {
        return _reply({'message': 'Demo verification code is 123456.'}, 422);
      }
      // Never retain supplied phone numbers, passwords, names or image bytes.
      return _reply({'token': token, 'user': user});
    }
    if (request.headers['Authorization'] != 'Bearer $token') {
      return _reply({'message': 'Demo session required.'}, 401);
    }
    switch ((method, path)) {
      case ('GET', '/auth/me'):
        return _reply({'data': user});
      case ('POST', '/auth/logout'):
        return _reply({'ok': true});
      case ('DELETE', '/auth/delete-account'):
        await reset();
        return _reply({'ok': true});
      case ('GET', '/profile'):
        return _reply({'data': profile});
      case ('PUT', '/profile'):
        profile.addAll(body);
        await persist();
        return _reply({'data': profile});
      case ('GET', '/logs'):
        final date = request.url.queryParameters['date'];
        return _reply({
          'data': (data['logs'] as List)
              .where((row) => row['logged_at'] == date)
              .toList(),
        });
      case ('POST', '/logs'):
        final row = {...body, 'id': 'demo-${data['nextId']}'};
        data['nextId'] = (data['nextId'] as int) + 1;
        (data['logs'] as List).add(row);
        await persist();
        return _reply({'data': row}, 201);
      case ('GET', '/water'):
        return _reply({
          'data': {
            'glasses': data['water'][request.url.queryParameters['date']] ?? 0,
          },
        });
      case ('PUT', '/water'):
        data['water'][body['log_date']] = body['glasses'];
        await persist();
        return _reply({'ok': true});
      case ('POST', '/weights'):
        (data['weights'] as List).add(body);
        await persist();
        return _reply({'ok': true}, 201);
      case ('GET', '/meal-plan'):
        return _reply({
          'data': {'plan': data['plan']},
        });
      case ('PUT', '/meal-plan'):
        data['plan'] = body['plan'];
        await persist();
        return _reply({'ok': true});
      case ('GET', '/subscription'):
        return _reply({
          'isPremium': data['premium'],
          'plan': 'DEMO — no purchase',
          'daysLeft': 365,
        });
      case ('GET', '/notifications'):
        return _reply({'data': []});
      case ('GET', '/ai/consent'):
        return _reply({
          'available': true, // Simulated fixtures only; never a Google request.
          'enabled': data['consent'],
          'version': ApiService.aiConsentVersion,
        });
      case ('PUT', '/ai/consent'):
        data['consent'] = body['enabled'] == true;
        await persist();
        return _reply({
          'enabled': data['consent'],
          'version': ApiService.aiConsentVersion,
        });
      case ('POST', '/ai/generate'):
        if (data['consent'] != true || data['premium'] != true) {
          return _reply({
            'code': 'consent_required',
            'message': 'Enable simulated consent and demo premium first.',
          }, 403);
        }
        final result = demoAiResponse(
          body['operation'].toString(),
          Map<String, dynamic>.from(body['input'] ?? {}),
        );
        return result == null
            ? _reply({
                'code': 'unavailable',
                'message': 'This operation is not simulated.',
              }, 503)
            : _reply({'data': result, 'simulated': true});
    }
    if (method == 'DELETE' && path.startsWith('/logs/')) {
      (data['logs'] as List).removeWhere(
        (row) => row['id'].toString() == path.substring(6),
      );
      await persist();
      return _reply({'ok': true});
    }
    return _reply({'message': 'Not implemented in the local demo.'}, 404);
  }
}
