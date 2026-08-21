import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/cycling_power_model.dart';
import 'package:trailwatt/models/calibration.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/services/calibration_store.dart';

const trueCda = 0.281;
const trueCrr = 0.0056;
const truth =
    RiderProfile(weightKg: 72, ftpWatts: 250, cda: trueCda, crr: trueCrr);

/// What the rider declared, which is not what the road says.
const declared = RiderProfile(weightKg: 72, ftpWatts: 250);

CalibrationObservation observed(double speedKmh, double gradientPct) {
  const model = CyclingPowerModel(truth);
  final actual =
      model.powerFor(speedMs: speedKmh / 3.6, gradientPct: gradientPct);
  return CalibrationObservation(
    observedAt: DateTime(2026, 5, 1),
    predictedPowerWatts: actual,
    actualPowerWatts: actual,
    predictedSpeedKmh: speedKmh,
    observedSpeedKmh: speedKmh,
    gradientPct: gradientPct,
    systemMassKg: truth.systemMassKg,
    activitySource: 'strava',
    quality: CalibrationQuality.high,
  );
}

List<CalibrationObservation> enoughRides() => [
      for (final s in [22.0, 26.0, 30.0, 34.0, 38.0]) observed(s, 0),
      for (final s in [14.0, 16.0, 18.0]) observed(s, 4),
      for (final s in [13.0, 15.0]) observed(s, 6),
    ];

void main() {
  group('what the road teaches replaces what was assumed', () {
    test('before any rides the declared constants are used', () {
      final store = CalibrationStore();
      expect(store.state, CalibrationState.generic);
      expect(store.effective(declared).cda, declared.cda);
    });

    test('after enough good rides the learned ones are', () {
      final store = CalibrationStore()..observeAll(enoughRides(), declared);

      expect(store.state, CalibrationState.calibrated);
      final effective = store.effective(declared);
      expect(effective.cda, closeTo(trueCda, 0.01),
          reason: 'declared ${declared.cda}, learned ${effective.cda}, '
              'real $trueCda');
      expect(effective.crr, closeTo(trueCrr, 0.001));
      // Everything else the rider told us is untouched.
      expect(effective.weightKg, declared.weightKg);
      expect(effective.ftpWatts, declared.ftpWatts);
    });

    test('a handful of rides is not enough to move anything', () {
      final store = CalibrationStore()
        ..observeAll(enoughRides().take(3).toList(), declared);

      expect(store.state, CalibrationState.generic);
      expect(store.effective(declared).cda, declared.cda,
          reason: 'a wrong calibration is worse than none');
    });
  });

  group('a changed rider invalidates it', () {
    test('losing weight marks it stale and stops it being used', () {
      final store = CalibrationStore()..observeAll(enoughRides(), declared);
      expect(store.state, CalibrationState.calibrated);

      const lighter = RiderProfile(weightKg: 68, ftpWatts: 250);
      store.riderChanged(declared, lighter);

      expect(store.state, CalibrationState.stale);
      expect(store.effective(lighter).cda, lighter.cda,
          reason: 'stale constants must not keep steering estimates');
    });

    test('stale keeps the numbers so the rider can see what it was', () {
      final store = CalibrationStore()..observeAll(enoughRides(), declared);
      final learned = store.profile!.cda;

      store.riderChanged(
          declared, const RiderProfile(weightKg: 68, ftpWatts: 250));

      expect(store.profile!.cda, learned,
          reason: 'deleted it would be a silent change');
      expect(store.profile!.state, CalibrationState.stale);
    });

    test('a trivial change leaves it alone', () {
      final store = CalibrationStore()..observeAll(enoughRides(), declared);
      store.riderChanged(
          declared, const RiderProfile(weightKg: 72.2, ftpWatts: 250));
      expect(store.state, CalibrationState.calibrated);
    });
  });

  group('it says how it got there', () {
    test('every ride seen is counted, usable or not', () {
      final store = CalibrationStore()
        ..observeAll(enoughRides(), declared)
        // A descent: real ride, useless evidence.
        ..observe(observed(45, -8), declared);

      expect(store.observationCount, enoughRides().length + 1);
      expect(store.profile!.observationCount, lessThan(store.observationCount),
          reason: 'how many were seen and how few were usable is the answer '
              'to "why am I still on the generic model"');
    });
  });
}
