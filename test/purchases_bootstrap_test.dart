import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/services/purchases_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var configured = false;
  final methods = <String>[];
  Future<void> Function()? configuring;
  setUp(() {
    configured = false;
    configuring = null;
    methods.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      if (call.method == 'isConfigured') return configured;
      if (call.method == 'setupPurchases') {
        await configuring?.call();
        configured = true;
      }
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'missing release key never configures or calls an unsafe SDK method',
    () async {
      final sdk = PurchasesBootstrap(iosPublicKey: '', androidPublicKey: '');
      expect(await sdk.ensureConfigured(), false);
      await sdk.logOutIfConfigured();
      expect(methods, everyElement('isConfigured'));
    },
  );

  test('restored sessions share a single pending SDK configuration', () async {
    final gate = Completer<void>();
    configuring = () => gate.future;
    final sdk = PurchasesBootstrap(
      iosPublicKey: 'appl_fictional_public_sdk_key',
    );
    final results = List.generate(8, (_) => sdk.ensureConfigured());
    await Future<void>.delayed(Duration.zero);
    expect(methods.where((m) => m == 'setupPurchases').length, 1);
    var returned = false;
    results.first.then((_) => returned = true);
    expect(returned, false);
    gate.complete();
    expect(await Future.wait(results), everyElement(true));
    expect(await sdk.ensureConfigured(), true);
    expect(methods.where((m) => m == 'setupPurchases').length, 1);
  });

  test(
    'a failed configuration stays unavailable without repeated setup attempts',
    () async {
      configuring = () async => throw PlatformException(code: 'unavailable');
      final sdk = PurchasesBootstrap(
        iosPublicKey: 'appl_fictional_public_sdk_key',
      );
      expect(await sdk.ensureConfigured(), false);
      expect(await sdk.ensureConfigured(), false);
      await sdk.logOutIfConfigured();
      expect(methods.where((m) => m == 'setupPurchases').length, 1);
      expect(methods, isNot(contains('logOut')));
    },
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('$platform rejects the other platform key and secret keys', () async {
      debugDefaultTargetPlatformOverride = platform;
      final sdk = PurchasesBootstrap(
        iosPublicKey: 'goog_fictional_wrong_platform',
        androidPublicKey: 'sk_fictional_server_secret',
      );
      expect(await sdk.ensureConfigured(), false);
      expect(methods, ['isConfigured']);
    });
  }

  test('Android configures with its own public SDK key', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final sdk = PurchasesBootstrap(
      androidPublicKey: 'goog_fictional_public_sdk_key',
    );
    expect(await sdk.ensureConfigured(), true);
    await sdk.logOutIfConfigured();
    expect(methods, containsAllInOrder(['setupPurchases', 'logOut']));
  });
}
