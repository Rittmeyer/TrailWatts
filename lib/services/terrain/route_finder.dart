import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../engine/workout_route_matcher.dart';
import '../../models/rider_profile.dart';
import '../../models/route_suggestion.dart';
import '../../models/terrain_target.dart';
import '../../models/search_context.dart';
import '../../models/workout_block.dart';
import 'cycling_segment_source.dart';
import 'terrain_elevation.dart';

/// Why a search came back with nothing. Distinguished because the answers
/// are different: no data is something the rider can retry, no rideable
/// ground near the start is something they fix by moving the pin.
enum RouteSearchFailure { source, noGround, noCandidate }

class RouteSearchResult {
  final List<RankedSuggestion> suggestions;
  final RouteSearchFailure? failure;

  const RouteSearchResult(this.suggestions) : failure = null;
  const RouteSearchResult.failed(this.failure) : suggestions = const [];

  bool get ok => failure == null;
}

/// A suggestion plus the match it came from, so the screen can say why it
/// scored what it scored instead of showing a bare number.
class RankedSuggestion {
  final RouteSuggestion suggestion;
  final RouteMatch match;
  final SuggestionLabel label;

  const RankedSuggestion({
    required this.suggestion,
    required this.match,
    required this.label,
  });
}

/// Spec 006's alternatives. None of them says "best" on its own.
enum SuggestionLabel { bestWorkoutMatch, safest, mostClimbing, balanced }

/// Turns ground into ranked route suggestions for a workout.
///
/// The pieces are deliberately separate: the source knows where roads are,
/// the matcher knows whether a route serves a session, and this joins them
/// by building candidates and ranking what the matcher says about each.
class RouteFinder {
  final CyclingSegmentSource source;
  final RiderProfile rider;

  /// Heights, fetched for the candidates that get built rather than for the
  /// whole search area. Null leaves gradients unknown, which the matcher
  /// already handles by capping what it will claim.
  final TerrainElevation? elevation;

  /// Distance between the points a candidate is sampled at.
  ///
  /// OSM nodes can be metres apart, and a gradient measured over a few
  /// metres is noise, not terrain. Sampling also decides the cost of the
  /// search: every kept point is a point the elevation API has to answer
  /// for, at a hundred per call and a call per second.
  final double sampleSpacingM;

  RouteFinder({
    required this.source,
    required this.rider,
    this.elevation,
    this.sampleSpacingM = 80,
  });

  static const _distance = Distance();

  /// Rough pace used only to decide how long a candidate needs to be. The
  /// real speed per stretch comes from the power model inside the matcher.
  static const _nominalKmh = 24.0;

  Future<RouteSearchResult> suggestionsFor({
    required RouteSearchContext context,
    required List<WorkoutBlockGroup> plan,
    int limit = 4,
  }) async {
    final steps = expandWorkout(flattenBlockGroups(plan));
    if (steps.isEmpty) {
      return const RouteSearchResult.failed(RouteSearchFailure.noCandidate);
    }

    final start = LatLng(context.start.lat, context.start.lng);
    final fetched = await source.waysAround(start, context.area.radiusM);
    if (!fetched.ok) {
      return const RouteSearchResult.failed(RouteSearchFailure.source);
    }
    if (fetched.ways.isEmpty) {
      return const RouteSearchResult.failed(RouteSearchFailure.noGround);
    }

    final wantedM =
        workoutDurationMin(flattenBlockGroups(plan)) / 60 * _nominalKmh * 1000;

    final graph = _WayGraph(fetched.ways);
    final matcher = WorkoutRouteMatcher(rider);

    final ranked = <RankedSuggestion>[];
    final seen = <String>{};

    // One walk per preference, so the alternatives differ in what they were
    // built for rather than being the same route scored four ways.
    for (final label in SuggestionLabel.values) {
      final path = graph.walkFrom(start, wantedM / 2, _biasFor(label));
      if (path.isEmpty) continue;

      final key = path.map((w) => w.id).join('>');
      if (!seen.add(key)) continue;

      final sampled = _sample(path, outAndBack: true);
      if (sampled.points.length < 2) continue;

      // Only now, and only for the points nothing already knows.
      final missing = sampled.pointsNeedingHeight;
      if (missing.isNotEmpty) await elevation?.prefetch(missing);

      final segments = _segmentsFor(sampled);
      if (segments.length < 2) continue;

      final match = matcher.match(steps: steps, path: segments);
      ranked.add(RankedSuggestion(
        suggestion: _describe(path, segments, match, start),
        match: match,
        label: label,
      ));
    }

    if (ranked.isEmpty) {
      return const RouteSearchResult.failed(RouteSearchFailure.noCandidate);
    }

    ranked
        .sort((a, b) => b.suggestion.matchPct.compareTo(a.suggestion.matchPct));
    return RouteSearchResult(ranked.take(limit).toList());
  }

  /// What each alternative is built to prefer when choosing the next way.
  double Function(CyclingWay) _biasFor(SuggestionLabel label) =>
      switch (label) {
        SuggestionLabel.bestWorkoutMatch => (w) => 1,
        SuggestionLabel.safest => (w) => switch (w.safety) {
              CyclingSafetyLevel.lowRisk => 3.0,
              CyclingSafetyLevel.moderate => 1.0,
              CyclingSafetyLevel.highRisk => 0.15,
              CyclingSafetyLevel.unknown => 0.6,
            },
        SuggestionLabel.mostClimbing => (w) {
            if (!w.hasElevation) return 0.5;
            final heights = w.elevationM!;
            var gain = 0.0;
            for (var i = 1; i < heights.length; i++) {
              final rise = heights[i] - heights[i - 1];
              if (rise > 0) gain += rise;
            }
            return 1 + gain / 20;
          },
        SuggestionLabel.balanced => (w) => switch (w.traffic) {
              TrafficLevel.low => 2.0,
              TrafficLevel.medium => 1.0,
              TrafficLevel.high => 0.3,
              TrafficLevel.unknown => 0.8,
            },
      };

  /// The chained ways walked into one ordered path, thinned to
  /// [sampleSpacingM] and optionally doubled back so the ride returns to
  /// where it started.
  ///
  /// Thinning here rather than after: every point kept is a point the
  /// elevation API is asked about, and a point the matcher has to score.
  _Sampled _sample(List<CyclingWay> path, {required bool outAndBack}) {
    final points = <LatLng>[];
    final surfaces = <SurfaceType>[];
    final traffic = <TrafficLevel>[];
    final safety = <CyclingSafetyLevel>[];
    final heights = <double?>[];

    void append(CyclingWay way, {required bool reversed}) {
      final ordered = reversed ? way.points.reversed.toList() : way.points;
      // A source that already carries heights - a GPX import, a fixture -
      // must not be sent to the elevation API to be told what it knows.
      final known = way.hasElevation
          ? (reversed ? way.elevationM!.reversed.toList() : way.elevationM!)
          : null;
      for (var i = 0; i < ordered.length; i++) {
        final point = ordered[i];
        if (points.isNotEmpty) {
          final gap = _distance.as(LengthUnit.Meter, points.last, point);
          if (gap < sampleSpacingM) continue;
        }
        points.add(point);
        surfaces.add(way.surface);
        traffic.add(way.traffic);
        safety.add(way.safety);
        heights.add(known?[i]);
      }
    }

    for (final way in path) {
      append(way, reversed: false);
    }
    if (outAndBack) {
      for (final way in path.reversed) {
        append(way, reversed: true);
      }
    }

    return _Sampled(
      points: points,
      surfaces: surfaces,
      traffic: traffic,
      safety: safety,
      heights: heights,
    );
  }

  /// The sampled path as the matcher reads it, with gradients resolved from
  /// whatever heights are known.
  List<RouteSegment> _segmentsFor(_Sampled sampled) {
    final points = sampled.points;
    final segments = <RouteSegment>[];

    for (var i = 0; i < points.length; i++) {
      final here = points[i];
      final height = sampled.heights[i] ?? elevation?.at(here);
      double gradient = 0;
      if (i < points.length - 1) {
        final next = sampled.heights[i + 1] ?? elevation?.at(points[i + 1]);
        if (height != null && next != null) {
          final run =
              _distance.as(LengthUnit.Meter, here, points[i + 1]).toDouble();
          if (run > 1) gradient = (next - height) / run * 100;
        }
      }
      segments.add(RouteSegment(
        id: 'seg-$i',
        lat: here.latitude,
        lng: here.longitude,
        elevationM: height,
        gradientPct: gradient,
        surfaceType: sampled.surfaces[i],
        trafficLevel: sampled.traffic[i],
        safetyLevel: sampled.safety[i],
        sourceMetadata: SegmentSourceMetadata(
          source: 'openstreetmap',
          fetchedAt: DateTime.now(),
        ),
      ));
    }
    return segments;
  }

  RouteSuggestion _describe(List<CyclingWay> path, List<RouteSegment> segments,
      RouteMatch match, LatLng start) {
    var metres = 0.0;
    var gain = 0.0;
    for (var i = 0; i < segments.length - 1; i++) {
      final a = segments[i];
      final b = segments[i + 1];
      metres += _distance
          .as(LengthUnit.Meter, LatLng(a.lat, a.lng), LatLng(b.lat, b.lng))
          .toDouble();
      final rise = (b.elevationM ?? 0) - (a.elevationM ?? 0);
      if (a.elevationM != null && b.elevationM != null && rise > 0) {
        gain += rise;
      }
    }

    final minutes = match.steps.fold(0.0, (sum, s) => sum + s.durationMin);

    return RouteSuggestion(
      id: path.map((w) => w.id).join('+'),
      name: _nameFor(path),
      routeType: RouteType.outAndBack,
      distanceM: metres.round(),
      elevationGainM: gain.round(),
      estimatedMovingTimeMin: minutes.round(),
      score: match.score,
      path: segments,
    );
  }

  /// Named after the roads it uses, because "Route 3" tells the rider
  /// nothing about whether they want to ride it.
  String _nameFor(List<CyclingWay> path) {
    final names = <String>[];
    for (final way in path) {
      final name = way.name;
      if (name != null && name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
      if (names.length == 2) break;
    }
    if (names.isEmpty) return '';
    return names.join(' · ');
  }
}

/// Ways joined at shared endpoints, walked to build a route longer than any
/// single road.
///
/// A rider's session rarely fits on one way, so matching way by way would
/// score every candidate badly for a reason that has nothing to do with the
/// terrain. Endpoints are matched on rounded coordinates - OSM ways that
/// meet share a node, so their ends are identical rather than merely close.
/// One candidate's path, thinned and carrying the tags of the way each
/// point came from.
class _Sampled {
  final List<LatLng> points;
  final List<SurfaceType> surfaces;
  final List<TrafficLevel> traffic;
  final List<CyclingSafetyLevel> safety;

  /// Heights the source already knew, per kept point. Null where it did not,
  /// which is what the elevation service is asked about.
  final List<double?> heights;

  const _Sampled({
    required this.points,
    required this.surfaces,
    required this.traffic,
    required this.safety,
    required this.heights,
  });

  /// Only the points nothing already knows a height for.
  List<LatLng> get pointsNeedingHeight => [
        for (var i = 0; i < points.length; i++)
          if (heights[i] == null) points[i],
      ];
}

class _WayGraph {
  final List<CyclingWay> ways;
  final Map<String, List<CyclingWay>> _byEndpoint = {};

  _WayGraph(this.ways) {
    for (final way in ways) {
      for (final end in [way.points.first, way.points.last]) {
        _byEndpoint.putIfAbsent(_key(end), () => []).add(way);
      }
    }
  }

  static String _key(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

  static const _distance = Distance();

  static double lengthOf(CyclingWay way) {
    var metres = 0.0;
    for (var i = 0; i < way.points.length - 1; i++) {
      metres += _distance
          .as(LengthUnit.Meter, way.points[i], way.points[i + 1])
          .toDouble();
    }
    return metres;
  }

  /// Walks from the way nearest [start], taking the best-scoring unvisited
  /// neighbour each time, until the chain is long enough or runs out.
  List<CyclingWay> walkFrom(
      LatLng start, double wantedM, double Function(CyclingWay) bias) {
    if (ways.isEmpty) return const [];

    CyclingWay? first;
    var closest = double.infinity;
    for (final way in ways) {
      for (final point in way.points) {
        final d = _distance.as(LengthUnit.Meter, start, point).toDouble();
        if (d < closest) {
          closest = d;
          first = way;
        }
      }
    }
    if (first == null) return const [];

    final chain = <CyclingWay>[first];
    final used = <String>{first.id};
    var total = lengthOf(first);
    var tail = first.points.last;

    // Bounded so a dense city grid cannot walk forever; a chain this long
    // already covers any session the builder can express.
    for (var hop = 0; hop < 200 && total < wantedM; hop++) {
      CyclingWay? best;
      var bestScore = double.negativeInfinity;
      var bestReversed = false;

      for (final candidate in _byEndpoint[_key(tail)] ?? const <CyclingWay>[]) {
        if (used.contains(candidate.id)) continue;
        final reversed = _key(candidate.points.last) == _key(tail);
        final score = bias(candidate) * math.min(lengthOf(candidate), 2000);
        if (score > bestScore) {
          bestScore = score;
          best = candidate;
          bestReversed = reversed;
        }
      }

      if (best == null) break;
      chain.add(best);
      used.add(best.id);
      total += lengthOf(best);
      tail = bestReversed ? best.points.first : best.points.last;
    }

    return chain;
  }
}
