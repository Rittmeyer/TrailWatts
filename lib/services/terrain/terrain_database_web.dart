import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'cycling_segment_source.dart';
import 'terrain_database.dart';

/// IndexedDB: a real database in the browser, sized for the megabytes of
/// geometry and heights this caches, rather than the few hundred kilobytes
/// a key/value store allows.
///
/// Two stores that mirror how the terrain index reads: ways by their own id,
/// and, per grid cell, the ids that fall in it. A long road belongs to many
/// cells and is stored once, listed many times.
///
/// Everything is best-effort. A private window, site data blocked, a quota
/// refusal - each ends with the app running exactly as it did before there
/// was a database: slower, never broken.
class WebTerrainDatabase implements TerrainDatabase {
  static const _dbName = 'trailwatt-terrain';
  static const _version = 1;
  static const _ways = 'ways';
  static const _cellIndex = 'cell_index';
  static const _cells = 'cells';
  static const _elevation = 'elevation';

  web.IDBDatabase? _db;

  @override
  Future<void> open() async {
    if (_db != null) return;
    try {
      final request = web.window.indexedDB.open(_dbName, _version);
      request.onupgradeneeded = (web.Event _) {
        final db = request.result as web.IDBDatabase;
        for (final name in [_ways, _cellIndex, _cells, _elevation]) {
          if (!db.objectStoreNames.contains(name)) {
            db.createObjectStore(name);
          }
        }
      }.toJS;
      _db = await _await<web.IDBDatabase>(request);
    } catch (_) {
      _db = null;
    }
  }

  /// IndexedDB is event-based; this is the one place that turns a request
  /// into something the rest of the code can await.
  Future<T?> _await<T extends JSAny?>(web.IDBRequest request) {
    final completer = Completer<T?>();
    request.onsuccess = (web.Event _) {
      if (!completer.isCompleted) completer.complete(request.result as T?);
    }.toJS;
    request.onerror = (web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }.toJS;
    return completer.future;
  }

  Future<Object?> _get(String store, String key) async {
    final db = _db;
    if (db == null) return null;
    try {
      final tx = db.transaction(store.toJS, 'readonly');
      final value = await _await<JSAny?>(tx.objectStore(store).get(key.toJS));
      return value.dartify();
    } catch (_) {
      return null;
    }
  }

  Future<void> _putAll(String store, Map<String, Object?> entries) async {
    final db = _db;
    if (db == null || entries.isEmpty) return;
    try {
      final tx = db.transaction(store.toJS, 'readwrite');
      final objectStore = tx.objectStore(store);
      for (final entry in entries.entries) {
        objectStore.put(entry.value.jsify() ?? ''.toJS, entry.key.toJS);
      }
      await _done(tx);
    } catch (_) {
      // Out of quota is the likely one. The in-memory index still holds it.
    }
  }

  Future<void> _done(web.IDBTransaction tx) {
    final completer = Completer<void>();
    tx.oncomplete = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    tx.onerror = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    tx.onabort = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    return completer.future;
  }

  @override
  Future<List<CyclingWay>> waysIn(Iterable<String> cellKeys) async {
    final db = _db;
    if (db == null) return const [];

    final ids = <String>{};
    for (final cell in cellKeys) {
      final listed = await _get(_cellIndex, cell);
      if (listed is List) {
        for (final id in listed) {
          ids.add('$id');
        }
      }
    }
    if (ids.isEmpty) return const [];

    final out = <CyclingWay>[];
    for (final id in ids) {
      final raw = await _get(_ways, id);
      if (raw is! String) continue;
      try {
        final way = decodeWay(jsonDecode(raw));
        if (way != null) out.add(way);
      } catch (_) {
        // A row written by an older shape is skipped, not repaired.
      }
    }
    return out;
  }

  @override
  Future<void> putWays(Iterable<CyclingWay> ways,
      Iterable<String> Function(CyclingWay) cellsOf) async {
    if (_db == null) return;

    final rows = <String, Object?>{};
    final perCell = <String, Set<String>>{};
    for (final way in ways) {
      rows[way.id] = jsonEncode(encodeWay(way));
      for (final cell in cellsOf(way)) {
        perCell.putIfAbsent(cell, () => <String>{}).add(way.id);
      }
    }
    await _putAll(_ways, rows);

    // Merge rather than overwrite: a cell learned about in one search must
    // not lose the ways another search put there.
    final merged = <String, Object?>{};
    for (final entry in perCell.entries) {
      final existing = await _get(_cellIndex, entry.key);
      final ids = <String>{
        if (existing is List) ...existing.map((e) => '$e'),
        ...entry.value,
      };
      merged[entry.key] = ids.toList();
    }
    await _putAll(_cellIndex, merged);
  }

  @override
  Future<Set<String>> fetchedCells() async {
    final db = _db;
    if (db == null) return const {};
    try {
      final tx = db.transaction(_cells.toJS, 'readonly');
      final keys =
          await _await<JSAny?>(tx.objectStore(_cells).getAllKeys(null));
      final listed = keys.dartify();
      if (listed is! List) return const {};
      return {for (final key in listed) '$key'};
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> markCells(Iterable<String> cellKeys) =>
      _putAll(_cells, {for (final key in cellKeys) key: 1});

  @override
  Future<Map<String, double>> elevations() async {
    final db = _db;
    if (db == null) return const {};
    try {
      final tx = db.transaction(_elevation.toJS, 'readonly');
      final store = tx.objectStore(_elevation);
      final keys = (await _await<JSAny?>(store.getAllKeys(null))).dartify();
      final values = (await _await<JSAny?>(store.getAll(null))).dartify();
      if (keys is! List || values is! List) return const {};
      final out = <String, double>{};
      for (var i = 0; i < keys.length && i < values.length; i++) {
        final value = values[i];
        if (value is num) out['${keys[i]}'] = value.toDouble();
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> putElevations(Map<String, double> values) =>
      _putAll(_elevation, values);

  @override
  Future<void> clear() async {
    final db = _db;
    if (db == null) return;
    try {
      for (final name in [_ways, _cellIndex, _cells, _elevation]) {
        final tx = db.transaction(name.toJS, 'readwrite');
        tx.objectStore(name).clear();
        await _done(tx);
      }
    } catch (_) {}
  }
}

TerrainDatabase createTerrainDatabase() => WebTerrainDatabase();
