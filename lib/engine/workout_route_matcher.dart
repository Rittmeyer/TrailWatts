import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/rider_profile.dart';
import '../models/route_suggestion.dart';
import '../models/terrain_target.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import 'cycling_power_model.dart';

/// Matches a whole workout against a route.
///
/// The point is the *whole* workout. Picking the best hill for one interval
/// and then looking for the next one is a greedy walk that routinely spends
/// the terrain a later interval needed - which is why a route can look
/// perfect for a single stimulus and be useless for the session. Here every
/// step of the expanded timeline, warm-up and recovery included, is placed
/// against the route at once, and the assignment that scores best overall
/// wins even where that means giving an individual interval worse terrain.
///
/// The placement is a dynamic program over (step, distance along the route):
/// steps take consecutive, non-overlapping stretches in order, so
/// `best[i][j]` is the best value for the first i steps using the first j
/// stretches. Candidate starts are kept inside a duration window - a step
/// wanting 8 minutes will not be served by 40 - which turns what would be a
/// quadratic scan into a sliding one and leaves the whole match linear in
/// (steps x stretches).
class WorkoutRouteMatcher {
  final RiderProfile rider;
  final CyclingPowerModel model;

  WorkoutRouteMatcher(this.rider, {CyclingPowerModel? model})
      : model = model ?? CyclingPowerModel(rider);

  /// Slowest speed treated as still riding, ~5 km/h. Below this a climb is
  /// not a hard interval, it is a walk.
  static const _minRideableMs = 1.4;

  /// Fastest speed the matcher will build a workout around, ~54 km/h. A
  /// descent that needs more than this to hit the target is not interval
  /// terrain whatever the arithmetic says.
  static const _maxWorkableMs = 15.0;

  /// How far outside the requested duration a stretch may be and still be
  /// considered. Also the DP's search window.
  static const _minDurationRatio = 0.35;
  static const _maxDurationRatio = 2.5;

  static const _distance = Distance();

  RouteMatch match({
    required List<WorkoutTimelineStep> steps,
    required List<RouteSegment> path,
  }) {
    if (steps.isEmpty || path.length < 2) {
      return RouteMatch.unmatchable(steps);
    }

    final stretches = _prepare(path);
    if (stretches.isEmpty) return RouteMatch.unmatchable(steps);

    // Per step, per stretch: how well this ground serves that instruction.
    // Precomputed so the DP never calls the power solver in its inner loop.
    final fit = [
      for (final step in steps) _fitFor(step, stretches),
    ];

    return _place(steps, stretches, fit);
  }

  /// Consecutive points become stretches carrying a length and the gradient
  /// of the ground between them.
  List<_Stretch> _prepare(List<RouteSegment> path) {
    final out = <_Stretch>[];
    for (var i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final metres = _distance
          .as(LengthUnit.Meter, LatLng(a.lat, a.lng), LatLng(b.lat, b.lng))
          .toDouble();
      if (metres <= 0) continue;
      out.add(_Stretch(
        distanceM: metres,
        gradientPct: a.gradientPct,
        surface: a.surfaceType,
        junctions: a.junctionCount + a.trafficLightCount,
        traffic: a.trafficLevel,
        safety: a.safetyLevel,
        knownElevation: a.elevationM != null,
      ));
    }
    return out;
  }

  /// Equivalent power for a step, so heart-rate steps can be matched against
  /// terrain at all. Spec 001 requires the equivalent to be exposed rather
  /// than hidden inside the calculation, which is what [MatchedStep] does.
  int targetWattsFor(WorkoutTimelineStep step) {
    if (step.target.metric == ZoneMetric.power) {
      return ((step.target.minValue + step.target.maxValue) / 2).round();
    }
    // A heart-rate zone is matched on the power table's equivalent band, at
    // the same zone index: the two tables are independent, and pretending a
    // bpm number is a watt number would be worse than saying so.
    final bounds = rider.powerZones.customLowerBoundsWatts ??
        rider.powerZones.derivedBounds(rider.ftpWatts);
    // Zone indices are 1-based and the bounds list is 0-based - the two
    // conventions meet here, and getting it wrong silently matches every
    // step against the wrong zone's watts.
    final zoneIndex = step.zone.index.clamp(1, bounds.length);
    final lower = bounds[zoneIndex - 1];
    final upper = upperBoundFrom(bounds, zoneIndex) ?? (lower * 1.15).round();
    return ((lower + upper) / 2).round();
  }

  /// How well each stretch serves one step, from 0 (useless) to 1.
  _StepFit _fitFor(WorkoutTimelineStep step, List<_Stretch> stretches) {
    final target = targetWattsFor(step).toDouble();
    final isWork = step.role == WorkoutBlockRole.work;

    final seconds = List<double>.filled(stretches.length, 0);
    final quality = List<double>.filled(stretches.length, 0);

    for (var i = 0; i < stretches.length; i++) {
      final s = stretches[i];
      final solved = model.solveSpeed(
        powerW: target,
        gradientPct: s.gradientPct,
        surface: s.surface,
      );
      final coast = model.solveSpeed(
        powerW: 0,
        gradientPct: s.gradientPct,
        surface: s.surface,
      );

      final speed = math.max(solved.speedMs, 0.1);
      seconds[i] = s.distanceM / speed;

      var q = 1.0;

      if (speed < _minRideableMs) {
        // Too steep to hold the target and keep moving.
        q *= 0.1;
      } else if (isWork && speed > _maxWorkableMs) {
        // The target is reachable only at a speed nobody does intervals at.
        q *= 0.25;
      }

      if (isWork && coast.speedMs >= solved.speedMs) {
        // Gravity is already doing more than the target asks. Fine ground
        // for recovery, useless for accumulating work.
        q *= 0.15;
      }

      if (!isWork && coast.speedMs >= solved.speedMs) {
        // A descent as recovery, which spec 006 calls out explicitly as
        // valid rather than failed terrain.
        q *= 1.0;
      }

      // Interruptions cost a work interval far more than a warm-up.
      final perKm = s.distanceM <= 0 ? 0 : s.junctions / (s.distanceM / 1000);
      q *= 1 / (1 + (isWork ? 0.35 : 0.12) * perKm);

      if (!s.knownElevation) {
        // Missing data must not read as a perfect match (spec 006).
        q *= 0.75;
      }

      quality[i] = q.clamp(0.0, 1.0);
    }

    return _StepFit(
      targetWatts: target.round(),
      seconds: _prefix(seconds),
      qualitySeconds: _prefix([
        for (var i = 0; i < seconds.length; i++) seconds[i] * quality[i],
      ]),
    );
  }

  static List<double> _prefix(List<double> values) {
    final out = List<double>.filled(values.length + 1, 0);
    for (var i = 0; i < values.length; i++) {
      out[i + 1] = out[i] + values[i];
    }
    return out;
  }

  /// The dynamic program: place every step, in order, over the route.
  RouteMatch _place(
    List<WorkoutTimelineStep> steps,
    List<_Stretch> stretches,
    List<_StepFit> fit,
  ) {
    final n = stretches.length;
    final s = steps.length;
    const negative = -1e18;

    // best[i][j]: value of placing the first i steps in the first j
    // stretches. Row 0 is "nothing placed yet", which is free anywhere -
    // the route may start before the workout does.
    var previous = List<double>.filled(n + 1, 0);
    final parent = [
      for (var i = 0; i < s; i++) List<int>.filled(n + 1, -1),
    ];

    for (var i = 0; i < s; i++) {
      final current = List<double>.filled(n + 1, negative);
      final f = fit[i];
      final wanted = steps[i].durationMin * 60.0;

      // Candidate starts stay inside the duration window, and because the
      // window's edges only move forward as j grows, each start is visited
      // once per step rather than once per (start, end) pair.
      var lo = 0;
      for (var j = 1; j <= n; j++) {
        while (lo < j &&
            f.seconds[j] - f.seconds[lo] > wanted * _maxDurationRatio) {
          lo++;
        }
        for (var k = lo; k < j; k++) {
          if (previous[k] <= negative / 2) continue;
          final span = f.seconds[j] - f.seconds[k];
          if (span < wanted * _minDurationRatio) break;
          final value = previous[k] + _value(f, k, j, wanted);
          if (value > current[j]) {
            current[j] = value;
            parent[i][j] = k;
          }
        }
      }
      previous = current;
    }

    var end = n;
    var bestValue = negative;
    for (var j = 1; j <= n; j++) {
      if (previous[j] > bestValue) {
        bestValue = previous[j];
        end = j;
      }
    }
    if (bestValue <= negative / 2) return RouteMatch.unmatchable(steps);

    final placed = <MatchedStep>[];
    var j = end;
    for (var i = s - 1; i >= 0; i--) {
      final k = parent[i][j];
      if (k < 0) return RouteMatch.unmatchable(steps);
      placed.add(_describe(steps[i], fit[i], stretches, k, j));
      j = k;
    }
    final ordered = placed.reversed.toList();

    return RouteMatch(steps: ordered, score: _score(ordered, stretches));
  }

  /// What one placement is worth: how much of the requested time this ground
  /// can actually serve. Overrunning is penalised as well as falling short -
  /// a 20-minute stretch does not satisfy an 8-minute interval twice over.
  double _value(_StepFit f, int from, int to, double wanted) {
    final span = f.seconds[to] - f.seconds[from];
    final useful = f.qualitySeconds[to] - f.qualitySeconds[from];
    final ratio = span / wanted;
    final durationFit = ratio <= 1 ? ratio : math.max(0, 2 - ratio);
    return useful / math.max(span, 1) * durationFit * wanted;
  }

  MatchedStep _describe(WorkoutTimelineStep step, _StepFit f,
      List<_Stretch> stretches, int from, int to) {
    final seconds = f.seconds[to] - f.seconds[from];
    final useful = f.qualitySeconds[to] - f.qualitySeconds[from];
    var metres = 0.0;
    var junctions = 0;
    for (var i = from; i < to; i++) {
      metres += stretches[i].distanceM;
      junctions += stretches[i].junctions;
    }
    final wanted = step.durationMin * 60.0;
    final quality = seconds <= 0 ? 0.0 : useful / seconds;
    return MatchedStep(
      step: step,
      targetWatts: f.targetWatts,
      fromStretch: from,
      toStretch: to,
      distanceM: metres,
      durationSec: seconds,
      junctions: junctions,
      qualityPct: (quality * 100).round().clamp(0, 100),
      durationFitPct:
          (math.min(seconds / wanted, 1) * 100).round().clamp(0, 100),
    );
  }

  RouteScoreBreakdown _score(List<MatchedStep> placed, List<_Stretch> all) {
    final work = placed
        .where((p) => p.step.role == WorkoutBlockRole.work)
        .toList(growable: false);
    final relevant = work.isEmpty ? placed : work;

    int mean(Iterable<int> values) {
      if (values.isEmpty) return 0;
      return (values.reduce((a, b) => a + b) / values.length).round();
    }

    final intensity = mean(relevant.map((p) => p.qualityPct));
    final duration = mean(placed.map((p) => p.durationFitPct));

    // Sequence: the DP only ever emits steps in order, so what is left to
    // report is how many of them found ground at all.
    final satisfied = placed.where((p) => p.isSatisfied).length;
    final sequence = (satisfied / placed.length * 100).round();

    final junctionsPerWorkKm = () {
      final metres = relevant.fold(0.0, (sum, p) => sum + p.distanceM);
      if (metres <= 0) return 0.0;
      return relevant.fold(0, (int sum, p) => sum + p.junctions) /
          (metres / 1000);
    }();
    final continuity = (100 / (1 + 0.5 * junctionsPerWorkKm)).round();

    // Nothing scores full marks on data the route did not carry: an unknown
    // rates 50, never 100, so a route with no safety data cannot outrank one
    // measured and found safe.
    int rated(int Function(_Stretch) rate) =>
        all.isEmpty ? 50 : mean(all.map(rate));

    final safety = rated((s) => switch (s.safety) {
          CyclingSafetyLevel.lowRisk => 100,
          CyclingSafetyLevel.moderate => 60,
          CyclingSafetyLevel.highRisk => 20,
          CyclingSafetyLevel.unknown => 50,
        });

    final traffic = rated((s) => switch (s.traffic) {
          TrafficLevel.low => 100,
          TrafficLevel.medium => 60,
          TrafficLevel.high => 25,
          TrafficLevel.unknown => 50,
        });

    final surface = rated((s) => switch (s.surface) {
          SurfaceType.asphalt => 100,
          SurfaceType.gravel => 70,
          SurfaceType.dirt => 45,
        });

    // Practicality: how much of the ride is the workout rather than getting
    // to it. A route that spends most of its length positioning is a worse
    // suggestion than one that does not, however well the intervals fit.
    final placedMetres = placed.fold(0.0, (sum, p) => sum + p.distanceM);
    final routeMetres = all.fold(0.0, (sum, s) => sum + s.distanceM);
    final practicality = routeMetres <= 0
        ? 0
        : (placedMetres / routeMetres * 100).round().clamp(0, 100);

    return RouteScoreBreakdown(
      intensityMatchPct: intensity,
      durationMatchPct: duration,
      sequenceMatchPct: sequence,
      continuityScorePct: continuity.clamp(0, 100),
      safetyScorePct: safety,
      trafficScorePct: traffic,
      surfaceScorePct: surface,
      practicalityScorePct: practicality,
    );
  }
}

class _Stretch {
  final double distanceM;
  final double gradientPct;
  final SurfaceType surface;
  final int junctions;
  final TrafficLevel traffic;
  final CyclingSafetyLevel safety;
  final bool knownElevation;

  const _Stretch({
    required this.distanceM,
    required this.gradientPct,
    required this.surface,
    required this.junctions,
    required this.traffic,
    required this.safety,
    required this.knownElevation,
  });
}

class _StepFit {
  final int targetWatts;
  final List<double> seconds;
  final List<double> qualitySeconds;

  const _StepFit({
    required this.targetWatts,
    required this.seconds,
    required this.qualitySeconds,
  });
}

/// Where one step of the workout ended up on the route.
class MatchedStep {
  final WorkoutTimelineStep step;

  /// The watts this step was matched at. For a heart-rate step this is the
  /// equivalent the matcher used, which spec 001 requires to be visible.
  final int targetWatts;

  final int fromStretch;
  final int toStretch;
  final double distanceM;
  final double durationSec;
  final int junctions;

  /// How well the ground serves the instruction, 0-100.
  final int qualityPct;

  /// How much of the requested time this ground provides, 0-100.
  final int durationFitPct;

  const MatchedStep({
    required this.step,
    required this.targetWatts,
    required this.fromStretch,
    required this.toStretch,
    required this.distanceM,
    required this.durationSec,
    required this.junctions,
    required this.qualityPct,
    required this.durationFitPct,
  });

  /// Placed on ground that can actually carry it. The thresholds are the
  /// line between "matched" and "the best we could do", and the UI must be
  /// able to say which.
  bool get isSatisfied => qualityPct >= 60 && durationFitPct >= 80;

  double get durationMin => durationSec / 60;
}

class RouteMatch {
  final List<MatchedStep> steps;
  final RouteScoreBreakdown score;

  const RouteMatch({required this.steps, required this.score});

  /// No placement exists - too few points, or no stretch long enough for the
  /// first step. Scored zero rather than omitted, so a caller ranking
  /// candidates sees it lose instead of not seeing it.
  factory RouteMatch.unmatchable(List<WorkoutTimelineStep> steps) =>
      const RouteMatch(
        steps: [],
        score: RouteScoreBreakdown(
          intensityMatchPct: 0,
          durationMatchPct: 0,
          sequenceMatchPct: 0,
          continuityScorePct: 0,
          safetyScorePct: 0,
          trafficScorePct: 0,
          surfaceScorePct: 0,
          practicalityScorePct: 0,
        ),
      );

  int get matchPct => score.weightedScorePct;

  Iterable<MatchedStep> get intervals =>
      steps.where((s) => s.step.role == WorkoutBlockRole.work);

  int get intervalsMatched => intervals.where((s) => s.isSatisfied).length;

  int get intervalsRequested => intervals.length;
}
