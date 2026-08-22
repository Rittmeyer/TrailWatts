import 'dart:math' as math;

import '../models/calibration.dart';

/// A completed ride as the platforms record it: one value per sample, with
/// the samples lined up by index.
///
/// Normalised on purpose. Strava, Garmin and Wahoo each shape their streams
/// differently, and nothing downstream should have to know which one a ride
/// came from.
class ActivityStream {
  /// Seconds from the start of the ride.
  final List<double> timeS;

  /// Cumulative distance in metres.
  final List<double> distanceM;

  /// Height above sea level. Null per sample where the device had none.
  final List<double?> altitudeM;

  /// Power at the pedals. Null per sample where there was no meter.
  final List<double?> powerW;

  final String source;

  const ActivityStream({
    required this.timeS,
    required this.distanceM,
    required this.altitudeM,
    required this.powerW,
    required this.source,
  });

  int get length => math.min(math.min(timeS.length, distanceM.length),
      math.min(altitudeM.length, powerW.length));

  /// A ride with no power meter or no barometer cannot calibrate anything,
  /// and saying so early is cheaper than discovering it per window.
  bool get canCalibrate =>
      length >= 2 &&
      powerW.any((p) => p != null && p > 0) &&
      altitudeM.any((a) => a != null);
}

/// Turns a ride into the steady stretches worth learning from.
///
/// The power model describes a rider holding an effort on a constant
/// gradient. Most of a ride is not that: accelerating out of junctions,
/// braking into corners, freewheeling. Feeding all of it to the fit would
/// teach it that riders are slower than they are.
///
/// So a ride is cut into windows and a window is kept only when the rider
/// was actually doing one thing for its whole length.
class ActivityStreamReader {
  /// Long enough to average out pedal strokes and traffic lights, short
  /// enough that the ground underneath stays one gradient.
  final int windowSeconds;

  /// How much power may wobble inside a window and still count as steady,
  /// as a share of its own mean.
  final double maxPowerVariation;

  /// How much the speed may wobble. A window that includes a stop is not a
  /// window at one speed, whatever its average says.
  final double maxSpeedVariation;

  const ActivityStreamReader({
    this.windowSeconds = 60,
    this.maxPowerVariation = 0.25,
    this.maxSpeedVariation = 0.20,
  });

  List<CalibrationObservation> observationsFrom(
    ActivityStream stream, {
    required double systemMassKg,
    required DateTime ridenAt,
    double Function(double speedKmh, double gradientPct)? predictPower,
  }) {
    if (!stream.canCalibrate) return const [];

    final out = <CalibrationObservation>[];
    final n = stream.length;
    var start = 0;

    while (start < n - 1) {
      final end = _endOfWindow(stream, start, n);
      if (end <= start) {
        start++;
        continue;
      }

      final observation = _readWindow(
        stream,
        start,
        end,
        systemMassKg: systemMassKg,
        ridenAt: ridenAt,
        predictPower: predictPower,
      );
      if (observation != null) out.add(observation);
      start = end;
    }
    return out;
  }

  int _endOfWindow(ActivityStream stream, int start, int n) {
    final target = stream.timeS[start] + windowSeconds;
    var end = start + 1;
    while (end < n - 1 && stream.timeS[end] < target) {
      end++;
    }
    return end;
  }

  CalibrationObservation? _readWindow(
    ActivityStream stream,
    int start,
    int end, {
    required double systemMassKg,
    required DateTime ridenAt,
    double Function(double speedKmh, double gradientPct)? predictPower,
  }) {
    final seconds = stream.timeS[end] - stream.timeS[start];
    final metres = stream.distanceM[end] - stream.distanceM[start];
    if (seconds < windowSeconds * 0.6) return null;
    // A window the rider barely moved through is a stop, not a stretch.
    if (metres < 50) return null;

    final startAltitude = stream.altitudeM[start];
    final endAltitude = stream.altitudeM[end];
    if (startAltitude == null || endAltitude == null) return null;

    final powers = <double>[];
    final speeds = <double>[];
    for (var i = start; i < end; i++) {
      final p = stream.powerW[i];
      if (p == null) return null; // a gap in the meter, not a zero
      powers.add(p);

      final dt = stream.timeS[i + 1] - stream.timeS[i];
      if (dt <= 0) continue;
      speeds.add((stream.distanceM[i + 1] - stream.distanceM[i]) / dt);
    }
    if (powers.isEmpty || speeds.isEmpty) return null;

    final meanPower = _mean(powers);
    if (meanPower <= 0) return null;
    if (_variation(powers, meanPower) > maxPowerVariation) return null;

    final meanSpeed = _mean(speeds);
    if (meanSpeed <= 0) return null;
    if (_variation(speeds, meanSpeed) > maxSpeedVariation) return null;

    final speedKmh = metres / seconds * 3.6;
    final gradientPct = (endAltitude - startAltitude) / metres * 100;

    return CalibrationObservation(
      observedAt: ridenAt.add(Duration(seconds: stream.timeS[start].round())),
      // What the model would have said for this ground. Kept so the rider
      // can be shown how far off it was, never used as a reason to discard
      // the window - that gap is what there is to learn from.
      predictedPowerWatts: predictPower?.call(speedKmh, gradientPct) ?? 0,
      actualPowerWatts: meanPower,
      predictedSpeedKmh: speedKmh,
      observedSpeedKmh: speedKmh,
      gradientPct: gradientPct,
      systemMassKg: systemMassKg,
      activitySource: stream.source,
      quality: CalibrationQuality.medium,
    );
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  /// Spread as a share of the mean, which is what "steady" has to mean when
  /// 200 W and 20 W are both being judged.
  static double _variation(List<double> values, double mean) {
    if (mean.abs() < 1e-9) return double.infinity;
    var sum = 0.0;
    for (final v in values) {
      sum += (v - mean) * (v - mean);
    }
    return math.sqrt(sum / values.length) / mean.abs();
  }
}
