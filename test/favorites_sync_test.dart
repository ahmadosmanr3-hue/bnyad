import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/favorite_template.dart';
import 'package:nutrify/services/favorites_controller.dart';

final food = FavoriteTemplate(
  id: 'milk',
  foodId: 'milk',
  name: 'Milk',
  amount: 250,
  amountUnit: 'ml',
  calories: 155,
  protein: 8,
  carbs: 12,
  fat: 8,
);

class Server implements FavoritesApi {
  final Map<String, dynamic> rows = {};
  final Map<String, int> versions = {};
  int revision = 0, writes = 0;
  bool failWrite = false, failRead = false, commitThenFail = false;
  Completer<void>? hold;
  @override
  Future<Map<String, dynamic>> readFavorites() async {
    if (failRead) throw StateError('offline');
    return {
      'revision': revision,
      'data': rows.values.toList(),
      'versions': {...versions},
    };
  }

  @override
  Future<void> importFavorites(List<Map<String, dynamic>> favorites) async {}
  @override
  Future<Map<String, dynamic>> writeFavorite(Map<String, dynamic> i) async {
    writes++;
    await hold?.future;
    if (failWrite) throw StateError('offline');
    final key = i['foodId'] as String;
    if (i['expectedVersion'] != (versions[key] ?? 0)) {
      throw StateError('conflict');
    }
    versions[key] = (versions[key] ?? 0) + 1;
    revision++;
    if (i['favorite'] == true) {
      rows[key] = i['template'];
    } else {
      rows.remove(key);
    }
    if (commitThenFail) throw StateError('response lost');
    return {
      'version': versions[key],
      'revision': revision,
      'favorite': i['favorite'],
      'data': rows[key],
    };
  }
}

FavoritesController client(Server s) =>
    FavoritesController(s)..attach(server: true, cached: []);
void main() {
  test(
    'one tap fills immediately, second removes; one row and restart persistence',
    () async {
      final s = Server(), c = client(Server());
      c.dispose();
      final a = client(s);
      final first = a.toggle(food);
      expect(a.contains('milk'), true);
      await first;
      expect(s.rows.length, 1);
      final b = client(s);
      await b.refresh();
      expect(b.items.single.amountUnit, 'ml');
      final remove = a.toggle(food);
      expect(a.contains('milk'), false);
      expect(await remove, true);
      await b.refresh();
      expect(b.items, isEmpty);
    },
  );
  test(
    'ten rapid taps coalesce to final unselected state with no duplicates',
    () async {
      final s = Server(), a = client(s);
      await a.refresh();
      final changes = [for (var n = 0; n < 10; n++) a.toggle(food)];
      await Future.wait(changes);
      expect(a.items, isEmpty);
      expect(s.rows, isEmpty);
      expect(s.writes, 0);
    },
  );
  test('rapid taps during an in-flight write preserve final intent', () async {
    final s = Server()..hold = Completer<void>(), a = client(s);
    await a.refresh();
    final operation = a.toggle(food);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    a.toggle(food);
    a.toggle(food);
    a.toggle(food);
    expect(a.contains('milk'), false);
    s.hold!.complete();
    expect(await operation, true);
    expect(s.rows, isEmpty);
    expect(s.writes, 2);
  });
  test(
    'failed write rolls back, lost success reconciles, never retries failed operation',
    () async {
      final s = Server(), a = client(s);
      await a.refresh();
      s.failWrite = true;
      expect(await a.toggle(food), false);
      expect(a.items, isEmpty);
      expect(s.writes, 1);
      s.failWrite = false;
      s.commitThenFail = true;
      expect(await a.toggle(food), true);
      expect(a.items.length, 1);
      expect(s.writes, 2);
    },
  );
  test('two devices reconcile removals and reject stale overwrite', () async {
    final s = Server(), a = client(s), b = client(s);
    await a.refresh();
    await b.refresh();
    await a.toggle(food);
    expect(await b.toggle(food), true);
    expect(s.rows.length, 1);
    await a.toggle(food);
    expect(await b.toggle(food), true);
    await a.refresh();
    expect(a.items, isEmpty);
    expect(b.items, isEmpty);
  });
  test(
    'account switch discards delayed old response and visible state',
    () async {
      final s = Server()..hold = Completer<void>(), a = client(s);
      await a.refresh();
      final operation = a.toggle(food);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      a.attach(server: true, cached: []);
      s.hold!.complete();
      expect(await operation, false);
      expect(a.items, isEmpty);
    },
  );
}
