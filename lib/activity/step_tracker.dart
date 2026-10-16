import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'step_health_provider.dart';
import 'step_models.dart';

abstract class StepSettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Only settings and confirmed day identifiers are saved, never health totals,
/// raw records, distance, weight or calorie estimates. iOS storage is local to
/// this device, not synchronizable/backed up to a new device.
class LocalStepSettingsStore extends StepSettingsStore {
  final FlutterSecureStorage secure;
  LocalStepSettingsStore()
    : secure = const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
      );
  @override
  Future<String?> read(String key) async => kIsWeb
      ? (await SharedPreferences.getInstance()).getString(key)
      : secure.read(key: key);
  @override
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).setString(key, value);
    } else {
      await secure.write(key: key, value: value);
    }
  }

  @override
  Future<void> remove(String key) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).remove(key);
    } else {
      await secure.delete(key: key);
    }
  }
}

enum StepStatus {
  disconnected,
  loading,
  waitingForForeground,
  ready,
  emptyOrPrivate,
  denied,
  unavailable,
  installRequired,
  error,
}

class StepTracker extends ChangeNotifier {
  final StepHealthProvider provider;
  final StepSettingsStore store;
  final UserProfile? Function() profile;
  final double? Function()? weightKg;
  final DateTime Function() clock;

  /// Optional local-preview diagnostics. Never includes health values/profile,
  /// identifiers, keys or tokens; normal app builds leave this callback null.
  final void Function(String)? diagnostics;
  StepTracker({
    required this.provider,
    required this.store,
    required this.profile,
    this.weightKg,
    this.diagnostics,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    provider.onTimeChanged = () {
      _lastFetch = null;
      unawaited(refresh(force: true));
    };
  }
  String? _owner;
  int _epoch = 0;
  int _changeRevision = 0;
  bool _disposed = false, _foreground = true, _busy = false;
  Timer? _midnight;
  DateTime? _lastFetch, lastUpdated, _lastAccepted;
  String? _zoneSignature;
  String? _confirmedZone;
  Future<void> _writes = Future<void>.value();
  int? _goal;
  bool connected = false, automatic = true;
  Set<String> confirmedDays = {};
  List<StepDay> days = [];
  StepStatus status = StepStatus.disconnected;
  String? get owner => _owner;
  int get goal => _goal ?? initialStepGoal(profile());
  bool get simulated => provider.simulated;
  bool get busy => _busy;
  int? get todaySteps {
    final key = stepDateKey(clock());
    for (final day in days) {
      if (day.date == key) return day.steps;
    }
    return null;
  }

  WalkingEstimate? get walking {
    final key = stepDateKey(clock());
    final current = days.where((day) => day.date == key).firstOrNull;
    return estimateWalking(
      steps: current?.steps,
      weightKg: weightKg?.call() ?? profile()?.weight,
      heightCm: profile()?.height,
      distanceMeters: current?.distanceMeters,
    );
  }

  double get progress => ((todaySteps ?? 0) / goal).clamp(0.0, 1.0);
  List<StepDay> get pastDays {
    final eligible = stepWindows(clock()).skip(1).map((w) => w.date).toSet();
    return days
        .where((d) => eligible.contains(d.date) && d.steps != null)
        .toList();
  }

  int? get recommendation => !automatic || !connected
      ? null
      : suggestedStepGoal(
          days: days,
          confirmedDays: confirmedDays,
          currentGoal: goal,
          now: clock(),
          lastAccepted: _lastAccepted,
          gentle: needsGentleStepGoals(profile()),
        );
  String _key(String owner) => 'bnyad_steps_v1_${Uri.encodeComponent(owner)}';
  String _signature(DateTime now) =>
      '${stepDateKey(now)}|${now.timeZoneOffset.inMinutes}|${now.timeZoneName}';
  void _notify() {
    if (!_disposed) {
      diagnostics?.call(
        'connected=$connected status=${status.name} foreground=$_foreground busy=$_busy',
      );
      notifyListeners();
    }
  }

  /// Recalculate presentation from current local profile without changing an
  /// accepted goal, health records or any nutrition target.
  void refreshProfilePresentation() => _notify();

  Future<void> attach(String? owner) async {
    if (_disposed || owner == _owner) return;
    detach();
    if (owner == null) return;
    _owner = owner;
    final epoch = _epoch;
    try {
      final raw = await store.read(_key(owner));
      diagnostics?.call('restore: settingsPresent=${raw != null}');
      if (epoch != _epoch || _disposed) return;
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final value = data['goal'];
        if (value is int && value >= 1 && value <= 20000) _goal = value;
        connected = data['connected'] == true;
        automatic = data['automatic'] != false;
        _lastAccepted = DateTime.tryParse(data['accepted']?.toString() ?? '');
        confirmedDays = (data['confirmed'] as List? ?? [])
            .whereType<String>()
            .toSet();
        _confirmedZone = data['confirmedZone'] as String?;
        if (_confirmedZone != _zone(clock())) confirmedDays = {};
      }
      if (connected) await refresh(force: true);
    } catch (_) {
      if (epoch == _epoch) {
        connected = false;
        status = StepStatus.error;
      }
    }
    _notify();
  }

  void detach() {
    _epoch++;
    _midnight?.cancel();
    _owner = null;
    _goal = null;
    _lastAccepted = null;
    connected = false;
    automatic = true;
    confirmedDays = {};
    days = [];
    _busy = false;
    _lastFetch = null;
    lastUpdated = null;
    _zoneSignature = null;
    _confirmedZone = null;
    status = StepStatus.disconnected;
    _notify();
  }

  Future<bool> _save() async {
    final owner = _owner;
    if (owner == null) return false;
    final epoch = _epoch;
    try {
      final serialized = jsonEncode({
        'goal': _goal,
        'connected': connected,
        'automatic': automatic,
        'accepted': _lastAccepted?.toUtc().toIso8601String(),
        'confirmed': confirmedDays.toList(),
        'confirmedZone': _confirmedZone,
      });
      // Preserve invocation order when a permission result races disconnect,
      // manual edits, or switching accounts. Capture the owner and values now.
      final operation = _writes.then(
        (_) => store.write(_key(owner), serialized),
      );
      _writes = operation.catchError((Object _) {});
      await operation;
      diagnostics?.call('settings saved');
      return epoch == _epoch && !_disposed;
    } catch (_) {
      diagnostics?.call('settings save failed');
      if (epoch == _epoch) {
        status = StepStatus.error;
        _notify();
      }
      return false;
    }
  }

  /// Called ONLY after the in-app explanation is explicitly accepted.
  Future<void> connect() async {
    if (_owner == null || _busy) return;
    final epoch = _epoch;
    _busy = true;
    status = StepStatus.loading;
    _notify();
    try {
      final access = await provider.access().timeout(
        const Duration(seconds: 8),
      );
      if (epoch != _epoch || _disposed) return;
      if (access.availability != HealthAvailability.available) {
        status = access.availability == HealthAvailability.installRequired
            ? StepStatus.installRequired
            : StepStatus.unavailable;
        return;
      }
      final requested = await provider.requestAccess().timeout(
        const Duration(minutes: 2),
      );
      if (epoch != _epoch || _disposed) return;
      if (!requested) {
        status = StepStatus.denied;
        return;
      }
      connected = true;
      _goal ??= initialStepGoal(profile());
      final saved = await _save();
      if (epoch != _epoch || _disposed) return;
      if (!saved) {
        connected = false;
        return;
      }
    } catch (_) {
      if (epoch == _epoch) status = StepStatus.error;
    } finally {
      if (epoch == _epoch) {
        _busy = false;
        _notify();
      }
    }
    if (epoch == _epoch && connected) await refresh(force: true);
  }

  Future<void> disconnect() async {
    _epoch++;
    final epoch = _epoch, owner = _owner;
    _busy = false;
    connected = false;
    days = [];
    confirmedDays = {};
    lastUpdated = null;
    _lastFetch = null;
    _midnight?.cancel();
    status = StepStatus.disconnected;
    _notify();
    if (!await _save()) {
      // Fail closed on restart if an updated consent setting cannot be saved.
      if (owner != null && epoch == _epoch && owner == _owner) {
        try {
          await store.remove(_key(owner));
        } catch (_) {}
      }
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (_owner == null || !connected || _disposed) return;
    if (!_foreground && force) {
      final epoch = _epoch;
      try {
        final visible = await provider.foreground().timeout(
          const Duration(seconds: 2),
        );
        if (_disposed || epoch != _epoch) return;
        if (visible != null) _foreground = visible;
      } catch (_) {
        /* Keep the lifecycle's conservative state. */
      }
    }
    if (!_foreground) {
      // connect() previously left "Refreshing…" forever if a permission
      // sheet changed lifecycle state before its final read could begin.
      if (!_busy) {
        status = StepStatus.waitingForForeground;
        _notify();
      }
      return;
    }
    final now = clock(), epoch = _epoch;
    final zone = _signature(now);
    final changedDay = _zoneSignature != zone;
    if (changedDay) {
      // Clear old local-day/timezone values before awaiting any native read.
      days = [];
      lastUpdated = null;
      _zoneSignature = zone;
      if (_confirmedZone != null && _confirmedZone != _zone(now)) {
        confirmedDays = {};
        _confirmedZone = null;
      }
    }
    _scheduleMidnight();
    if (_busy) {
      if (changedDay) _notify();
      return;
    }
    if (!changedDay &&
        _lastFetch != null &&
        now.difference(_lastFetch!).inSeconds < (force ? 15 : 60)) {
      return;
    }
    _busy = true;
    _lastFetch = now;
    status = StepStatus.loading;
    _notify();
    try {
      final access = await provider.access().timeout(
        const Duration(seconds: 8),
      );
      if (epoch != _epoch || _disposed) return;
      if (access.availability != HealthAvailability.available) {
        days = [];
        status = access.availability == HealthAvailability.installRequired
            ? StepStatus.installRequired
            : StepStatus.unavailable;
      } else if (access.permission == HealthPermission.denied) {
        days = [];
        status = StepStatus.denied;
      } else {
        final response = await provider
            .readDays(stepWindows(now))
            .timeout(const Duration(seconds: 25));
        if (epoch != _epoch || _disposed) return;
        // A clock/timezone change during a query makes its boundaries obsolete.
        if (_signature(clock()) != zone) {
          _lastFetch = null;
          days = [];
          return;
        }
        days = response;
        lastUpdated = clock();
        status = todaySteps == null
            ? StepStatus.emptyOrPrivate
            : StepStatus.ready;
      }
    } catch (error) {
      if (epoch == _epoch) {
        days = [];
        lastUpdated = null;
        status =
            error is PlatformException &&
                error.code == 'health_permission_denied'
            ? StepStatus.denied
            : StepStatus.error;
      }
    } finally {
      if (epoch == _epoch) {
        _busy = false;
        _notify();
        if (_signature(clock()) != zone) {
          _lastFetch = null;
          unawaited(refresh(force: true));
        }
      }
    }
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    if (!_foreground || !connected) return;
    final now = clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(milliseconds: 100),
      () {
        unawaited(refresh(force: true));
      },
    );
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) {
      _midnight?.cancel();
      return;
    }
    // Permission changes in Settings must be observed even after a brief pause.
    _lastFetch = null;
    unawaited(refresh(force: true));
  }

  Future<void> setManualGoal(int value) async {
    if (value < 1 || value > 20000) throw ArgumentError.value(value, 'goal');
    final oldGoal = _goal,
        oldAutomatic = automatic,
        oldAccepted = _lastAccepted;
    _goal = value;
    automatic = false;
    _lastAccepted = clock();
    await _persistPreferences(() {
      _goal = oldGoal;
      automatic = oldAutomatic;
      _lastAccepted = oldAccepted;
    });
  }

  Future<void> setAutomatic(bool value) async {
    final old = automatic;
    automatic = value;
    await _persistPreferences(() {
      automatic = old;
    });
  }

  Future<void> confirmHistory(Set<String> dates) async {
    final oldDays = confirmedDays, oldZone = _confirmedZone;
    _confirmedZone = _zone(clock());
    confirmedDays = dates.intersection(pastDays.map((d) => d.date).toSet());
    await _persistPreferences(() {
      confirmedDays = oldDays;
      _confirmedZone = oldZone;
    });
  }

  String _zone(DateTime now) =>
      '${now.timeZoneOffset.inMinutes}|${now.timeZoneName}';

  Future<void> acceptRecommendation({int? expected}) async {
    final value = recommendation;
    if (value == null || (expected != null && expected != value)) return;
    final oldGoal = _goal, oldAccepted = _lastAccepted;
    _goal = value;
    _lastAccepted = clock();
    await _persistPreferences(() {
      _goal = oldGoal;
      _lastAccepted = oldAccepted;
    });
  }

  Future<void> _persistPreferences(VoidCallback restore) async {
    final revision = ++_changeRevision, epoch = _epoch;
    _notify();
    if (!await _save() && revision == _changeRevision && epoch == _epoch) {
      restore();
      _notify();
    }
  }

  Future<void> eraseAccount() async {
    final owner = _owner;
    detach();
    await _writes;
    if (owner != null) await store.remove(_key(owner));
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _midnight?.cancel();
    provider.dispose();
    super.dispose();
  }
}
