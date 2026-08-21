import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/models/route_suggestion.dart';
import 'package:trailwatt/models/terrain_target.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/terrain/elevation_service.dart';
import 'package:trailwatt/services/terrain/terrain_database.dart';
import 'package:trailwatt/services/terrain/terrain_elevation.dart';
import 'package:trailwatt/services/terrain/terrain_index.dart';

/// A database that keeps everything in maps. Stands in for IndexedDB, which
/// only exists in a browser: what is being checked here is the contract the
/// index depends on, and that the same rows read back as they were written.
class FakeDatabase implements TerrainDatabase {
  final Map<String, String> ways = {};
  final Map<String, Set<String>> cellIndex = {};
  final Set<String> cells = {};
  final Map<String, double> heights = {};
  bool opened = false;

  @override
  Future<void> open() async => opened = true;

  @override
  Future<List<CyclingWay>> waysIn(Iterable<String> cellKeys) async {
    final ids = <String>{};
    for (final key in cellKeys) {
      ids.addAll(cellIndex[key] ?? const {});
    }
    return [
      for (final id in ids)
        if (ways[id] != null) decodeWay(jsonDecode(ways[id]!))!,
    ];
  }

  @override
  Future<void> putWays(Iterable<CyclingWay> list,
      Iterable<String> Function(CyclingWay) cellsOf) async {
    for (final way in list) {
      ways[way.id] = jsonEncode(encodeWay(way));
      for (final cell in cellsOf(way)) {
        cellIndex.putIfAbsent(cell, () => <String>{}).add(way.id);
      }
    }
  }

  @override
  Future<Set<String>> fetchedCells() async => cells;

  @override
  Future<void> markCells(Iterable<String> keys) async => cells.addAll(keys);

  @override
  Future<Map<String, double>> elevations() async => heights;

  @override
  Future<void> putElevations(Map<String, double> values) async =>
      heights.addAll(values);

  @override
  Future<void> clear() async {
    ways.clear();
    cellIndex.clear();
    cells.clear();
    heights.clear();
  }
}

class CountingSource implements CyclingSegmentSource {
  final List<CyclingWay> ways;
  int calls = 0;
  CountingSource(this.ways);

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async {
    calls++;
    return SegmentFetch(ways);
  }
}

class CountingElevation implements ElevationService {
  int points = 0;
  @override
  Future<List<double?>> elevationsFor(List<LatLng> p) async {
    points += p.length;
    return [for (var i = 0; i < p.length; i++) 700.0 + i];
  }
}

CyclingWay road(String id) => CyclingWay(
      id: id,
      name: 'Rua $id',
      points: [
        for (var i = 0; i < 12; i++) LatLng(-23.55 + i * 0.0005, -46.63),
      ],
      surface: SurfaceType.gravel,
      traffic: TrafficLevel.medium,
      safety: CyclingSafetyLevel.moderate,
    );

void main() {
  const centre = LatLng(-23.55, -46.63);

  group('a way survives being written and read', () {
    test('geometry and tags come back as they went in', () {
      final original = road('a');
      final back = decodeWay(jsonDecode(jsonEncode(encodeWay(original))))!;

      expect(back.id, original.id);
      expect(back.name, original.name);
      expect(back.points.length, original.points.length);
      expect(back.points.first.latitude,
          closeTo(original.points.first.latitude, 1e-9));
      expect(back.surface, SurfaceType.gravel);
      expect(back.traffic, TrafficLevel.medium);
      expect(back.safety, CyclingSafetyLevel.moderate);
    });

    test('an elevation list that no longer fits the geometry is dropped', () {
      final row = encodeWay(road('a'));
      row['ele'] = [700.0, 701.0]; // shorter than the 12 points
      final back = decodeWay(row)!;

      expect(back.hasElevation, isFalse,
          reason: 'lining heights up by index against the wrong points '
              'would invent gradients');
    });

    test('a row that is not a way at all is refused, not guessed', () {
      expect(decodeWay(null), isNull);
      expect(decodeWay({'id': 'x'}), isNull);
      expect(
          decodeWay({
            'id': 'x',
            'lat': [1.0],
            'lon': [1.0]
          }),
          isNull,
          reason: 'one point is not a road');
    });
  });

  group('what a previous run learned', () {
    test('the network is not asked for an area already on disk', () async {
      final db = FakeDatabase();
      final source = CountingSource([road('a'), road('b')]);

      final first = CachedSegmentSource(
          source: source, index: TerrainIndex(database: db));
      await first.waysAround(centre, 1500);
      expect(source.calls, 1);

      // A new run of the app: nothing in memory, the same database.
      final second = CachedSegmentSource(
          source: source, index: TerrainIndex(database: db));
      final result = await second.waysAround(centre, 1500);

      expect(source.calls, 1,
          reason: 'the roads were already downloaded yesterday');
      expect(result.ways.map((w) => w.id).toSet(), {'a', 'b'});
    });

    test('heights are not bought twice', () async {
      final db = FakeDatabase();
      final elevation = CountingElevation();
      final points = [
        for (var i = 0; i < 30; i++) LatLng(-23.55 + i * 0.001, -46.63),
      ];

      final first = TerrainIndex(database: db);
      await first.load();
      await TerrainElevation(service: elevation, index: first).prefetch(points);
      expect(elevation.points, 30);

      final second = TerrainIndex(database: db);
      await second.load();
      await TerrainElevation(service: elevation, index: second)
          .prefetch(points);

      expect(elevation.points, 30,
          reason: 'a thousand elevation calls a day is the real budget');
      expect(second.elevationAt(points.first), isNotNull);
    });

    test('an empty area stays remembered as empty', () async {
      final db = FakeDatabase();
      final source = CountingSource(const []);

      await CachedSegmentSource(
              source: source, index: TerrainIndex(database: db))
          .waysAround(centre, 1500);
      await CachedSegmentSource(
              source: source, index: TerrainIndex(database: db))
          .waysAround(centre, 1500);

      expect(source.calls, 1);
    });

    test('a failed fetch is not written down as an answer', () async {
      final db = FakeDatabase();
      final failing = _FailingSource();

      await CachedSegmentSource(
              source: failing, index: TerrainIndex(database: db))
          .waysAround(centre, 1500);

      expect(db.cells, isEmpty,
          reason: 'a bad minute must not become a permanent empty area');
    });
  });

  group('no database', () {
    test('everything still works, just without memory', () async {
      final source = CountingSource([road('a')]);
      final index = TerrainIndex(database: const NoTerrainDatabase());

      final result = await CachedSegmentSource(source: source, index: index)
          .waysAround(centre, 1500);

      expect(result.ok, isTrue);
      expect(result.ways, hasLength(1));
    });
  });
}

class _FailingSource implements CyclingSegmentSource {
  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async =>
      const SegmentFetch.failed(SegmentFetchFailure.rateLimited);
}
