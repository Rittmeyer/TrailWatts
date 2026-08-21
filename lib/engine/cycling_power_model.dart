import 'dart:math' as math;

import '../models/rider_profile.dart';
import '../models/terrain_target.dart';

/// One power model for every rider (Constitution Article I, spec 001): the
/// formula is fixed and personalization only moves constants - mass, CdA,
/// Crr, drivetrain efficiency - which all live on [RiderProfile].
///
/// Steady-state road cycling power:
///
///   P = (F_roll + F_grav + F_aero) * v / efficiency
///
/// with F_roll = Crr * m * g * cos(atan(s)), F_grav = m * g * sin(atan(s))
/// and F_aero = 0.5 * rho * CdA * v_air^2. Acceleration is deliberately not
/// modelled: the matcher asks what a rider can *hold* over a stretch of
/// terrain, which is a steady-state question.
class CyclingPowerModel {
  final RiderProfile rider;

  /// Sea-level ISA density. Altitude matters - about 3% less drag per 300 m -
  /// but the elevation of the ride is not always known, and quietly assuming
  /// thin air would flatter the numbers.
  final double airDensityKgM3;

  const CyclingPowerModel(this.rider, {this.airDensityKgM3 = 1.225});

  static const _g = 9.80665;

  /// Highest speed the solver will consider, ~108 km/h: past any speed a
  /// rider holds on a road, so a bracket that reaches it means "faster than
  /// this model is willing to claim".
  static const _maxSpeedMs = 30.0;

  /// Crr multipliers by surface. Rolling resistance is what surface really
  /// changes; treating gravel as asphalt is how a route that cannot hold the
  /// target gets recommended anyway.
  static double crrFactor(SurfaceType surface) => switch (surface) {
        SurfaceType.asphalt => 1.0,
        SurfaceType.gravel => 2.6,
        SurfaceType.dirt => 4.0,
      };

  double _rollingForce(double gradientPct, SurfaceType surface) {
    final angle = math.atan(gradientPct / 100);
    return rider.crr *
        crrFactor(surface) *
        rider.systemMassKg *
        _g *
        math.cos(angle);
  }

  double _gravityForce(double gradientPct) {
    final angle = math.atan(gradientPct / 100);
    return rider.systemMassKg * _g * math.sin(angle);
  }

  /// Power needed to hold [speedMs] on [gradientPct].
  ///
  /// [headwindMs] is the component of wind along the direction of travel:
  /// positive is a headwind. Drag is signed so a tailwind stronger than the
  /// rider's speed pushes rather than resists.
  double powerFor({
    required double speedMs,
    required double gradientPct,
    SurfaceType surface = SurfaceType.asphalt,
    double headwindMs = 0,
  }) {
    if (speedMs <= 0) return 0;
    final airSpeed = speedMs + headwindMs;
    final drag = 0.5 * airDensityKgM3 * rider.cda * airSpeed * airSpeed.abs();
    final force =
        _rollingForce(gradientPct, surface) + _gravityForce(gradientPct) + drag;
    return force * speedMs / rider.drivetrainEfficiency;
  }

  /// The speed [powerW] buys on this terrain.
  ///
  /// P(v) is not monotonic on a descent - gravity makes it dip below zero
  /// before drag takes over - so bisection has to start past the turning
  /// point or it can converge on a physically meaningless root. Below that
  /// point the rider is coasting, not pedalling.
  RidingSolution solveSpeed({
    required double powerW,
    required double gradientPct,
    SurfaceType surface = SurfaceType.asphalt,
    double headwindMs = 0,
  }) {
    final a = _rollingForce(gradientPct, surface) + _gravityForce(gradientPct);
    final k = 0.5 * airDensityKgM3 * rider.cda;

    // Where P(v) stops falling and starts rising: dP/dv = a + 3k v^2 = 0.
    final turning = a >= 0 ? 0.0 : math.sqrt(-a / (3 * k));

    // Coasting: the speed gravity alone sustains, P(v) = 0 above the turn.
    final coasting = _bisect(
      (v) => powerFor(
          speedMs: v,
          gradientPct: gradientPct,
          surface: surface,
          headwindMs: headwindMs),
      0,
      turning,
      _maxSpeedMs,
    );

    if (powerW <= 0) {
      return RidingSolution(
          speedMs: coasting, powerW: 0, coasting: true, capped: false);
    }

    // Above the coasting speed the rider is pedalling again, so that is where
    // the bracket starts. Whether the resulting speed is a sane thing to ask
    // of a rider is the matcher's call, not the model's: pedalling hard down
    // a hill is physically fine and trainingwise usually pointless.
    final v = _bisect(
      (x) => powerFor(
          speedMs: x,
          gradientPct: gradientPct,
          surface: surface,
          headwindMs: headwindMs),
      powerW,
      math.max(turning, coasting),
      _maxSpeedMs,
    );

    return RidingSolution(
      speedMs: v,
      powerW: powerW,
      coasting: v <= coasting + 1e-6,
      capped: v >= _maxSpeedMs - 1e-6,
    );
  }

  /// Solves f(v) = target on [lo, hi], where f is increasing across it.
  static double _bisect(
      double Function(double) f, double target, double lo, double hi) {
    if (f(hi) <= target) return hi;
    if (f(lo) >= target) return lo;
    var low = lo, high = hi;
    // 60 halvings takes a 30 m/s bracket well below floating-point noise;
    // it is a fixed cost so the matcher's timing stays predictable.
    for (var i = 0; i < 60; i++) {
      final mid = (low + high) / 2;
      if (f(mid) < target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }
}

/// What the model says a rider does on a stretch of road.
class RidingSolution {
  final double speedMs;

  /// Power actually being produced: zero when the terrain carries the rider.
  final double powerW;

  /// The rider is not pedalling - gravity alone is faster than the target.
  final bool coasting;

  /// The solver hit its speed ceiling, so this is a floor on the real speed
  /// rather than the real speed.
  final bool capped;

  const RidingSolution({
    required this.speedMs,
    required this.powerW,
    required this.coasting,
    required this.capped,
  });

  double get speedKmh => speedMs * 3.6;
}
