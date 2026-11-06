import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only stable IDs, scoped to backend and account. Never a shared guest history.
class RecentFoods extends ChangeNotifier {
  String? _owner;
  int _epoch = 0;
  bool _disposed = false;
  List<String> _ids = [];
  Future<void> _writes = Future.value();
  Future<void> _loading = Future.value();
  List<String> get ids => List.unmodifiable(_ids);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> attach(String? owner) {
    if (_owner == owner) return _loading;
    _owner = owner;
    final epoch = ++_epoch;
    _ids = [];
    _notify();
    if (owner == null) return _loading = Future.value();
    // Optional recents must never prevent authentication or health setup.
    return _loading = _read(owner, epoch).catchError((_) {});
  }

  Future<void> _read(String owner, int epoch) async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || epoch != _epoch) return;
    _ids = {
      ..._ids,
      ...?prefs.getStringList('recent_foods_v1_$owner'),
    }.take(30).toList();
    _notify();
  }

  Future<void> record(String id) async {
    final owner = _owner, epoch = _epoch;
    if (owner == null || id.isEmpty) return;
    await _loading;
    if (_disposed || epoch != _epoch) return;
    _ids = [id, ..._ids.where((value) => value != id)].take(30).toList();
    final snapshot = List<String>.from(_ids);
    _notify();
    _writes = _writes
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          if (!_disposed && epoch == _epoch) {
            await prefs.setStringList('recent_foods_v1_$owner', snapshot);
          }
        })
        .catchError((_) {});
    await _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
