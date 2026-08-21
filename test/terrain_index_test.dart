import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/terrain/elevation_service.dart';
import 'package:trailwatt/services/terrain/terrain_elevation.dart';
import 'package:trailwatt/services/terrain/terrain_index.dart';

class RecordingSource implements CyclingSegmentSource {
  final List<CyclingWay> ways;
  final SegmentFetchFailure? failure;
  int calls = 0;

  RecordingSource(this.ways, {this.failure});

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async {
    calls++;
    return failure == null ? SegmentFetch(ways) : SegmentFetch.failed(failure);
  }
}

class CountingElevation implements ElevationService {
  int pointsAsked = 0;
  int calls = 0;

  @override
  Future<List<double?>> elevationsFor(List<LatLng> points) async {
    calls++;
    pointsAsked += points.length;
    // A hill: height rises with latitude.
    return [for (final p in points) 700 + (p.latitude + 24) * 1000];
  }
}

CyclingWay wayAt(String id, double lat, double lon, {int points = 4}) =>
    CyclingWay(
      id: id,
      points: [
        for (var i = 0; i < points; i++) LatLng(lat + i * 0.0005, lon),
      ],
    );

void main() {
  const centre = LatLng(-23.55, -46.63);

  group('finding ground near a point', () {
    test('only ways inside the radius come back', () {
      final index = TerrainIndex()
        ..add(wayAt('near', -23.551, -46.63))
        ..add(wayAt('far', -23.90, -46.63));

      final found = index.near(centre, 2000);
      expect(found.map((w) => w.id), ['near']);
    });

    test('a long way is found from anywhere along it', () {
      final long = CyclingWay(id: 'long', points: [
        for (var i = 0; i < 200; i++) LatLng(-23.60 + i * 0.001, -46.63),
      ]);
      final index = TerrainIndex()..add(long);

      // Its far end, nowhere near where the way starts.
      expect(index.near(const LatLng(-23.45, -46.63), 500).map((w) => w.id),
          ['long']);
    });

    test('the lookup does not walk everything ever stored', () {
      final index = TerrainIndex();
      // A country's worth of roads, spread over degrees.
      for (var i = 0; i < 20000; i++) {
        index.add(wayAt(
            'w$i', -24 + (i % 1000) * 0.002, -47 + (i ~/ 1000) * 0.002,
            points: 2));
      }

      final watch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        index.near(centre, 3000);
      }
      watch.stop();

      expect(watch.elapsedMilliseconds, lessThan(500),
          reason: '50 lookups over ${index.wayCount} ways took '
              '${watch.elapsedMilliseconds} ms');
    });

    test('the store is bounded rather than growing forever', () {
      final index = TerrainIndex(maxWays: 500);
      for (var i = 0; i < 3000; i++) {
        index.add(wayAt('w$i', -24 + i * 0.01, -47, points: 2));
      }
      expect(index.wayCount, lessThanOrEqualTo(500));
    });
  });

  group('an area is fetched once', () {
    test('a second search over the same ground makes no call', () async {
      final source = RecordingSource([wayAt('a', -23.551, -46.63)]);
      final cached = CachedSegmentSource(source: source, index: TerrainIndex());

      await cached.waysAround(centre, 2000);
      await cached.waysAround(centre, 2000);
      await cached.waysAround(const LatLng(-23.5505, -46.6305), 1500);

      expect(source.calls, 1,
          reason: 'terrain does not change between two searches');
    });

    test('an empty area is remembered as empty, not asked again', () async {
      final source = RecordingSource(const []);
      final cached = CachedSegmentSource(source: source, index: TerrainIndex());

      await cached.waysAround(centre, 2000);
      final second = await cached.waysAround(centre, 2000);

      expect(source.calls, 1);
      expect(second.ok, isTrue);
      expect(second.ways, isEmpty);
    });

    test('a failed fetch is not cached as an empty area', () async {
      final source =
          RecordingSource(const [], failure: SegmentFetchFailure.rateLimited);
      final cached = CachedSegmentSource(source: source, index: TerrainIndex());

      final first = await cached.waysAround(centre, 2000);
      expect(first.ok, isFalse);

      await cached.waysAround(centre, 2000);
      expect(source.calls, 2,
          reason: 'caching a failure would turn a bad minute into a bad day');
    });
  });

  group('elevation is fetched once per point', () {
    test('a second search asks for nothing it already knows', () async {
      final index = TerrainIndex();
      final elevation = CountingElevation();
      final terrain = TerrainElevation(service: elevation, index: index);

      final points = [
        for (var i = 0; i < 40; i++) LatLng(-23.55 + i * 0.001, -46.63),
      ];

      await terrain.prefetch(points);
      expect(elevation.pointsAsked, 40);
      expect(terrain.at(points.first), isNotNull);

      await terrain.prefetch(points);
      expect(elevation.calls, 1,
          reason: 'the ground did not move between the two searches');
    });

    test('a point repeated along the route is asked for once', () async {
      final index = TerrainIndex();
      final elevation = CountingElevation();
      final terrain = TerrainElevation(service: elevation, index: index);

      const point = LatLng(-23.55, -46.63);
      // What an out-and-back does: every point appears twice.
      await terrain.prefetch([point, point, point]);

      expect(elevation.pointsAsked, 1);
    });

    test('a point the DEM does not cover stays unknown', () async {
      final index = TerrainIndex();
      final terrain =
          TerrainElevation(service: _PartialElevation(), index: index);

      const a = LatLng(-23.55, -46.63);
      const b = LatLng(-23.56, -46.63);
      await terrain.prefetch([a, b]);

      expect(terrain.at(a), isNotNull);
      expect(terrain.at(b), isNull,
          reason: 'a height nobody measured must not become a gradient');
    });
  });
}

/// Answers for the first point only, as a DEM does at the edge of coverage.
class _PartialElevation implements ElevationService {
  @override
  Future<List<double?>> elevationsFor(List<LatLng> points) async =>
      [for (var i = 0; i < points.length; i++) i == 0 ? 700.0 : null];
}
