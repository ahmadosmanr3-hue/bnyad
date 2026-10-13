import 'package:nutrify/services/api_service.dart';

/// Authentication service backed by the Laravel API.
///
/// Wraps [ApiService] OTP endpoints.
class AuthService {
  final ApiService _api;

  AuthService({required ApiService api}) : _api = api;

  bool get isLoggedIn => _api.hasToken;

  /// Whether [phoneNumber] is already registered on the server.
  Future<bool?> isPhoneRegistered(String phoneNumber) =>
      _api.checkPhoneRegistered(phoneNumber);

  /// Sends an OTP to [phoneNumber].
  /// Returns an error message on failure, `null` on success.
  Future<String?> sendPhoneOtp(String phoneNumber) async {
    return _api.requestOtp(phoneNumber);
  }

  /// Verifies OTP. For new users pass [password] and [name].
  /// On success the API token is persisted inside [ApiService].
  Future<({String? error, Map<String, dynamic>? user})> verifyPhoneOtp({
    required String phoneNumber,
    required String code,
    String? password,
    String? name,
  }) async {
    if (password != null && password.trim().isNotEmpty && password.trim().length < 6) {
      return (error: 'Password must be at least 6 characters.', user: null);
    }

    final userData = await _api.verifyOtp(
      phone: phoneNumber,
      code: code,
      password: password,
      name: name,
    );

    if (userData != null) return (error: null, user: userData);
    return (error: _api.lastError ?? 'Verification failed.', user: null);
  }

  /// Logs in using phone and password directly.
  Future<({String? error, Map<String, dynamic>? user})> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    if (password.trim().isEmpty) {
      return (error: 'Password is required.', user: null);
    }

    final userData = await _api.loginWithPassword(
      phone: phoneNumber,
      password: password,
    );

    if (userData != null) return (error: null, user: userData);
    return (error: _api.lastError ?? 'Login failed.', user: null);
  }

  Future<void> signOut() async {
    await _api.logout();
  }

  /// Permanently deletes the user account on the backend.
  Future<bool> deleteAccount() async {
    return _api.deleteAccount();
  }
}
