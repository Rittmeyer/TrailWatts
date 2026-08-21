import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/search_context.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/terrain/elevation_service.dart';
import 'package:trailwatt/services/terrain/route_finder.dart';
import 'package:trailwatt/services/terrain/terrain_elevation.dart';
import 'package:trailwatt/services/terrain/terrain_index.dart';

const rider = RiderProfile(weightKg: 74, ftpWatts: 210);

class Ground implements CyclingSegmentSource {
  final List<CyclingWay> ways;
  const Ground(this.ways);
  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async =>
      SegmentFetch(ways);
}

/// Counts what the elevation API would be asked for. The public one allows
/// 100 locations a call and one call a second, so calls are seconds.
class CountingElevation implements ElevationService {
  int points = 0;
  int calls = 0;

  @override
  Future<List<double?>> elevationsFor(List<LatLng> p) async {
    points += p.length;
    calls += (p.length / OpenTopoElevationService.maxPerCall).ceil();
    return [for (var i = 0; i < p.length; i++) 700.0 + i];
  }
}

/// An urban search area: streets on a grid, nodes a few metres apart, the
/// density that made the first version take minutes.
List<CyclingWay> urbanArea({int streets = 1200, int nodes = 25}) {
  final ways = <CyclingWay>[];
  var lat = -23.55;
  for (var w = 0; w < streets; w++) {
    final points = <LatLng>[];
    for (var i = 0; i < nodes; i++) {
      points.add(LatLng(lat + i * (8 / 111320), -46.63));
    }
    ways.add(CyclingWay(id: 'w$w', name: 'Rua $w', points: points));
    lat = points.last.latitude;
  }
  return ways;
}

final plan = [
  WorkoutBlockGroup(stimuli: [
    WorkoutBlock(
      zone: const TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.five, index: 4),
      durationMin: 5,
      role: WorkoutBlockRole.work,
      target: const WorkoutTarget(
          metric: ZoneMetric.power, minValue: 220, maxValue: 245),
    ),
  ]),
];

const context = RouteSearchContext(
  start: RouteStart(
      lat: -23.55, lng: -46.63, source: RouteStartSource.mapSelection),
  area: SearchArea(centerLat: -23.55, centerLng: -46.63, radiusM: 8000),
);

void main() {
  group('what a search costs', () {
    test('elevation is asked for the candidates, not for the whole area',
        () async {
      final index = TerrainIndex();
      final elevation = CountingElevation();
      final finder = RouteFinder(
        source: CachedSegmentSource(source: Ground(urbanArea()), index: index),
        rider: rider,
        elevation: TerrainElevation(service: elevation, index: index),
      );

      final watch = Stopwatch()..start();
      final result = await finder.suggestionsFor(context: context, plan: plan);
      watch.stop();

      expect(result.ok, isTrue);

      // Every node of every street would be 30,000 points: 300 calls, and
      // at one call a second, five minutes for one search. It also spends a
      // third of the daily quota.
      expect(elevation.points, lessThan(2000),
          reason: 'asked for ${elevation.points} points');
      expect(elevation.calls, lessThan(20),
          reason: '${elevation.calls} calls is ${elevation.calls} seconds of '
              'waiting before the rider sees anything');
    });

    test('a point is never asked for twice, across candidates or searches',
        () async {
      final index = TerrainIndex();
      final elevation = CountingElevation();
      RouteFinder build() => RouteFinder(
            source:
                CachedSegmentSource(source: Ground(urbanArea()), index: index),
            rider: rider,
            elevation: TerrainElevation(service: elevation, index: index),
          );

      await build().suggestionsFor(context: context, plan: plan);
      final afterFirst = elevation.points;

      await build().suggestionsFor(context: context, plan: plan);

      expect(elevation.points, afterFirst,
          reason: 'the ground did not move between the two searches');
    });

    test('sampling thins nodes that are metres apart', () async {
      final index = TerrainIndex();
      final finder = RouteFinder(
        source: CachedSegmentSource(
            source: Ground(urbanArea(streets: 40)), index: index),
        rider: rider,
        sampleSpacingM: 80,
      );

      final result = await finder.suggestionsFor(context: context, plan: plan);
      final path = result.suggestions.first.suggestion.path;

      const distance = Distance();
      for (var i = 1; i < path.length; i++) {
        final gap = distance.as(
            LengthUnit.Meter,
            LatLng(path[i - 1].lat, path[i - 1].lng),
            LatLng(path[i].lat, path[i].lng));
        expect(gap, greaterThanOrEqualTo(60),
            reason: 'a gradient measured over a few metres is noise');
      }
    });
  });
}
