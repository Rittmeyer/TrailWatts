import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/engine/workout_demand.dart';
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
  Future<SegmentFetch> waysAround(LatLng c, double r) async =>
      SegmentFetch(ways);
}

class CountingElevation implements ElevationService {
  int points = 0;
  int calls = 0;
  @override
  Future<List<double?>> elevationsFor(List<LatLng> p) async {
    points += p.length;
    calls += (p.length / OpenTopoElevationService.maxPerCall).ceil();
    return [for (var i = 0; i < p.length; i++) 700.0 + (i % 40)];
  }
}

/// A continuous road of [km], cut into 200 m ways that share their end
/// nodes, the way a highway is mapped in OSM.
List<CyclingWay> road(double km) {
  const segM = 200.0;
  final out = <CyclingWay>[];
  var lat = -23.55;
  const d = segM / 111320;
  for (var i = 0; i < (km * 1000 / segM).round(); i++) {
    out.add(CyclingWay(id: 'w$i', name: 'Rodovia', points: [
      LatLng(lat, -46.63),
      LatLng(lat + d / 2, -46.63),
      LatLng(lat + d, -46.63),
    ]));
    lat += d;
  }
  return out;
}

/// An endurance ride of [minutes] at Z2: one stimulus, one repetition.
List<WorkoutBlockGroup> endurance(int minutes) => [
      WorkoutBlockGroup(stimuli: [
        WorkoutBlock(
          zone: const TrainingZone(
              metric: ZoneMetric.power, scale: ZoneScale.five, index: 2),
          durationMin: minutes,
          role: WorkoutBlockRole.work,
          target: const WorkoutTarget(
              metric: ZoneMetric.power, minValue: 150, maxValue: 175),
        ),
      ]),
    ];

RouteSearchContext contextWithRadius(double radiusM) => RouteSearchContext(
      start: const RouteStart(
          lat: -23.55, lng: -46.63, source: RouteStartSource.mapSelection),
      area: SearchArea(centerLat: -23.55, centerLng: -46.63, radiusM: radiusM),
    );

void main() {
  group('a long route is delivered, not quietly truncated', () {
    test('200 km of ground produces a route of that order', () async {
      final demand = WorkoutDemand.of(endurance(480), rider);
      final askedKm = demand.riddenDistanceM / 1000;
      expect(askedKm, greaterThan(150), reason: '${askedKm}km asked');

      final index = TerrainIndex();
      final elevation = CountingElevation();
      final finder = RouteFinder(
        source: CachedSegmentSource(
            source: Ground(road(askedKm * 1.2)), index: index),
        rider: rider,
        elevation: TerrainElevation(service: elevation, index: index),
      );

      final result = await finder.suggestionsFor(
          context: contextWithRadius(8000), plan: endurance(480));

      expect(result.ok, isTrue);
      final deliveredKm = result.suggestions.first.suggestion.distanceM / 1000;

      // Before the hop cap followed the distance, a 200 km request came
      // back as 79.6 km and said nothing.
      expect(deliveredKm, greaterThan(askedKm * 0.85),
          reason: 'asked ${askedKm.toStringAsFixed(0)}km, '
              'got ${deliveredKm.toStringAsFixed(0)}km');
      expect(result.fallsShort, isFalse);
    });

    test('a long candidate does not become hundreds of elevation calls',
        () async {
      final index = TerrainIndex();
      final elevation = CountingElevation();
      final finder = RouteFinder(
        source: CachedSegmentSource(source: Ground(road(240)), index: index),
        rider: rider,
        elevation: TerrainElevation(service: elevation, index: index),
      );

      await finder.suggestionsFor(
          context: contextWithRadius(8000), plan: endurance(480));

      // At the nominal 80 m spacing a 200 km route is 2,500 points and 25
      // calls, each a second apart by policy.
      // The API takes 100 points a call, so the number to hold down is the
      // points. At the nominal spacing this route would be 2,500 of them.
      expect(elevation.points, lessThan(700),
          reason: '${elevation.points} points, ${elevation.calls} calls');
    });

    test('the rider is told when the terrain could not deliver', () async {
      // Only 20 km of road exists; the session wants ten times that.
      final index = TerrainIndex();
      final finder = RouteFinder(
        source: CachedSegmentSource(source: Ground(road(20)), index: index),
        rider: rider,
      );

      final result = await finder.suggestionsFor(
          context: contextWithRadius(8000), plan: endurance(480));

      expect(result.ok, isTrue);
      expect(result.fallsShort, isTrue,
          reason: 'pediu ${(result.requestedDistanceM / 1000).round()}km, '
              'entregou ${(result.deliveredDistanceM / 1000).round()}km, '
              'faltou ${result.shortfallPct}%');
      expect(result.shortfallPct, greaterThan(50));
    });

    test('the search area follows the session, not the slider', () async {
      // The rider left the radius at 8 km; the session needs far more.
      var askedRadius = 0.0;
      final source = _RecordingRadius((r) => askedRadius = r, road(240));
      final finder = RouteFinder(
        source: source,
        rider: rider,
      );

      await finder.suggestionsFor(
          context: contextWithRadius(8000), plan: endurance(480));

      expect(askedRadius, greaterThan(50000),
          reason: 'asked for ${(askedRadius / 1000).round()}km of ground');
    });
  });
}

class _RecordingRadius implements CyclingSegmentSource {
  final void Function(double) onRadius;
  final List<CyclingWay> ways;
  const _RecordingRadius(this.onRadius, this.ways);

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async {
    onRadius(radiusM);
    return SegmentFetch(ways);
  }
}
