enum SurfaceType { asphalt, gravel, dirt }

enum ModelState { generic, calibrated }

enum ModelConfidence { low, medium, high }

class TerrainOption {
  final double gradientPct;
  final double speedKmh;
  final int durationMin;
  final int distanceM;
  final int predictedPowerWatts;
  final bool feasible;
  final ModelConfidence confidence;
  final String? explanation;

  const TerrainOption({
    required this.gradientPct,
    required this.speedKmh,
    required this.durationMin,
    required this.distanceM,
    required this.predictedPowerWatts,
    required this.feasible,
    required this.confidence,
    this.explanation,
  }) : assert(durationMin > 0);
}

class TerrainTargetResult {
  final List<TerrainOption> options;
  final ModelState modelState;
  final ModelConfidence confidence;
  final int? equivalentPowerWatts;

  const TerrainTargetResult({
    required this.options,
    required this.modelState,
    required this.confidence,
    this.equivalentPowerWatts,
  });
}

class SegmentEvaluationRequest {
  final double gradientPct;
  final SurfaceType surfaceType;
  final double achievableSpeedKmh;
  final double? windSpeedKmh;
  final double? windDirectionDeg;
  final double? riderHeadingDeg;

  const SegmentEvaluationRequest({
    required this.gradientPct,
    required this.surfaceType,
    required this.achievableSpeedKmh,
    this.windSpeedKmh,
    this.windDirectionDeg,
    this.riderHeadingDeg,
  });
}

class SegmentEvaluationResult {
  final int predictedPowerWatts;
  final String? predictedHrZone;
  final ModelState modelState;
  final ModelConfidence confidence;

  const SegmentEvaluationResult({
    required this.predictedPowerWatts,
    this.predictedHrZone,
    this.modelState = ModelState.generic,
    this.confidence = ModelConfidence.medium,
  });
}

typedef TerrainTarget = TerrainTargetResult;
