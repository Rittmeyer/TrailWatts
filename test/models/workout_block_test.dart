import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';

const _powerZ4 =
    TrainingZone(metric: ZoneMetric.power, scale: ZoneScale.seven, index: 4);
const _powerZ1 =
    TrainingZone(metric: ZoneMetric.power, scale: ZoneScale.seven, index: 1);

void main() {
  test('expands 3x10min with 5min recovery into the correct timeline', () {
    final block = WorkoutBlock(
      zone: _powerZ4,
      durationMin: 10,
      repetitions: 3,
      target: const WorkoutTarget(
        metric: ZoneMetric.power,
        minValue: 250,
        maxValue: 270,
      ),
      recoveryDurationMin: 5,
      recoveryZone: _powerZ1,
      recoveryTarget: const WorkoutTarget(
        metric: ZoneMetric.power,
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

  test('a watts block cannot carry a heart-rate zone', () {
    expect(
      () => WorkoutBlock(
        zone: const TrainingZone(
            metric: ZoneMetric.heartRate, scale: ZoneScale.five, index: 4),
        durationMin: 10,
        target: const WorkoutTarget(
            metric: ZoneMetric.power, minValue: 250, maxValue: 270),
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
