enum CalibrationState { generic, calibrated, stale }

enum CalibrationQuality { rejected, low, medium, high }

class CalibrationObservation {
  final DateTime observedAt;
  final double predictedPowerWatts;
  final double actualPowerWatts;
  final double predictedSpeedKmh;
  final double observedSpeedKmh;
  final double gradientPct;
  final double systemMassKg;
  final String? surface;
  final String activitySource;
  final CalibrationQuality quality;

  const CalibrationObservation({
    required this.observedAt,
    required this.predictedPowerWatts,
    required this.actualPowerWatts,
    required this.predictedSpeedKmh,
    required this.observedSpeedKmh,
    required this.gradientPct,
    required this.systemMassKg,
    required this.activitySource,
    required this.quality,
    this.surface,
  });
}

class CalibrationProfile {
  final CalibrationState state;
  final int version;
  final double cda;
  final double crr;
  final double predictionAccuracyPct;
  final int observationCount;
  final CalibrationQuality quality;
  final DateTime updatedAt;

  const CalibrationProfile({
    required this.state,
    required this.version,
    required this.cda,
    required this.crr,
    required this.predictionAccuracyPct,
    required this.observationCount,
    required this.quality,
    required this.updatedAt,
  });
}
