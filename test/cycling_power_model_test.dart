import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/cycling_power_model.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/terrain_target.dart';

/// Checked against figures a cyclist would recognise rather than against
/// the implementation: a model that agrees with itself proves nothing.
void main() {
  // 74 kg rider, 8 kg bike, ordinary road position.
  const rider = RiderProfile(weightKg: 74, ftpWatts: 210);
  const model = CyclingPowerModel(rider);

  double kmh(double v) => v * 3.6;

  group('power for a held speed', () {
    test('200 W on the flat lands in the low 30s km/h', () {
      final v = model.solveSpeed(powerW: 200, gradientPct: 0).speedMs;
      expect(kmh(v), inInclusiveRange(29, 35));
    });

    test('a 8% climb at 200 W is a walking-pace grind', () {
      final v = model.solveSpeed(powerW: 200, gradientPct: 8).speedMs;
      expect(kmh(v), inInclusiveRange(7, 11));
    });

    test('doubling power on a climb roughly doubles speed', () {
      // On a steep climb almost all power goes into lifting mass, so speed
      // is close to linear in power - unlike on the flat.
      final low = model.solveSpeed(powerW: 150, gradientPct: 10).speedMs;
      final high = model.solveSpeed(powerW: 300, gradientPct: 10).speedMs;
      expect(high / low, inInclusiveRange(1.8, 2.1));
    });

    test('on the flat it takes far more than double for double speed', () {
      final low = model.solveSpeed(powerW: 100, gradientPct: 0).speedMs;
      final high = model.solveSpeed(powerW: 200, gradientPct: 0).speedMs;
      expect(high / low, lessThan(1.4));
    });
  });

  group('surface', () {
    test('gravel costs speed at the same power', () {
      final road = model
          .solveSpeed(powerW: 200, gradientPct: 0, surface: SurfaceType.asphalt)
          .speedMs;
      final gravel = model
          .solveSpeed(powerW: 200, gradientPct: 0, surface: SurfaceType.gravel)
          .speedMs;
      expect(gravel, lessThan(road));
      // Rolling resistance is a small share of flat power at speed, so the
      // penalty is real but not dramatic.
      expect(gravel / road, inInclusiveRange(0.85, 0.98));
    });
  });

  group('descents', () {
    test('a rider coasts rather than stops when the road falls away', () {
      final s = model.solveSpeed(powerW: 0, gradientPct: -6);
      expect(s.coasting, isTrue);
      expect(kmh(s.speedMs), greaterThan(30));
    });

    test('the solver does not settle on the wrong root below the turn', () {
      // P(v) dips negative on a descent before drag takes over. A bisection
      // started at zero can converge there and report a crawl.
      final s = model.solveSpeed(powerW: 150, gradientPct: -6);
      final coast = model.solveSpeed(powerW: 0, gradientPct: -6);
      expect(s.speedMs, greaterThan(coast.speedMs));
    });
  });

  group('wind', () {
    test('a headwind costs speed and a tailwind gives it back', () {
      final still = model.solveSpeed(powerW: 200, gradientPct: 0).speedMs;
      final into =
          model.solveSpeed(powerW: 200, gradientPct: 0, headwindMs: 5).speedMs;
      final behind =
          model.solveSpeed(powerW: 200, gradientPct: 0, headwindMs: -5).speedMs;
      expect(into, lessThan(still));
      expect(behind, greaterThan(still));
    });
  });

  group('round trip', () {
    test('the solved speed reproduces the power it was solved for', () {
      for (final gradient in [-8.0, -2.0, 0.0, 3.0, 7.0, 12.0]) {
        final v = model.solveSpeed(powerW: 220, gradientPct: gradient).speedMs;
        final back = model.powerFor(speedMs: v, gradientPct: gradient);
        expect(back, closeTo(220, 0.5), reason: 'at $gradient%');
      }
    });
  });
}
