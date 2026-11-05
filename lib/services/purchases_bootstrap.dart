import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/private_keys.dart' as configuration;

/// RevenueCat can terminate iOS natively if an instance method runs before
/// configure(). A Dart try/catch cannot catch that native fatalError.
class PurchasesBootstrap {
  PurchasesBootstrap({
    this.iosPublicKey = configuration.rcIosApiKey,
    this.androidPublicKey = configuration.rcAndroidApiKey,
  });

  static final instance = PurchasesBootstrap();
  final String iosPublicKey;
  final String androidPublicKey;
  Future<bool>? _initialization;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<bool> _isConfigured() async {
    if (!_supported) return false;
    try {
      // This static SDK query is safe before configure(), unlike customerInfo.
      return await Purchases.isConfigured.timeout(const Duration(seconds: 8));
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureConfigured() async {
    if (!_supported) return false;
    if (await _isConfigured()) return true;
    // Share initialization between restored-session, paywall and startup work.
    // Do not repeatedly retry a missing/broken configuration in this process.
    return _initialization ??= _configure();
  }

  Future<bool> _configure() async {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final key = ios ? iosPublicKey : androidPublicKey;
    final prefix = ios ? 'appl_' : 'goog_';
    if (!key.startsWith(prefix) || key.length < 20) return false;
    try {
      await Purchases.setLogLevel(LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration(key),
      ).timeout(const Duration(seconds: 8));
      return await _isConfigured();
    } catch (_) {
      // Purchases are unavailable, but account access and tracking still work.
      // Never print configuration values or provider errors containing them.
      return false;
    }
  }

  Future<void> logOutIfConfigured() async {
    if (!await _isConfigured()) return;
    try {
      await Purchases.logOut().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
