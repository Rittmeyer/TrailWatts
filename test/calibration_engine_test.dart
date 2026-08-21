import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/calibration_engine.dart';
import 'package:trailwatt/engine/cycling_power_model.dart';
import 'package:trailwatt/models/calibration.dart';
import 'package:trailwatt/models/rider_profile.dart';

const engine = CalibrationEngine();

/// A rider whose real constants we know, so the fit can be checked against
/// the truth instead of against itself.
const trueCda = 0.281;
const trueCrr = 0.0056;
const truth =
    RiderProfile(weightKg: 72, ftpWatts: 250, cda: trueCda, crr: trueCrr);

/// One ride at [speedKmh] on [gradientPct], with the power that rider would
/// actually have had to produce.
CalibrationObservation observed(double speedKmh, double gradientPct,
    {double noise = 0, double predicted = 0}) {
  const model = CyclingPowerModel(truth);
  final actual =
      model.powerFor(speedMs: speedKmh / 3.6, gradientPct: gradientPct);
  return CalibrationObservation(
    observedAt: DateTime(2026, 5, 1),
    predictedPowerWatts: predicted > 0 ? predicted : actual,
    actualPowerWatts: actual * (1 + noise),
    predictedSpeedKmh: speedKmh,
    observedSpeedKmh: speedKmh,
    gradientPct: gradientPct,
    systemMassKg: truth.systemMassKg,
    activitySource: 'strava',
    quality: CalibrationQuality.high,
  );
}

/// A spread of rides: fast and flat is where drag shows, slow and steep is
/// where rolling resistance does. Without both the two cannot be separated.
List<CalibrationObservation> spread({double noise = 0}) => [
      for (final speed in [22.0, 26.0, 30.0, 34.0, 38.0])
        observed(speed, 0, noise: noise),
      for (final speed in [14.0, 16.0, 18.0]) observed(speed, 4, noise: noise),
      for (final speed in [13.0, 15.0]) observed(speed, 6, noise: noise),
    ];

void main() {
  group('the fit recovers constants it was never told', () {
    test('clean observations return the rider real constants', () {
      final profile =
          engine.fit(observations: spread(), rider: truth, previousVersion: 0);

      expect(profile, isNotNull);
      expect(profile!.cda, closeTo(trueCda, 0.005),
          reason: 'fitted ${profile.cda}, real $trueCda');
      expect(profile.crr, closeTo(trueCrr, 0.0005),
          reason: 'fitted ${profile.crr}, real $trueCrr');
      expect(profile.state, CalibrationState.calibrated);
      expect(profile.version, 1);
    });

    test('noisy observations still land close', () {
      final rnd = math.Random(4);
      final noisy = [
        for (final o in spread())
          CalibrationObservation(
            observedAt: o.observedAt,
            predictedPowerWatts: o.predictedPowerWatts,
            actualPowerWatts:
                o.actualPowerWatts * (1 + (rnd.nextDouble() - 0.5) * 0.06),
            predictedSpeedKmh: o.predictedSpeedKmh,
            observedSpeedKmh: o.observedSpeedKmh,
            gradientPct: o.gradientPct,
            systemMassKg: o.systemMassKg,
            activitySource: o.activitySource,
            quality: o.quality,
          ),
      ];

      final profile =
          engine.fit(observations: noisy, rider: truth, previousVersion: 3);

      expect(profile!.cda, closeTo(trueCda, 0.04));
      expect(profile.version, 4, reason: 'calibration is versioned');
      expect(profile.predictionAccuracyPct, greaterThan(90));
    });

    test('accuracy is reported apart from the constants', () {
      final profile =
          engine.fit(observations: spread(), rider: truth, previousVersion: 0);
      // Fitted on clean data, so it should land on it almost exactly.
      expect(profile!.predictionAccuracyPct, greaterThan(98));
    });
  });

  group('it refuses rather than inventing', () {
    test('too few observations produce nothing', () {
      final profile = engine.fit(
          observations: spread().take(3).toList(),
          rider: truth,
          previousVersion: 0);
      expect(profile, isNull, reason: 'a wrong calibration is worse than none');
    });

    test('observations that all look alike cannot separate the two', () {
      // Ten rides at the same speed on the same gradient: the two columns
      // are proportional and the system has no unique answer.
      final same = [for (var i = 0; i < 10; i++) observed(28, 0)];
      expect(engine.fit(observations: same, rider: truth, previousVersion: 0),
          isNull);
    });

    test('a fit landing outside physical sense is thrown away', () {
      // Power far too low for the speeds: the maths would answer with a
      // CdA no bicycle has.
      final wrong = [
        for (final o in spread())
          CalibrationObservation(
            observedAt: o.observedAt,
            predictedPowerWatts: o.predictedPowerWatts,
            actualPowerWatts: o.actualPowerWatts * 0.25,
            predictedSpeedKmh: o.predictedSpeedKmh,
            observedSpeedKmh: o.observedSpeedKmh,
            gradientPct: o.gradientPct,
            systemMassKg: o.systemMassKg,
            activitySource: o.activitySource,
            quality: o.quality,
          ),
      ];
      expect(engine.fit(observations: wrong, rider: truth, previousVersion: 0),
          isNull);
    });
  });

  group('which rides are worth learning from', () {
    test('a ride with no power is rejected', () {
      final o = observed(28, 0);
      final dead = CalibrationObservation(
        observedAt: o.observedAt,
        predictedPowerWatts: 200,
        actualPowerWatts: 0,
        predictedSpeedKmh: 28,
        observedSpeedKmh: 28,
        gradientPct: 0,
        systemMassKg: o.systemMassKg,
        activitySource: 'manual',
        quality: CalibrationQuality.high,
      );
      expect(engine.qualityOf(dead), CalibrationQuality.rejected);
    });

    test('a descent is rejected: wind and braking, not the rider', () {
      expect(engine.qualityOf(observed(40, -6)), CalibrationQuality.rejected);
    });

    test('a wall is rejected: nothing there is steady state', () {
      expect(engine.qualityOf(observed(8, 24)), CalibrationQuality.rejected);
    });

    test('a crawl is kept but barely weighted', () {
      expect(engine.qualityOf(observed(9, 8)), CalibrationQuality.low);
    });

    test('fast and flat is the best evidence there is', () {
      expect(engine.qualityOf(observed(32, 1)), CalibrationQuality.high);
    });

    test('a ride nothing like the one prescribed is rejected', () {
      expect(engine.qualityOf(observed(28, 0, predicted: 400)),
          CalibrationQuality.rejected);
    });
  });

  group('a changed rider invalidates what was learned', () {
    test('losing three kilos makes the calibration stale', () {
      expect(
          engine.invalidates(
              truth, const RiderProfile(weightKg: 69, ftpWatts: 250)),
          isTrue);
    });

    test('a new FTP makes it stale', () {
      expect(
          engine.invalidates(
              truth, const RiderProfile(weightKg: 72, ftpWatts: 265)),
          isTrue);
    });

    test('a hundred grams does not', () {
      expect(
          engine.invalidates(
              truth, const RiderProfile(weightKg: 72.1, ftpWatts: 250)),
          isFalse);
    });
  });
}
