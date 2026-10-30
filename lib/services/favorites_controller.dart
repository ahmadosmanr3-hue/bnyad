import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nutrify/models/favorite_template.dart';

abstract interface class FavoritesApi {
  Future<Map<String, dynamic>> readFavorites();
  Future<Map<String, dynamic>> writeFavorite(Map<String, dynamic> intent);
  Future<void> importFavorites(List<Map<String, dynamic>> favorites);
}

/// Server revisions + per-food CAS prevent stale devices resurrecting removals.
/// A single worker per canonical food coalesces taps, keeping optimistic UI fast.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this.api);
  final FavoritesApi api;
  Map<String, FavoriteTemplate> _confirmed = {};
  final Map<String, FavoriteTemplate?> _desired = {};
  final Map<String, Future<bool>> _workers = {};
  Map<String, int> _versions = {};
  int _revision = -1, _epoch = 0;
  bool remote = false, _ready = false;
  Future<bool>? _refresh;
  void Function(List<FavoriteTemplate>)? persist;
  @override
  void dispose() {
    _epoch++;
    persist = null;
    super.dispose();
  }

  List<FavoriteTemplate> get items {
    final result = {..._confirmed};
    for (final e in _desired.entries) {
      if (e.value == null) {
        result.remove(e.key);
      } else {
        result[e.key] = e.value!;
      }
    }
    return List.unmodifiable(result.values);
  }

  bool contains(String key) => _desired.containsKey(key)
      ? _desired[key] != null
      : _confirmed.containsKey(key);
  void attach({required bool server, required List<FavoriteTemplate> cached}) {
    _epoch++;
    remote = server;
    _ready = !server;
    _revision = -1;
    _confirmed = {for (final f in cached) f.foodId ?? f.id: f};
    _desired.clear();
    _workers.clear();
    _versions = {};
    _refresh = null;
    notifyListeners();
  }

  void _publish() {
    persist?.call(items);
    notifyListeners();
  }

  void _snapshot(Map<String, dynamic> result) {
    final revision = (result['revision'] as num).toInt();
    if (revision < _revision) return;
    _revision = revision;
    _versions = (result['versions'] as Map).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    );
    _confirmed = {
      for (final raw in result['data'] as List)
        raw['foodId'] as String: FavoriteTemplate.fromMap(
          Map<String, dynamic>.from(raw),
        ),
    };
    _ready = true;
    _publish();
  }

  Future<bool> refresh() {
    if (!remote) return Future.value(true);
    final epoch = _epoch;
    return _refresh ??= _read().whenComplete(() {
      if (epoch == _epoch) _refresh = null;
    });
  }

  Future<bool> _read() async {
    final epoch = _epoch;
    try {
      final data = await api.readFavorites();
      if (epoch != _epoch) return false;
      _snapshot(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> set(FavoriteTemplate template, bool active) {
    final key = template.foodId ?? template.id;
    if (!remote) {
      if (active) {
        _confirmed[key] = template;
      } else {
        _confirmed.remove(key);
      }
      _publish();
      return Future.value(true);
    }
    _desired[key] = active ? template : null;
    _publish();
    final epoch = _epoch;
    return _workers[key] ??= _flush(key, epoch).whenComplete(() {
      if (epoch == _epoch) {
        _workers.remove(key);
      }
    });
  }

  Future<bool> toggle(FavoriteTemplate template) =>
      set(template, !contains(template.foodId ?? template.id));
  Future<bool> _flush(String key, int epoch) async {
    // Yield once so rapid synchronous taps coalesce before any network write.
    await Future<void>.delayed(Duration.zero);
    if (!_ready && !await refresh()) {
      if (epoch == _epoch) {
        _desired.remove(key);
        _publish();
      }
      return false;
    }
    while (epoch == _epoch && _desired.containsKey(key)) {
      final desired = _desired[key], active = desired != null;
      if (_confirmed.containsKey(key) == active) {
        _desired.remove(key);
        _publish();
        return true;
      }
      final mutation =
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      try {
        final result = await api.writeFavorite({
          'foodId': key,
          'favorite': active,
          'expectedVersion': _versions[key] ?? 0,
          'mutationId': mutation,
          if (active) 'template': desired.toMap(),
        });
        if (epoch != _epoch) return false;
        _revision = max(_revision, (result['revision'] as num).toInt());
        final version = (result['version'] as num).toInt();
        if (version >= (_versions[key] ?? 0)) {
          _versions[key] = version;
          if (result['favorite'] == true) {
            _confirmed[key] = FavoriteTemplate.fromMap(
              Map<String, dynamic>.from(result['data']),
            );
          } else {
            _confirmed.remove(key);
          }
        }
        // Food versions are independent; ignore any older per-food response.
        if (identical(_desired[key], desired)) {
          _desired.remove(key);
        }
        _publish();
      } catch (_) {
        // One read reconciles ambiguous network commits. Never retry a failed
        // write automatically or overwrite another device after a CAS conflict.
        final reconciled = await refresh();
        if (epoch != _epoch) return false;
        final latest = _desired[key], wanted = latest != null;
        final satisfied = reconciled && _confirmed.containsKey(key) == wanted;
        _desired.remove(key);
        _publish();
        return satisfied;
      }
    }
    return epoch == _epoch;
  }
}
