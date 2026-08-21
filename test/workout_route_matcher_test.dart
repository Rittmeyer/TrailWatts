import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/workout_route_matcher.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/route_suggestion.dart';
import 'package:trailwatt/models/terrain_target.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';

const rider = RiderProfile(weightKg: 74, ftpWatts: 210);

/// Builds a route as a list of sampled points. Each leg contributes points
/// 100 m apart carrying its gradient, which is how real sampled route data
/// arrives - a polyline with a gradient per sample.
List<RouteSegment> route(
  List<({double gradientPct, int metres})> legs, {
  SurfaceType surface = SurfaceType.asphalt,
  bool elevation = true,
  int junctionsPerLeg = 0,
}) {
  const step = 100.0;
  // 100 m of latitude, near enough for a synthetic fixture.
  const dLat = 100 / 111320;
  final out = <RouteSegment>[];
  var lat = -23.55;
  for (final leg in legs) {
    final count = (leg.metres / step).round();
    for (var i = 0; i < count; i++) {
      out.add(RouteSegment(
        id: 's${out.length}',
        lat: lat,
        lng: -46.63,
        elevationM: elevation ? 800 : null,
        gradientPct: leg.gradientPct,
        surfaceType: surface,
        junctionCount: i == 0 ? junctionsPerLeg : 0,
      ));
      lat += dLat;
    }
  }
  out.add(RouteSegment(
      id: 'end', lat: lat, lng: -46.63, elevationM: elevation ? 800 : null));
  return out;
}

WorkoutBlock block(WorkoutBlockRole role, int minutes, int zoneIndex, int minW,
        int maxW) =>
    WorkoutBlock(
      zone: TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.five, index: zoneIndex),
      durationMin: minutes,
      role: role,
      target: WorkoutTarget(
          metric: ZoneMetric.power, minValue: minW, maxValue: maxW),
    );

/// Three threshold intervals with recovery between them, plus a warm-up.
List<WorkoutTimelineStep> intervalSession() => expandWorkout([
      block(WorkoutBlockRole.warmUp, 10, 2, 110, 140),
      block(WorkoutBlockRole.work, 5, 4, 220, 245),
      block(WorkoutBlockRole.recovery, 3, 1, 90, 120),
      block(WorkoutBlockRole.work, 5, 4, 220, 245),
      block(WorkoutBlockRole.recovery, 3, 1, 90, 120),
      block(WorkoutBlockRole.work, 5, 4, 220, 245),
    ]);

void main() {
  final matcher = WorkoutRouteMatcher(rider);

  group('the whole session is placed, not one stimulus', () {
    test('every step gets ground, in order, without overlapping', () {
      final steps = intervalSession();
      final match = matcher.match(
        steps: steps,
        path: route([
          (gradientPct: 0, metres: 5000),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
        ]),
      );

      expect(match.steps.length, steps.length,
          reason: 'a step with no ground would be silently dropped');

      for (var i = 1; i < match.steps.length; i++) {
        expect(match.steps[i].fromStretch,
            greaterThanOrEqualTo(match.steps[i - 1].toStretch),
            reason: 'step $i starts before the previous one ended');
      }
      for (final s in match.steps) {
        expect(s.toStretch, greaterThan(s.fromStretch));
      }
    });

    test('all three intervals land on climbing terrain', () {
      final match = matcher.match(
        steps: intervalSession(),
        path: route([
          (gradientPct: 0, metres: 5000),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
        ]),
      );

      expect(match.intervalsRequested, 3);
      expect(match.intervalsMatched, 3);
    });

    test('it beats taking the best ground for each interval in turn', () {
      // One long climb early and two shorter ones later. Serving interval 1
      // with as much of the long climb as it can take is locally the best
      // move and leaves the session worse off - the failure the whole
      // dynamic program exists to avoid.
      final path = route([
        (gradientPct: 0, metres: 3000),
        (gradientPct: 7, metres: 4000),
        (gradientPct: -5, metres: 800),
        (gradientPct: 7, metres: 1200),
        (gradientPct: -5, metres: 800),
        (gradientPct: 7, metres: 1200),
      ]);
      final steps = intervalSession();

      final planned = matcher.match(steps: steps, path: path);
      final greedy = greedyMatch(matcher, steps, path);

      // Compared on intervals actually served - quality *and* duration -
      // because that is the thing the rider cares about. Comparing mean
      // quality alone flatters the greedy matcher, which happily takes a
      // 200 m stretch of perfect gradient and calls a 5-minute interval
      // done.
      expect(planned.intervalsMatched, greaterThan(greedy.satisfied),
          reason: 'sequence-aware served ${planned.intervalsMatched}/3, '
              'one-at-a-time served ${greedy.satisfied}/3');
    });
  });

  group('terrain semantics', () {
    test('a descent is recovery terrain, not failed terrain', () {
      final steps = expandWorkout([
        block(WorkoutBlockRole.work, 5, 4, 220, 245),
        block(WorkoutBlockRole.recovery, 4, 1, 90, 120),
      ]);
      final match = matcher.match(
        steps: steps,
        path: route([
          (gradientPct: 6, metres: 1500),
          (gradientPct: -6, metres: 3000),
        ]),
      );

      final recovery = match.steps.last;
      expect(recovery.step.role, WorkoutBlockRole.recovery);
      expect(recovery.qualityPct, greaterThan(60),
          reason: 'spec 006: descents may be valid recovery');
    });

    test('a work interval is not satisfied by a descent', () {
      final steps =
          expandWorkout([block(WorkoutBlockRole.work, 5, 4, 220, 245)]);
      final onDescent = matcher.match(
        steps: steps,
        path: route([(gradientPct: -7, metres: 4000)]),
      );
      final onClimb = matcher.match(
        steps: steps,
        path: route([(gradientPct: 6, metres: 1500)]),
      );
      expect(onDescent.steps.single.qualityPct,
          lessThan(onClimb.steps.single.qualityPct));
    });
  });

  group('missing data never reads as a perfect match', () {
    test('a route with no elevation scores below the same route with it', () {
      final steps = intervalSession();
      final legs = [
        (gradientPct: 0.0, metres: 5000),
        (gradientPct: 6.0, metres: 1600),
        (gradientPct: -4.0, metres: 1200),
        (gradientPct: 6.0, metres: 1600),
        (gradientPct: -4.0, metres: 1200),
        (gradientPct: 6.0, metres: 1600),
      ];
      final known = matcher.match(steps: steps, path: route(legs));
      final unknown =
          matcher.match(steps: steps, path: route(legs, elevation: false));
      expect(unknown.matchPct, lessThan(known.matchPct));
    });

    test('unknown traffic and safety cannot score 100', () {
      final match = matcher.match(
        steps: intervalSession(),
        path: route([
          (gradientPct: 0, metres: 5000),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
          (gradientPct: -4, metres: 1200),
          (gradientPct: 6, metres: 1600),
        ]),
      );
      expect(match.score.safetyScorePct, lessThan(100));
      expect(match.score.trafficScorePct, lessThan(100));
    });
  });

  group('it refuses rather than invents', () {
    test('a route too short for the session is unmatchable, not a low score',
        () {
      final match = matcher.match(
        steps: intervalSession(),
        path: route([(gradientPct: 0, metres: 200)]),
      );
      expect(match.steps, isEmpty);
      expect(match.matchPct, 0);
    });

    test('an empty path does not throw', () {
      expect(
          matcher.match(steps: intervalSession(), path: const []).matchPct, 0);
    });
  });

  group('performance', () {
    test('a long route with a long session stays well under a second', () {
      // 20 km sampled every 10 m, and a session of 21 steps.
      final path = [
        for (var i = 0; i < 2000; i++)
          RouteSegment(
            id: 's$i',
            lat: -23.55 + i * (10 / 111320),
            lng: -46.63,
            elevationM: 800,
            gradientPct: (i ~/ 50) % 2 == 0 ? 6 : -4,
          ),
      ];
      final steps = expandWorkout([
        block(WorkoutBlockRole.warmUp, 10, 2, 110, 140),
        for (var i = 0; i < 10; i++) ...[
          block(WorkoutBlockRole.work, 4, 4, 220, 245),
          block(WorkoutBlockRole.recovery, 2, 1, 90, 120),
        ],
      ]);

      final watch = Stopwatch()..start();
      final match = matcher.match(steps: steps, path: path);
      watch.stop();

      expect(match.steps, isNotEmpty);
      expect(watch.elapsedMilliseconds, lessThan(1000),
          reason: 'took ${watch.elapsedMilliseconds} ms');
    });
  });
}

/// What the matcher replaces: walk the steps in order and give each one the
/// stretch that looks best for it alone, from wherever the last step ended,
/// never reconsidering. Lives in the test because its only purpose is to be
/// the thing the real matcher has to beat.
({int satisfied}) greedyMatch(WorkoutRouteMatcher matcher,
    List<WorkoutTimelineStep> steps, List<RouteSegment> path) {
  var cursor = 0;
  var satisfied = 0;
  for (final step in steps) {
    var bestEnd = -1;
    MatchedStep? best;
    for (var end = cursor + 2; end < path.length && end - cursor < 200; end++) {
      final one = matcher.match(steps: [step], path: path.sublist(cursor, end));
      if (one.steps.isEmpty) continue;
      final placed = one.steps.single;
      if (best == null || placed.qualityPct > best.qualityPct) {
        best = placed;
        bestEnd = end;
      }
    }
    if (best == null) continue;
    if (best.isSatisfied) satisfied++;
    cursor = bestEnd;
  }
  return (satisfied: satisfied);
}
