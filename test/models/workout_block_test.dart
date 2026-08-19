import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';

void main() {
  test('expands 3x10min with 5min recovery into the correct timeline', () {
    const block = WorkoutBlock(
      zone: Zone.limiar,
      durationMin: 10,
      repetitions: 3,
      target: WorkoutTarget(
        metric: WorkoutTargetMetric.watts,
        minValue: 250,
        maxValue: 270,
      ),
      recoveryDurationMin: 5,
      recoveryZone: Zone.recuperacao,
      recoveryTarget: WorkoutTarget(
        metric: WorkoutTargetMetric.watts,
        minValue: 100,
        maxValue: 150,
      ),
    );

    final steps = block.expand(blockId: 'b1');

    expect(steps.map((step) => step.durationMin), [10, 5, 10, 5, 10]);
    expect(steps.where((step) => !step.isRecovery), hasLength(3));
    expect(steps[2].intervalId, 'b1-2');
    expect(block.totalDurationMin, 40);
  });
}
