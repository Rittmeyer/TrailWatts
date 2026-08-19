import 'terrain_target.dart';
import 'zone.dart';

enum TrafficLevel { low, medium, high, unknown }

enum CyclingSafetyLevel { lowRisk, moderate, highRisk, unknown }

enum RouteSegmentRole { approach, work, recovery, returnPath }

enum RouteType { loop, outAndBack, pointToPoint }

class SegmentSourceMetadata {
  final String source;
  final DateTime fetchedAt;

  const SegmentSourceMetadata({
    required this.source,
    required this.fetchedAt,
  });
}

class RouteSegment {
  final String id;
  final double lat;
  final double lng;
  final double? elevationM;
  final double gradientPct;
  final double? headingDeg;
  final SurfaceType surfaceType;
  final double? achievableSpeedKmh;
  final TrafficLevel trafficLevel;
  final CyclingSafetyLevel safetyLevel;
  final Zone? matchedZone;
  final String? matchedIntervalId;
  final RouteSegmentRole role;
  final bool isEditable;
  final int? continuousDurationSec;
  final int junctionCount;
  final int trafficLightCount;
  final SegmentSourceMetadata? sourceMetadata;

  const RouteSegment({
    required this.id,
    required this.lat,
    required this.lng,
    this.elevationM,
    this.gradientPct = 0,
    this.headingDeg,
    this.surfaceType = SurfaceType.asphalt,
    this.achievableSpeedKmh,
    this.trafficLevel = TrafficLevel.unknown,
    this.safetyLevel = CyclingSafetyLevel.unknown,
    this.matchedZone,
    this.matchedIntervalId,
    this.role = RouteSegmentRole.approach,
    this.isEditable = false,
    this.continuousDurationSec,
    this.junctionCount = 0,
    this.trafficLightCount = 0,
    this.sourceMetadata,
  }) : assert(junctionCount >= 0),
       assert(trafficLightCount >= 0);
}

class RouteScoreWeights {
  static const intensity = 0.25;
  static const duration = 0.15;
  static const sequence = 0.15;
  static const continuity = 0.15;
  static const safety = 0.10;
  static const traffic = 0.05;
  static const surface = 0.05;
  static const practicality = 0.10;

  const RouteScoreWeights._();
}

class RouteScoreBreakdown {
  final int intensityMatchPct;
  final int durationMatchPct;
  final int sequenceMatchPct;
  final int continuityScorePct;
  final int safetyScorePct;
  final int trafficScorePct;
  final int surfaceScorePct;
  final int practicalityScorePct;

  const RouteScoreBreakdown({
    required this.intensityMatchPct,
    required this.durationMatchPct,
    required this.sequenceMatchPct,
    required this.continuityScorePct,
    required this.safetyScorePct,
    required this.trafficScorePct,
    required this.surfaceScorePct,
    required this.practicalityScorePct,
  }) : assert(intensityMatchPct >= 0 && intensityMatchPct <= 100),
       assert(durationMatchPct >= 0 && durationMatchPct <= 100),
       assert(sequenceMatchPct >= 0 && sequenceMatchPct <= 100),
       assert(continuityScorePct >= 0 && continuityScorePct <= 100),
       assert(safetyScorePct >= 0 && safetyScorePct <= 100),
       assert(trafficScorePct >= 0 && trafficScorePct <= 100),
       assert(surfaceScorePct >= 0 && surfaceScorePct <= 100),
       assert(practicalityScorePct >= 0 && practicalityScorePct <= 100);

  int get weightedScorePct =>
      (intensityMatchPct * RouteScoreWeights.intensity +
              durationMatchPct * RouteScoreWeights.duration +
              sequenceMatchPct * RouteScoreWeights.sequence +
              continuityScorePct * RouteScoreWeights.continuity +
              safetyScorePct * RouteScoreWeights.safety +
              trafficScorePct * RouteScoreWeights.traffic +
              surfaceScorePct * RouteScoreWeights.surface +
              practicalityScorePct * RouteScoreWeights.practicality)
          .round();
}

class RouteSuggestion {
  final String id;
  final String name;
  final RouteType routeType;
  final int distanceM;
  final int elevationGainM;
  final int estimatedMovingTimeMin;
  final RouteScoreBreakdown score;
  final List<RouteSegment> path;

  const RouteSuggestion({
    required this.id,
    required this.name,
    required this.routeType,
    required this.distanceM,
    required this.elevationGainM,
    required this.estimatedMovingTimeMin,
    required this.score,
    this.path = const [],
  });

  int get matchPct => score.weightedScorePct;

  double get gradientAvgPct =>
      distanceM == 0 ? 0 : elevationGainM / distanceM * 100;

  bool get hasTrafficWarning => path.any(
        (segment) =>
            segment.trafficLevel == TrafficLevel.medium ||
            segment.trafficLevel == TrafficLevel.high,
      );

  bool get hasHighTrafficWarning =>
      path.any((segment) => segment.trafficLevel == TrafficLevel.high);

  bool get hasMissingSafetyData =>
      path.any((segment) => segment.safetyLevel == CyclingSafetyLevel.unknown);

  bool get hasSafetyWarning => path.any(
        (segment) => segment.safetyLevel == CyclingSafetyLevel.moderate ||
            segment.safetyLevel == CyclingSafetyLevel.highRisk,
      );
}
