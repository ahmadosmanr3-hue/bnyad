import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/meal.dart';

/// REST client for the active Next.js backend and compatible bearer-token API.
class ApiService {
  final String baseUrl;
  final bool aiEnabled;
  String? _token;
  int? _userId;

  final FlutterSecureStorage _secureStorage;
  late final _SafeHttp _http;
  VoidCallback? onSessionInvalidated;
  static const aiConsentVersion = 'google-ai-2026-10-13-v1';
  String aiErrorCode = 'failed';
  bool? aiServiceAvailable;

  Future<bool?> getAiConsent() async {
    aiServiceAvailable = null;
    final owner = _token;
    if (!hasToken) return false;
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/ai/consent'),
        headers: _headers,
      );
      if (_token != owner) return null;
      if (response.statusCode != 200) {
        aiErrorCode = response.statusCode == 404
            ? 'serviceUpdate'
            : 'unavailable';
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      aiServiceAvailable = body['available'] is bool
          ? body['available'] as bool
          : null;
      if (aiServiceAvailable == false) {
        aiErrorCode = 'disabled';
        return null;
      }
      return body['enabled'] == true && body['version'] == aiConsentVersion;
    } catch (_) {
      aiErrorCode = 'unavailable';
      return null;
    }
  }

  Future<bool> setAiConsent(bool enabled) async {
    final owner = _token;
    if (!hasToken) return false;
    try {
      final response = await _http.put(
        Uri.parse('$baseUrl/ai/consent'),
        headers: _headers,
        body: jsonEncode({'enabled': enabled, 'version': aiConsentVersion}),
      );
      return _token == owner && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateAi(
    String operation,
    Map<String, dynamic> input,
  ) async {
    final owner = _token;
    aiErrorCode = 'failed';
    if (!aiEnabled) {
      aiErrorCode = 'unavailable';
      return null;
    }
    if (!hasToken) {
      aiErrorCode = 'signIn';
      return null;
    }
    final consent = await getAiConsent();
    if (consent != true || owner != _token) {
      if (consent == false) aiErrorCode = 'consentRequired';
      return null;
    }
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/ai/generate'),
        headers: _headers,
        body: jsonEncode({'operation': operation, 'input': input}),
      );
      if (_token != owner) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        if (operation == 'shopping') {
          // Keep trilingual maps intact; the view chooses the current locale.
          return data;
        }
        return data;
      }
      aiErrorCode = switch (response.statusCode) {
        401 => 'signIn',
        403 => 'notAuthorized',
        429 => switch (body['code']) {
          'ai_rate_limit' => 'rateLimit',
          'ai_daily_limit' => 'dailyLimit',
          'ai_budget_limit' => 'budgetLimit',
          'ai_provider_quota' => 'providerQuota',
          _ => 'quota',
        },
        413 => 'tooLarge',
        422 => 'invalidResult',
        502 => 'invalidResult',
        503 => switch (body['code']) {
          'ai_disabled' => 'disabled',
          'ai_not_configured' ||
          'ai_provider_access' ||
          'ai_model_unavailable' => 'configuration',
          _ => 'unavailable',
        },
        _ => 'failed',
      };
    } catch (_) {
      aiErrorCode = 'unavailable';
    }
    return null;
  }

  ApiService({
    required this.baseUrl,
    this.aiEnabled = true,
    FlutterSecureStorage? storage,
    http_pkg.Client? client,
  }) : _secureStorage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(migrateWithBackup: true),
           ) {
    _http = _SafeHttp(
      client ?? http_pkg.Client(),
      _handleUnauthorized,
      _readOfflineCache,
      _saveOfflineCache,
      (headers) => hasToken && headers?['Authorization'] == 'Bearer $_token',
    );
  }

  String? _offlineKey(Uri uri) => _userId == null || !hasToken
      ? null
      : 'api_cache_${_userId}_${uri.path.split('/').last}';

  Future<String?> _readOfflineCache(Uri uri) async {
    final key = _offlineKey(uri);
    if (key == null ||
        !['logs', 'water', 'meal-plan'].contains(uri.path.split('/').last)) {
      return null;
    }
    final raw = await _secureStorage.read(key: key);
    if (raw == null) return null;
    try {
      final cache = jsonDecode(raw) as Map<String, dynamic>;
      return cache['url'] == uri.toString() ? cache['body'] as String : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveOfflineCache(Uri uri, String body) async {
    final key = _offlineKey(uri);
    if (key == null ||
        !['logs', 'water', 'meal-plan'].contains(uri.path.split('/').last)) {
      return;
    }
    await _secureStorage.write(
      key: key,
      value: jsonEncode({'url': uri.toString(), 'body': body}),
    );
  }

  Future<void> _handleUnauthorized(Map<String, String>? headers) async {
    if (!hasToken || headers?['Authorization'] != 'Bearer $_token') return;
    await clearAuth();
    onSessionInvalidated?.call();
  }

  void dispose() => _http.close();

  // ─── Token management ──────────────────────────────

  Future<void> loadToken() async {
    _token = await _secureStorage.read(key: 'api_token');
    final userIdStr = await _secureStorage.read(key: 'api_user_id');
    _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
    // Older releases used preferences. Remove them only after secure writes
    // succeed, so an interrupted migration can be retried on the next launch.
    if (!hasToken) {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString('api_token');
      final legacyId = prefs.get('api_user_id')?.toString();
      final id = int.tryParse(legacyId ?? '');
      if (legacy != null && legacy.isNotEmpty && id != null) {
        await _persistAuth(legacy, id);
        await prefs.remove('api_token');
        await prefs.remove('api_user_id');
      }
    }
  }

  Future<void> _persistAuth(String token, int userId) async {
    final previousId = await _secureStorage.read(key: 'api_user_id');
    if (previousId != userId.toString()) {
      await _secureStorage.delete(key: 'api_pending_profile');
      await _secureStorage.delete(key: 'api_user_snapshot');
    }
    await _secureStorage.write(key: 'api_token', value: token);
    await _secureStorage.write(key: 'api_user_id', value: userId.toString());
    // A platform entitlement/storage failure must never look like a successful
    // sign-in that silently disappears on the next launch.
    if (await _secureStorage.read(key: 'api_token') != token ||
        await _secureStorage.read(key: 'api_user_id') != userId.toString()) {
      throw StateError('Could not securely persist sign-in.');
    }
    _token = token;
    _userId = userId;
  }

  Future<Map<String, dynamic>?> cachedUser() async {
    final raw = await _secureStorage.read(key: 'api_user_snapshot');
    if (raw == null) return null;
    try {
      final user = jsonDecode(raw) as Map<String, dynamic>;
      return user['id'] == _userId ? user : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(Map<String, dynamic> user) async {
    if (user['id'] != _userId || !hasToken) return;
    await _secureStorage.write(
      key: 'api_user_snapshot',
      value: jsonEncode(user),
    );
  }

  Future<void> _cacheProfile(Map<String, dynamic> profile) async {
    final user = await cachedUser() ?? <String, dynamic>{'id': _userId};
    await _cacheUser({...user, 'profile': profile});
  }

  UserProfile profileFromJson(Map<String, dynamic> data) =>
      _profileFromApi(data);

  Future<void> cacheCurrentData({
    List<LogEntry>? logs,
    int? waterMl,
    MealPlanData? mealPlan,
  }) async {
    if (!hasToken) return;
    if (logs != null) {
      await _saveOfflineCache(
        Uri.parse('$baseUrl/logs?date=${_todayString()}'),
        jsonEncode({
          'data': logs.map((e) => {'id': e.id, ...e.toMap()}).toList(),
        }),
      );
    }
    if (waterMl != null) {
      await _saveOfflineCache(
        Uri.parse('$baseUrl/water?date=${_todayString()}'),
        jsonEncode({
          'data': {'glasses': (waterMl / _mlPerGlass).round()},
        }),
      );
    }
    if (mealPlan != null) {
      await _saveOfflineCache(
        Uri.parse('$baseUrl/meal-plan'),
        jsonEncode({
          'data': {'plan': mealPlan.toMap()},
        }),
      );
    }
  }

  Future<void> clearAuth() async {
    final oldUser = _userId;
    _token = null;
    _userId = null;
    await _secureStorage.delete(key: 'api_token');
    await _secureStorage.delete(key: 'api_user_id');
    await _secureStorage.delete(key: 'api_user_snapshot');
    await _secureStorage.delete(key: 'api_pending_profile');
    for (final resource in ['logs', 'water', 'meal-plan']) {
      await _secureStorage.delete(key: 'api_cache_${oldUser}_$resource');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('api_user_id');
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;
  int? get userId => _userId;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Auth ──────────────────────────────────────────

  /// Asks the server to send an OTP SMS to [phone].
  /// Returns `null` on success or an error message string.
  Future<String?> requestOtp(String phone, {String? password}) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          if (password != null && password.isNotEmpty) 'password': password,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return body['message']?.toString() ?? 'OTP request failed';
    } catch (e) {
      debugPrint('requestOtp error: $e');
      return 'Network error — could not reach server.';
    }
  }

  /// Returns whether [phone] already has a registered account.
  /// On network failure returns `null`.
  Future<bool?> checkPhoneRegistered(String phone) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/check-phone'),
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return body['registered'] == true;
      }
      lastError =
          body['message']?.toString() ?? 'Could not check phone number.';
      return null;
    } catch (e) {
      debugPrint('checkPhoneRegistered error: $e');
      lastError = 'Network error — could not reach server.';
      return null;
    }
  }

  /// Verifies the OTP code and password. On success, stores the Sanctum token
  /// and returns a map with user data. On failure returns `null` and sets
  /// [lastError].
  String? lastError;
  bool lastLogReadSucceeded = false;

  Future<Map<String, dynamic>?> verifyOtp({
    required String phone,
    required String code,
    String? password,
    String? name,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'code': code,
          if (password != null && password.isNotEmpty) 'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['token']?.toString();
        final userData = body['user'] as Map<String, dynamic>?;
        final id = (userData?['id'] as num?)?.toInt();
        if (token != null &&
            token.isNotEmpty &&
            id != null &&
            userData != null) {
          await _persistAuth(token, id);
          await _cacheUser(userData);
        } else {
          lastError = 'Invalid sign-in response.';
          return null;
        }
        lastError = null;
        return userData;
      }

      lastError = body['message']?.toString() ?? 'Verification failed';
      return null;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      lastError = 'Network error — could not reach server.';
      return null;
    }
  }

  /// Logs in using phone number and password.
  Future<Map<String, dynamic>?> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = body['token']?.toString();
        final userData = body['user'] as Map<String, dynamic>?;
        final id = (userData?['id'] as num?)?.toInt();
        if (token != null &&
            token.isNotEmpty &&
            id != null &&
            userData != null) {
          await _persistAuth(token, id);
          await _cacheUser(userData);
        } else {
          lastError = 'Invalid sign-in response.';
          return null;
        }
        lastError = null;
        return userData;
      }

      lastError = body['message']?.toString() ?? 'Login failed';
      return null;
    } catch (e) {
      debugPrint('loginWithPassword error: $e');
      lastError = 'Network error — could not reach server.';
      return null;
    }
  }

  /// Fetches the currently authenticated user.
  Future<Map<String, dynamic>?> me() async {
    final requestToken = _token;
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      if (requestToken != _token || !hasToken) return null;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = (body['data'] ?? body) as Map<String, dynamic>;
        final id = (user['id'] as num?)?.toInt();
        if (id == null) return null;
        _userId = id;
        await _secureStorage.write(key: 'api_user_id', value: '$id');
        // Do not overwrite locally completed onboarding awaiting upload.
        final pending = await _secureStorage.read(key: 'api_pending_profile');
        if (pending != null) user['profile'] = jsonDecode(pending);
        await _cacheUser(user);
        return user;
      }
    } catch (e) {
      debugPrint('me() error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
    } catch (_) {}
    await clearAuth();
  }

  /// Permanently deletes the authenticated user account and all personal data.
  /// Adheres to App Store Review Guideline 5.1.1(v).
  Future<bool> deleteAccount() async {
    bool ok = false;
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: _headers,
      );
      ok = (response.statusCode >= 200 && response.statusCode < 300);
    } catch (e) {
      debugPrint('deleteAccount error: $e');
    }
    if (ok) await clearAuth();
    return ok;
  }

  // ─── User Profile ─────────────────────────────────

  Future<UserProfile?> getUserProfile() async {
    final requestOwner = _userId;
    final pending = await _secureStorage.read(key: 'api_pending_profile');
    if (pending != null) {
      final profile = _profileFromApi(
        jsonDecode(pending) as Map<String, dynamic>,
      );
      await saveUserProfile(profile);
      return profile;
    }
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
      );
      if (requestOwner != _userId || !hasToken) return null;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] ?? body) as Map<String, dynamic>;
        await _cacheProfile(data);
        return _profileFromApi(data);
      }
    } catch (e) {
      debugPrint('getUserProfile error: $e');
    }
    final cached = await cachedUser();
    final profile = cached?['profile'];
    return hasToken && profile is Map<String, dynamic>
        ? _profileFromApi(profile)
        : null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final body = jsonEncode(_profileToApi(profile));
    await _secureStorage.write(key: 'api_pending_profile', value: body);
    await _cacheProfile(_profileToApi(profile));
    // Retry a couple of times so onboarding completion reliably lands on the
    // server, but never block the app indefinitely on a stalled connection.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _http
            .put(Uri.parse('$baseUrl/profile'), headers: _headers, body: body)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _secureStorage.delete(key: 'api_pending_profile');
          return;
        }
        if (!hasToken || response.statusCode < 500) return;
      } catch (e) {
        debugPrint('saveUserProfile attempt $attempt error: $e');
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }
  }

  Future<void> updateProfileField(Map<String, dynamic> data) async {
    try {
      await _http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('updateProfileField error: $e');
    }
  }

  // ─── Daily Logs ───────────────────────────────────

  Future<List<LogEntry>> getDailyLogs({String? date}) async {
    final requestOwner = _userId;
    lastLogReadSucceeded = false;
    final d = date ?? _todayString();
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/logs?date=$d'),
        headers: _headers,
      );
      if (requestOwner != _userId || !hasToken) return [];
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] ?? []) as List;
        lastLogReadSucceeded = true;
        return data.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return LogEntry.fromMap(map['id']?.toString() ?? '', map);
        }).toList();
      }
    } catch (e) {
      debugPrint('getDailyLogs error: $e');
    }
    return [];
  }

  Future<LogEntry?> addFoodLog(LogEntry entry) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/logs'),
        headers: _headers,
        body: jsonEncode({
          if (entry.foodId.isNotEmpty) 'external_food_id': entry.foodId,
          'name': entry.name,
          'amount': entry.amount,
          'amount_unit': entry.amountUnit,
          'calories': entry.calories,
          'protein': entry.protein,
          'carbs': entry.carbs,
          'fat': entry.fat,
          'logged_at': _todayString(),
          if (entry.timestamp > 0)
            'consumed_at': DateTime.fromMillisecondsSinceEpoch(
              entry.timestamp,
            ).toUtc().toIso8601String(),
          if (entry.mealId != null) 'meal_type': entry.mealId,
          if (entry.micros.isNotEmpty) 'micros': entry.micros,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data =
            (jsonDecode(response.body) as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        return LogEntry.fromMap(data['id'].toString(), data);
      }
    } catch (e) {
      debugPrint('addFoodLog error: $e');
    }
    return null;
  }

  Future<bool> removeFoodLog(String id) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/logs/$id'),
        headers: _headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('removeFoodLog error: $e');
    }
    return false;
  }

  Future<Map<String, List<LogEntry>>> fetchFoodLogsForDates(
    List<String> dates,
  ) async {
    final result = <String, List<LogEntry>>{};
    for (final date in dates) {
      try {
        final logs = await getDailyLogs(date: date);
        if (lastLogReadSucceeded) result[date] = logs;
      } catch (_) {}
    }
    return result;
  }

  // ─── Water (API stores glasses; app UI uses ml in 250 ml steps) ──

  static const int _mlPerGlass = 250;

  Future<int> getWaterIntake({String? date}) async {
    final d = date ?? _todayString();
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/water?date=$d'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] ?? body) as Map<String, dynamic>;
        final glasses = (data['glasses'] as num?)?.toInt() ?? 0;
        return glasses * _mlPerGlass;
      }
    } catch (e) {
      debugPrint('getWaterIntake error: $e');
    }
    return 0;
  }

  Future<bool> updateWater(int amountMl) async {
    try {
      final response = await _http.put(
        Uri.parse('$baseUrl/water'),
        headers: _headers,
        body: jsonEncode({
          'log_date': _todayString(),
          'glasses': (amountMl / _mlPerGlass).round(),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('updateWater error: $e');
    }
    return false;
  }

  // ─── Weight ───────────────────────────────────────

  Future<void> recordWeight(double kg) async {
    try {
      await _http.post(
        Uri.parse('$baseUrl/weights'),
        headers: _headers,
        body: jsonEncode({'weight': kg, 'log_date': _todayString()}),
      );
    } catch (e) {
      debugPrint('recordWeight error: $e');
    }
  }

  // ─── Meal Plans ───────────────────────────────────

  Future<MealPlanData?> getMealPlan() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/meal-plan'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data == null) return null;
        if (data is! Map) return null;
        final plan = data['plan'];
        if (plan == null || plan is! Map || plan.isEmpty) return null;
        return MealPlanData.fromMap(Map<String, dynamic>.from(plan));
      }
    } catch (e) {
      debugPrint('getMealPlan error: $e');
    }
    return null;
  }

  Future<bool> saveMealPlan(MealPlanData plan) async {
    try {
      final response = await _http.put(
        Uri.parse('$baseUrl/meal-plan'),
        headers: _headers,
        body: jsonEncode({'plan': plan.toMap()}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('saveMealPlan error: $e');
    }
    return false;
  }

  Future<bool> registerFcmToken(String token) async {
    final owner = _token;
    if (!hasToken) return false;
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        }),
      );
      return owner == _token && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> unregisterFcmToken(String token) async {
    if (!hasToken) return;
    try {
      await _http.delete(
        Uri.parse('$baseUrl/fcm-token'),
        headers: _headers,
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
  }

  // ─── Subscription ─────────────────────────────────
  Future<http_pkg.Response> getBarcodeProduct(String code) => _http
      .get(
        Uri.parse(
          '$baseUrl/foods/barcode',
        ).replace(queryParameters: {'code': code}),
        headers: _headers,
      )
      .timeout(const Duration(seconds: 15));

  /// Returns the current user's premium status from the server, or `null` on error.
  /// Shape: `{ isPremium: bool, expiresAt: String?, daysLeft: int, plan: String? }`.
  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/subscription'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('getSubscription error: $e');
    }
    return null;
  }

  /// Records a successful in-app purchase to the server database.
  Future<bool> postSubscription() async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/subscription'),
        headers: _headers,
        body: '{}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ─── Notifications ────────────────────────────────

  /// Fetches notifications for the current user (their own + broadcasts).
  /// Pass [since] (ISO 8601) to only get newer ones.
  Future<List<Map<String, dynamic>>> getNotifications({String? since}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/notifications${since != null ? '?since=${Uri.encodeComponent(since)}' : ''}',
      );
      final response = await _http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] ?? []) as List;
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('getNotifications error: $e');
    }
    return [];
  }

  // ─── Helpers ──────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  UserProfile _profileFromApi(Map<String, dynamic> data) {
    final uid =
        data['user_id']?.toString() ??
        data['id']?.toString() ??
        _userId?.toString() ??
        '';
    final normalized = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (m) => m[1]!.toUpperCase(),
      );
      normalized[key] = entry.value;
    }
    // Preserve existing ku identifiers throughout food/AI code while accepting
    // the correct external Sorani locale ckb.
    if (normalized['language'] == 'ckb') normalized['language'] = 'ku';
    return UserProfile.fromMap({...normalized, 'uid': uid});
  }

  Map<String, dynamic> _profileToApi(UserProfile profile) {
    final map = profile.toMap();
    map.remove('uid');
    // Micronutrient goals remain local until the backend supports this field.
    map.remove('dailyMicroGoals');
    return map.map(
      (key, value) => MapEntry(
        key.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m[0]!.toLowerCase()}',
        ),
        value,
      ),
    );
  }
}

class _SafeHttp {
  final http_pkg.Client _client;
  final Future<void> Function(Map<String, String>?) _unauthorized;
  final Future<String?> Function(Uri) _readCache;
  final Future<void> Function(Uri, String) _saveCache;
  final bool Function(Map<String, String>?) _isCurrentSession;
  _SafeHttp(
    this._client,
    this._unauthorized,
    this._readCache,
    this._saveCache,
    this._isCurrentSession,
  );

  Future<http_pkg.Response> _check(
    Future<http_pkg.Response> pending,
    Uri url,
    Map<String, String>? headers,
  ) async {
    final response = await pending.timeout(
      Duration(seconds: url.path.endsWith('/ai/generate') ? 55 : 12),
    );
    // Credential errors during sign-in do not revoke an unrelated session.
    if (response.statusCode == 401 &&
        !RegExp(
          r'/auth/(login|verify-otp|request-otp|check-phone)$',
        ).hasMatch(url.path)) {
      await _unauthorized(headers);
    }
    return response;
  }

  void close() => _client.close();

  Future<http_pkg.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await _check(
        _client.get(url, headers: headers),
        url,
        headers,
      );
      if (!_isCurrentSession(headers)) return response;
      if (response.statusCode == 200) {
        await _saveCache(url, response.body);
      } else if (response.statusCode >= 500) {
        final cached = await _readCache(url);
        if (cached != null) return http_pkg.Response(cached, 200);
      }
      return response;
    } catch (_) {
      if (!_isCurrentSession(headers)) rethrow;
      final cached = await _readCache(url);
      if (cached != null) return http_pkg.Response(cached, 200);
      rethrow;
    }
  }

  Future<http_pkg.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _check(
      _client.post(url, headers: headers, body: body, encoding: encoding),
      url,
      headers,
    );
  }

  Future<http_pkg.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _check(
      _client.put(url, headers: headers, body: body, encoding: encoding),
      url,
      headers,
    );
  }

  Future<http_pkg.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _check(
      _client.delete(url, headers: headers, body: body, encoding: encoding),
      url,
      headers,
    );
  }
}
