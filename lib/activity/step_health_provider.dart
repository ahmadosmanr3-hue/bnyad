import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'step_models.dart';

abstract class StepHealthProvider {
  bool get simulated => false;
  VoidCallback? onTimeChanged;
  Future<HealthAccess> access();
  Future<bool> requestAccess();
  Future<List<StepDay>> readDays(List<StepWindow> windows);
  Future<void> openSettings();
  void dispose() {}
}

class NativeStepHealthProvider extends StepHealthProvider {
  final MethodChannel channel;
  NativeStepHealthProvider({
    this.channel = const MethodChannel('com.bnyad.app/steps'),
  }) {
    if (supported) {
      channel.setMethodCallHandler((call) async {
        if (call.method == 'timeChanged') onTimeChanged?.call();
      });
    }
  }
  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.iOS,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform);

  @override
  Future<HealthAccess> access() async {
    if (!supported) {
      return const HealthAccess(
        HealthAvailability.unavailable,
        HealthPermission.unknown,
      );
    }
    final raw = await channel.invokeMapMethod<Object?, Object?>('access');
    return HealthAccess.fromMap(raw ?? {});
  }

  @override
  Future<bool> requestAccess() async =>
      supported && await channel.invokeMethod<bool>('requestAccess') == true;

  @override
  Future<List<StepDay>> readDays(List<StepWindow> windows) async {
    if (!supported) return [];
    final raw = await channel.invokeListMethod<Object?>('readDays', {
      'windows': windows.map((w) => w.toMap()).toList(),
    });
    final allowed = windows.map((w) => w.date).toSet();
    final days = <String, StepDay>{};
    for (final item in raw ?? []) {
      if (item is! Map ||
          item['date'] is! String ||
          !allowed.contains(item['date'])) {
        throw const FormatException('Invalid health aggregate');
      }
      final count = item['steps'], meters = item['distanceMeters'];
      if (count != null &&
          (count is! num ||
              !count.isFinite ||
              count < 0 ||
              count > 100000 ||
              count != count.roundToDouble())) {
        throw const FormatException('Invalid step count');
      }
      if (meters != null &&
          (meters is! num || !meters.isFinite || meters < 0)) {
        throw const FormatException('Invalid distance');
      }
      if (days.containsKey(item['date'])) {
        throw const FormatException('Duplicate day');
      }
      days[item['date']] = StepDay(
        item['date'],
        (count as num?)?.toInt(),
        distanceMeters: (meters as num?)?.toDouble(),
      );
    }
    return days.values.toList();
  }

  @override
  Future<void> openSettings() async {
    if (supported) await channel.invokeMethod<void>('openSettings');
  }

  @override
  void dispose() {
    if (supported) channel.setMethodCallHandler(null);
  }
}
