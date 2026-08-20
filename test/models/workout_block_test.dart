import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';

const _z4 =
    TrainingZone(metric: ZoneMetric.power, scale: ZoneScale.seven, index: 4);
const _z1 =
    TrainingZone(metric: ZoneMetric.power, scale: ZoneScale.seven, index: 1);

WorkoutBlock _work(int minutes) => WorkoutBlock(
      zone: _z4,
      durationMin: minutes,
      target: const WorkoutTarget(
          metric: ZoneMetric.power, minValue: 250, maxValue: 270),
    );

WorkoutBlock _recovery(int minutes) => WorkoutBlock(
      role: WorkoutBlockRole.recovery,
      zone: _z1,
      durationMin: minutes,
      target: const WorkoutTarget(
          metric: ZoneMetric.power, minValue: 100, maxValue: 150),
    );

void main() {
  group('the block list IS the timeline', () {
    test('3x10min with 5min recovery is written as alternating blocks', () {
      // Recovery is a block, not a field: the rider writes the sequence out.
      final blocks = [
        _work(10),
        _recovery(5),
        _work(10),
        _recovery(5),
        _work(10),
      ];

      final steps = expandWorkout(blocks);

      expect(steps.map((s) => s.durationMin), [10, 5, 10, 5, 10]);
      expect(steps.map((s) => s.isRecovery), [false, true, false, true, false]);
      expect(workoutDurationMin(blocks), 40);
    });

    test('every block becomes exactly one step, in order', () {
      final blocks = [_work(8), _recovery(2), _work(8)];
      final steps = expandWorkout(blocks);

      expect(steps, hasLength(blocks.length));
      expect(steps.map((s) => s.sequenceIndex), [0, 1, 2]);
      expect(steps.map((s) => s.zone), [_z4, _z1, _z4]);
    });

    test('only work steps carry an interval id, numbered across the workout',
        () {
      final steps = expandWorkout([_work(8), _recovery(2), _work(8)]);

      expect(steps[0].intervalId, 'interval-1');
      expect(steps[1].intervalId, isNull,
          reason: 'recovery matches no interval');
      expect(steps[2].intervalId, 'interval-2');
    });

    test('recovery time counts towards the workout, it is not a gap', () {
      expect(workoutDurationMin([_work(10), _recovery(5), _work(10)]), 25);
    });

    test('an empty workout has no steps and no duration', () {
      expect(expandWorkout([]), isEmpty);
      expect(workoutDurationMin([]), 0);
    });
  });

  group('block invariants', () {
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

    test('a block must last some time', () {
      expect(() => _work(0), throwsA(isA<AssertionError>()));
    });

    test('roles other than work are not recovery', () {
      expect(_work(10).isRecovery, isFalse);
      expect(_recovery(5).isRecovery, isTrue);
      final warmUp = _work(10).copyWith(role: WorkoutBlockRole.warmUp);
      expect(warmUp.isRecovery, isFalse);
      expect(expandWorkout([warmUp]).single.intervalId, isNull,
          reason: 'a warm-up is not an interval to match against');
    });
  });
}
