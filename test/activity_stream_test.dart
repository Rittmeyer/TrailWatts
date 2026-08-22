import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/activity_stream.dart';
import 'package:trailwatt/engine/calibration_engine.dart';
import 'package:trailwatt/engine/cycling_power_model.dart';
import 'package:trailwatt/models/rider_profile.dart';

const trueCda = 0.294;
const trueCrr = 0.0048;
const truth =
    RiderProfile(weightKg: 70, ftpWatts: 240, cda: trueCda, crr: trueCrr);
const model = CyclingPowerModel(truth);

const reader = ActivityStreamReader();
const engine = CalibrationEngine();

/// One stretch of a ride: [seconds] held at [speedKmh] on [gradientPct],
/// with the power that rider would really have had to produce, sampled once
/// a second the way a head unit records.
class Stretch {
  final double seconds, speedKmh, gradientPct, powerNoise;
  const Stretch(this.seconds, this.speedKmh, this.gradientPct,
      {this.powerNoise = 0});
}

/// Builds a stream out of stretches, plus optional gaps where the rider
/// stopped - which is what a real ride is full of.
ActivityStream rideOf(List<Stretch> stretches, {int seed = 3}) {
  final rnd = math.Random(seed);
  final time = <double>[];
  final distance = <double>[];
  final altitude = <double?>[];
  final power = <double?>[];

  var t = 0.0, d = 0.0, h = 500.0;
  for (final s in stretches) {
    final v = s.speedKmh / 3.6;
    final watts = model.powerFor(speedMs: v, gradientPct: s.gradientPct);
    for (var i = 0; i < s.seconds; i++) {
      time.add(t);
      distance.add(d);
      altitude.add(h);
      power.add(s.speedKmh <= 0
          ? 0
          : watts * (1 + (rnd.nextDouble() - 0.5) * 2 * s.powerNoise));
      t += 1;
      d += v;
      h += v * s.gradientPct / 100;
    }
  }
  time.add(t);
  distance.add(d);
  altitude.add(h);
  power.add(0);

  return ActivityStream(
    timeS: time,
    distanceM: distance,
    altitudeM: altitude,
    powerW: power,
    source: 'strava',
  );
}

/// A ride with the spread a fit needs: fast and flat where drag shows,
/// slower and climbing where rolling resistance does.
ActivityStream varied({double noise = 0}) => rideOf([
      for (final v in [24.0, 28.0, 32.0, 36.0])
        Stretch(180, v, 0, powerNoise: noise),
      for (final v in [15.0, 17.0, 19.0]) Stretch(180, v, 4, powerNoise: noise),
      for (final v in [13.0, 14.5]) Stretch(180, v, 6, powerNoise: noise),
    ]);

void main() {
  group('a ride becomes the stretches worth learning from', () {
    test('steady stretches are read out of it', () {
      final observations = reader.observationsFrom(varied(),
          systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1));

      expect(observations, isNotEmpty);
      // Nine stretches of three minutes, cut into windows of one.
      expect(observations.length, greaterThanOrEqualTo(20));
    });

    test('the speed and gradient read back are the ones ridden', () {
      final observations = reader.observationsFrom(
          rideOf([const Stretch(180, 30, 0)]),
          systemMassKg: truth.systemMassKg,
          ridenAt: DateTime(2026, 5, 1));

      expect(observations.first.observedSpeedKmh, closeTo(30, 0.5));
      expect(observations.first.gradientPct, closeTo(0, 0.2));
    });

    test('a climb reads as a climb', () {
      final observations = reader.observationsFrom(
          rideOf([const Stretch(180, 14, 7)]),
          systemMassKg: truth.systemMassKg,
          ridenAt: DateTime(2026, 5, 1));

      expect(observations.first.gradientPct, closeTo(7, 0.3));
    });
  });

  group('what is left out, and why', () {
    test('a stop is not a stretch at low speed', () {
      final withStop = rideOf([
        const Stretch(60, 30, 0),
        const Stretch(60, 0, 0), // traffic light
        const Stretch(60, 30, 0),
      ]);
      final observations = reader.observationsFrom(withStop,
          systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1));

      for (final o in observations) {
        expect(o.observedSpeedKmh, greaterThan(20),
            reason: 'a window containing a stop averaged into a slow ride');
      }
    });

    test('a window where the effort was not steady is dropped', () {
      final surging = reader.observationsFrom(
          rideOf([const Stretch(180, 28, 0, powerNoise: 0.9)]),
          systemMassKg: truth.systemMassKg,
          ridenAt: DateTime(2026, 5, 1));
      final steady = reader.observationsFrom(
          rideOf([const Stretch(180, 28, 0)]),
          systemMassKg: truth.systemMassKg,
          ridenAt: DateTime(2026, 5, 1));

      expect(surging.length, lessThan(steady.length));
    });

    test('a gap in the power meter drops the window, not zeroes it', () {
      final stream = rideOf([const Stretch(180, 28, 0)]);
      final holed = ActivityStream(
        timeS: stream.timeS,
        distanceM: stream.distanceM,
        altitudeM: stream.altitudeM,
        powerW: [
          for (var i = 0; i < stream.powerW.length; i++)
            i > 20 && i < 40 ? null : stream.powerW[i],
        ],
        source: stream.source,
      );

      final observations = reader.observationsFrom(holed,
          systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1));

      expect(observations.length, lessThan(3),
          reason: 'a missing reading is not zero watts');
    });

    test('a ride with no power meter yields nothing at all', () {
      final stream = rideOf([const Stretch(300, 28, 0)]);
      final noMeter = ActivityStream(
        timeS: stream.timeS,
        distanceM: stream.distanceM,
        altitudeM: stream.altitudeM,
        powerW: List<double?>.filled(stream.powerW.length, null),
        source: stream.source,
      );

      expect(noMeter.canCalibrate, isFalse);
      expect(
          reader.observationsFrom(noMeter,
              systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1)),
          isEmpty);
    });

    test('a ride with no barometer yields nothing either', () {
      final stream = rideOf([const Stretch(300, 28, 0)]);
      final noBaro = ActivityStream(
        timeS: stream.timeS,
        distanceM: stream.distanceM,
        altitudeM: List<double?>.filled(stream.altitudeM.length, null),
        powerW: stream.powerW,
        source: stream.source,
      );

      expect(noBaro.canCalibrate, isFalse);
    });
  });

  group('the whole loop: a ride teaches the model the rider', () {
    test('constants are recovered from a synthesised ride', () {
      final observations = reader.observationsFrom(varied(),
          systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1));

      // The rider the app believes in, which is not the real one.
      const declared = RiderProfile(weightKg: 70, ftpWatts: 240);
      final profile = engine.fit(
          observations: observations, rider: declared, previousVersion: 0);

      expect(profile, isNotNull,
          reason: '${observations.length} observations were not enough');
      expect(profile!.cda, closeTo(trueCda, 0.02),
          reason: 'declared ${declared.cda}, learned ${profile.cda}, '
              'real $trueCda');
      expect(profile.crr, closeTo(trueCrr, 0.001),
          reason: 'declared ${declared.crr}, learned ${profile.crr}, '
              'real $trueCrr');
    });

    test('a noisy ride still lands closer than the catalogue guess', () {
      final observations = reader.observationsFrom(varied(noise: 0.08),
          systemMassKg: truth.systemMassKg, ridenAt: DateTime(2026, 5, 1));

      const declared = RiderProfile(weightKg: 70, ftpWatts: 240);
      final profile = engine.fit(
          observations: observations, rider: declared, previousVersion: 0);

      final learnedError = (profile!.cda - trueCda).abs();
      final guessError = (declared.cda - trueCda).abs();
      expect(learnedError, lessThan(guessError),
          reason: 'learned off by $learnedError, guess off by $guessError');
    });

    test('one flat ride cannot separate the two constants', () {
      // All at one speed on one gradient: informative about the sum, not
      // about which of the two it belongs to.
      final observations = reader.observationsFrom(
          rideOf([const Stretch(900, 30, 0)]),
          systemMassKg: truth.systemMassKg,
          ridenAt: DateTime(2026, 5, 1));

      expect(observations.length, greaterThanOrEqualTo(8));
      expect(
          engine.fit(
              observations: observations,
              rider: const RiderProfile(weightKg: 70, ftpWatts: 240),
              previousVersion: 0),
          isNull,
          reason: 'fitting this would put all the error into one constant');
    });
  });
}
