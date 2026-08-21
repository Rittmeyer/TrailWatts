import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/route_suggestion.dart';
import 'package:trailwatt/models/search_context.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/terrain/route_finder.dart';

const rider = RiderProfile(weightKg: 74, ftpWatts: 210);

class FixedSource implements CyclingSegmentSource {
  final List<CyclingWay> ways;
  final SegmentFetchFailure? failure;
  const FixedSource(this.ways, {this.failure});

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async =>
      failure == null ? SegmentFetch(ways) : SegmentFetch.failed(failure);
}

/// A way of [points] samples 100 m apart heading north, climbing at
/// [gradientPct], starting at [lat] and at height [baseM].
CyclingWay climb(String id, double lat,
    {double gradientPct = 0,
    int points = 20,
    double baseM = 700,
    String? name,
    CyclingSafetyLevel safety = CyclingSafetyLevel.lowRisk,
    TrafficLevel traffic = TrafficLevel.low}) {
  const dLat = 100 / 111320;
  final pts = <LatLng>[];
  final ele = <double>[];
  for (var i = 0; i < points; i++) {
    pts.add(LatLng(lat + i * dLat, -46.63));
    ele.add(baseM + i * 100 * gradientPct / 100);
  }
  return CyclingWay(
    id: id,
    name: name,
    points: pts,
    elevationM: ele,
    safety: safety,
    traffic: traffic,
  );
}

WorkoutBlock block(
        WorkoutBlockRole role, int minutes, int zone, int min, int max) =>
    WorkoutBlock(
      zone: TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.five, index: zone),
      durationMin: minutes,
      role: role,
      target:
          WorkoutTarget(metric: ZoneMetric.power, minValue: min, maxValue: max),
    );

final plan = [
  WorkoutBlockGroup(stimuli: [block(WorkoutBlockRole.warmUp, 8, 2, 110, 140)]),
  WorkoutBlockGroup(
    stimuli: [
      block(WorkoutBlockRole.work, 4, 4, 220, 245),
      block(WorkoutBlockRole.recovery, 3, 1, 90, 120),
    ],
    repeatCount: 2,
  ),
];

const context = RouteSearchContext(
  start: RouteStart(
      lat: -23.55, lng: -46.63, source: RouteStartSource.mapSelection),
  area: SearchArea(centerLat: -23.55, centerLng: -46.63, radiusM: 8000),
);

/// Ways that meet end to end, the way OSM ways share a node, so the graph
/// has something to walk. Alternating climbs and descents.
List<CyclingWay> chainOf(int count, {double gradientPct = 5}) {
  final out = <CyclingWay>[];
  var lat = -23.55;
  var base = 700.0;
  for (var i = 0; i < count; i++) {
    final up = i.isEven;
    final way = climb('w$i', lat,
        gradientPct: up ? gradientPct : -gradientPct,
        points: 20,
        baseM: base,
        name: up ? 'Subida $i' : 'Descida $i');
    out.add(way);
    lat = way.points.last.latitude;
    base = way.elevationM!.last;
  }
  return out;
}

void main() {
  group('a search returns ranked suggestions', () {
    test('the const is gone: suggestions come from the ground fetched',
        () async {
      final finder = RouteFinder(source: FixedSource(chainOf(8)), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      expect(result.ok, isTrue);
      expect(result.suggestions, isNotEmpty);
      final best = result.suggestions.first.suggestion;
      expect(best.path, isNotEmpty);
      expect(best.distanceM, greaterThan(0));
      expect(best.matchPct, best.score.weightedScorePct,
          reason: 'spec 006: match is derived, never supplied');
    });

    test('suggestions are ordered by how well they serve the session',
        () async {
      final finder = RouteFinder(source: FixedSource(chainOf(8)), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      final scores = result.suggestions.map((s) => s.suggestion.matchPct);
      expect(scores.toList(),
          orderedEquals(scores.toList()..sort((a, b) => b - a)));
    });

    test('ways are chained into a route longer than any single road', () async {
      final finder = RouteFinder(source: FixedSource(chainOf(8)), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      final best = result.suggestions.first.suggestion;
      expect(best.id.split('+').length, greaterThan(1),
          reason: 'a session does not fit on one way, so matching way by '
              'way would score every candidate badly for the wrong reason');
      expect(best.name, contains('Subida'),
          reason: 'named after the roads it uses');
    });

    test('every segment says where it came from', () async {
      final finder = RouteFinder(source: FixedSource(chainOf(6)), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      final segment = result.suggestions.first.suggestion.path.first;
      expect(segment.sourceMetadata?.source, 'openstreetmap');
    });

    test('gradient is computed from elevation, not assumed', () async {
      final finder = RouteFinder(
          source: FixedSource(chainOf(6, gradientPct: 7)), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      final path = result.suggestions.first.suggestion.path;
      expect(path.any((s) => s.gradientPct > 5), isTrue);
      expect(path.any((s) => s.gradientPct < -5), isTrue,
          reason: 'the way back down is part of the ride');
    });

    test('a route with no elevation gets no invented gradient', () async {
      final flat = [
        CyclingWay(id: 'plain', points: [
          for (var i = 0; i < 30; i++)
            LatLng(-23.55 + i * (100 / 111320), -46.63),
        ]),
      ];
      final finder = RouteFinder(source: FixedSource(flat), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);

      final path = result.suggestions.first.suggestion.path;
      expect(path.every((s) => s.gradientPct == 0), isTrue);
      expect(path.every((s) => s.elevationM == null), isTrue);
    });
  });

  group('nothing to suggest is said, not faked', () {
    test('a source failure is reported as one', () async {
      final finder = RouteFinder(
          source:
              const FixedSource([], failure: SegmentFetchFailure.rateLimited),
          rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);
      expect(result.ok, isFalse);
      expect(result.failure, RouteSearchFailure.source);
    });

    test('no rideable ground is a different answer from a broken source',
        () async {
      final finder = RouteFinder(source: const FixedSource([]), rider: rider);
      final result = await finder.suggestionsFor(context: context, plan: plan);
      expect(result.failure, RouteSearchFailure.noGround);
    });

    test('an empty plan cannot be matched against anything', () async {
      final finder = RouteFinder(source: FixedSource(chainOf(4)), rider: rider);
      final result =
          await finder.suggestionsFor(context: context, plan: const []);
      expect(result.failure, RouteSearchFailure.noCandidate);
    });
  });

  group('performance', () {
    test('a dense area is searched in well under a second', () async {
      final finder =
          RouteFinder(source: FixedSource(chainOf(60)), rider: rider);

      final watch = Stopwatch()..start();
      final result = await finder.suggestionsFor(context: context, plan: plan);
      watch.stop();

      expect(result.ok, isTrue);
      expect(watch.elapsedMilliseconds, lessThan(1000),
          reason: 'took ${watch.elapsedMilliseconds} ms');
    });
  });
}
