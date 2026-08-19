import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/terrain_target.dart';

void main() {
  test('terrain result does not own a single route distance', () {
    const result = TerrainTargetResult(
      options: [
        TerrainOption(
          gradientPct: 0,
          speedKmh: 32,
          durationMin: 10,
          distanceM: 5333,
          predictedPowerWatts: 250,
          feasible: true,
          confidence: ModelConfidence.medium,
        ),
      ],
      modelState: ModelState.generic,
      confidence: ModelConfidence.medium,
    );

    expect(result.options.single.distanceM, 5333);
  });
}
