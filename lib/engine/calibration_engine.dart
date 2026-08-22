import 'dart:math' as math;

import '../models/calibration.dart';
import '../models/rider_profile.dart';

/// Learns a rider's CdA and Crr from what actually happened on the road.
///
/// The physics equation never changes (spec 009, requirement 3). Only the
/// two constants that are genuinely rider-and-equipment specific move, and
/// only when there is enough good data to move them.
///
/// The fit is exact rather than iterative. Steady-state power is
///
///   P = (Crr*m*g*cos0 + m*g*sin0 + 0.5*rho*CdA*v^2) * v / eta
///
/// so dividing by v and taking the gravity term across leaves
///
///   P*eta/v - m*g*sin0  =  Crr*(m*g*cos0)  +  CdA*(0.5*rho*v^2)
///
/// which is linear in the two unknowns. Two columns, closed-form least
/// squares, no starting guess to get wrong and nothing to converge.
class CalibrationEngine {
  /// Observations below this are not worth fitting to. Conservative on
  /// purpose (requirement 1): a wrong calibration is worse than none,
  /// because the rider stops being able to tell why an estimate moved.
  final int minimumObservations;

  /// How far the fitted constants may sit from anything physically
  /// sensible before the fit is thrown out rather than trusted.
  final double minCda, maxCda, minCrr, maxCrr;

  final double airDensityKgM3;

  const CalibrationEngine({
    this.minimumObservations = 8,
    this.minCda = 0.15,
    this.maxCda = 0.60,
    this.minCrr = 0.0015,
    this.maxCrr = 0.02,
    this.airDensityKgM3 = 1.225,
  });

  static const _g = 9.80665;

  /// Whether one observation is worth learning from.
  ///
  /// Requirement 2: rides with poor sensor coverage, implausible data or
  /// too much environmental uncertainty are rejected or down-weighted. A
  /// rejected observation is not a failure to report - most rides are not
  /// good calibration data, and saying so is the point.
  CalibrationQuality qualityOf(CalibrationObservation o) {
    if (o.actualPowerWatts <= 0 || o.observedSpeedKmh <= 0) {
      return CalibrationQuality.rejected;
    }
    if (o.systemMassKg <= 20 || o.systemMassKg > 250) {
      return CalibrationQuality.rejected;
    }
    // Beyond this the model's steady-state assumption stops holding: a 30%
    // wall is not ridden at a steady speed.
    if (o.gradientPct.abs() > 20) return CalibrationQuality.rejected;
    // Coasting tells us about drag but not about the rider, and a descent
    // is where wind and braking dominate.
    if (o.gradientPct < -3) return CalibrationQuality.rejected;
    // Too slow for drag to be measurable, so the fit cannot separate CdA
    // from Crr at all.
    if (o.observedSpeedKmh < 12) return CalibrationQuality.low;
    // Implausible for a human on a bicycle, so it is a sensor fault rather
    // than a ride.
    if (o.actualPowerWatts > 2000) return CalibrationQuality.rejected;
    if (o.observedSpeedKmh > 90) return CalibrationQuality.rejected;

    // Note what is deliberately *not* a reason to reject: a large gap
    // between predicted and actual power. That gap is the entire signal
    // calibration exists to learn from, and an earlier version of this gate
    // threw it away - it would have refused exactly the rides that had
    // something to teach, and left the model stuck on its guesses.

    if (o.observedSpeedKmh >= 25 && o.gradientPct.abs() <= 6) {
      // Fast and flattish is where drag dominates and CdA is observable.
      return CalibrationQuality.high;
    }
    return CalibrationQuality.medium;
  }

  static double _weightOf(CalibrationQuality q) => switch (q) {
        CalibrationQuality.high => 1.0,
        CalibrationQuality.medium => 0.6,
        CalibrationQuality.low => 0.25,
        CalibrationQuality.rejected => 0.0,
      };

  /// Fits a profile, or explains why it did not.
  ///
  /// Returns null when the data does not support a calibration. Requirement
  /// 10: nothing is invented from insufficient data, and the caller keeps
  /// whatever profile it had.
  CalibrationProfile? fit({
    required List<CalibrationObservation> observations,
    required RiderProfile rider,
    required int previousVersion,
    DateTime? now,
  }) {
    final usable = <CalibrationObservation>[];
    final weights = <double>[];
    for (final o in observations) {
      final q = qualityOf(o);
      final w = _weightOf(q);
      if (w <= 0) continue;
      usable.add(o);
      weights.add(w);
    }

    if (usable.length < minimumObservations) return null;

    // Weighted least squares on the two-column system.
    var saa = 0.0, sab = 0.0, sbb = 0.0, say = 0.0, sby = 0.0;
    for (var i = 0; i < usable.length; i++) {
      final o = usable[i];
      final w = weights[i];
      final v = o.observedSpeedKmh / 3.6;
      final angle = math.atan(o.gradientPct / 100);
      final a = o.systemMassKg * _g * math.cos(angle);
      final b = 0.5 * airDensityKgM3 * v * v;
      final y = o.actualPowerWatts * rider.drivetrainEfficiency / v -
          o.systemMassKg * _g * math.sin(angle);

      saa += w * a * a;
      sab += w * a * b;
      sbb += w * b * b;
      say += w * a * y;
      sby += w * b * y;
    }

    final determinant = saa * sbb - sab * sab;
    // A flat determinant means every observation looked the same - all one
    // speed, or all one gradient - so the two constants cannot be told
    // apart. Fitting anyway would put the whole error into one of them.
    if (determinant.abs() < 1e-9) return null;

    final crr = (say * sbb - sby * sab) / determinant;
    final cda = (sby * saa - say * sab) / determinant;

    if (crr < minCrr || crr > maxCrr) return null;
    if (cda < minCda || cda > maxCda) return null;

    return CalibrationProfile(
      state: CalibrationState.calibrated,
      version: previousVersion + 1,
      cda: cda,
      crr: crr,
      predictionAccuracyPct: _accuracyOf(usable, rider, cda, crr),
      observationCount: usable.length,
      quality: _overallQuality(usable),
      updatedAt: now ?? DateTime.now(),
    );
  }

  /// How close the fitted model lands on the observations it learned from.
  ///
  /// Requirement 8: kept apart from the constants, because it says how much
  /// to trust them and must not be mistaken for one of them.
  double _accuracyOf(List<CalibrationObservation> observations,
      RiderProfile rider, double cda, double crr) {
    var totalError = 0.0;
    for (final o in observations) {
      final v = o.observedSpeedKmh / 3.6;
      final angle = math.atan(o.gradientPct / 100);
      final predicted = (crr * o.systemMassKg * _g * math.cos(angle) +
              o.systemMassKg * _g * math.sin(angle) +
              0.5 * airDensityKgM3 * cda * v * v) *
          v /
          rider.drivetrainEfficiency;
      totalError += (predicted - o.actualPowerWatts).abs() /
          math.max(o.actualPowerWatts, 1);
    }
    final meanError = totalError / observations.length;
    return ((1 - meanError) * 100).clamp(0.0, 100.0);
  }

  CalibrationQuality _overallQuality(List<CalibrationObservation> usable) {
    final high =
        usable.where((o) => qualityOf(o) == CalibrationQuality.high).length;
    if (high >= usable.length * 0.5) return CalibrationQuality.high;
    if (high > 0 || usable.length >= minimumObservations * 2) {
      return CalibrationQuality.medium;
    }
    return CalibrationQuality.low;
  }

  /// Whether a change to the rider invalidates what was learned.
  ///
  /// Requirement 7: mass, FTP and equipment assumptions all change what the
  /// constants meant. The calibration is not thrown away - it is marked
  /// stale, so the rider can see that it stopped applying rather than
  /// finding their estimates silently different.
  bool invalidates(RiderProfile before, RiderProfile after) =>
      (before.weightKg - after.weightKg).abs() > 1.0 ||
      (before.bikeWeightKg - after.bikeWeightKg).abs() > 0.5 ||
      before.ftpWatts != after.ftpWatts ||
      before.drivetrainEfficiency != after.drivetrainEfficiency;
}
