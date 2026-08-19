import 'zone.dart';

enum WorkoutTargetMetric { watts, heartRate }

class WorkoutTarget {
  final WorkoutTargetMetric metric;
  final int minValue;
  final int maxValue;

  const WorkoutTarget({
    required this.metric,
    required this.minValue,
    required this.maxValue,
  })  : assert(minValue >= 0),
        assert(maxValue >= minValue);
}

/// A single prescribed training stimulus. Recovery is modeled explicitly.
class WorkoutBlock {
  final Zone zone;
  final int durationMin;
  final int repetitions;
  final WorkoutTarget target;
  final int? recoveryDurationMin;
  final Zone? recoveryZone;
  final WorkoutTarget? recoveryTarget;

  const WorkoutBlock({
    required this.zone,
    required this.durationMin,
    this.repetitions = 1,
    required this.target,
    this.recoveryDurationMin,
    this.recoveryZone,
    this.recoveryTarget,
  })  : assert(durationMin > 0),
        assert(repetitions > 0),
        assert(
          repetitions == 1 || recoveryDurationMin != null,
          'Repeated blocks require an explicit recovery duration.',
        ),
        assert(
          repetitions == 1 || recoveryZone != null,
          'Repeated blocks require an explicit recovery zone.',
        ),
        assert(
          repetitions == 1 || recoveryTarget != null,
          'Repeated blocks require an explicit recovery target.',
        );

  bool get isRepeated => repetitions > 1;

  int get workDurationTotalMin => durationMin * repetitions;

  int get recoveryDurationTotalMin =>
      isRepeated ? (repetitions - 1) * recoveryDurationMin! : 0;

  int get totalDurationMin => workDurationTotalMin + recoveryDurationTotalMin;

  List<WorkoutTimelineStep> expand({required String blockId}) {
    final steps = <WorkoutTimelineStep>[];
    for (var repetition = 0; repetition < repetitions; repetition++) {
      steps.add(WorkoutTimelineStep(
        id: '$blockId-work-${repetition + 1}',
        sequenceIndex: steps.length,
        isRecovery: false,
        durationMin: durationMin,
        zone: zone,
        target: target,
        intervalId: '$blockId-${repetition + 1}',
      ));
      if (repetition < repetitions - 1) {
        steps.add(WorkoutTimelineStep(
          id: '$blockId-recovery-${repetition + 1}',
          sequenceIndex: steps.length,
          isRecovery: true,
          durationMin: recoveryDurationMin!,
          zone: recoveryZone!,
          target: recoveryTarget!,
        ));
      }
    }
    return steps;
  }
}

class WorkoutTimelineStep {
  final String id;
  final int sequenceIndex;
  final bool isRecovery;
  final int durationMin;
  final Zone zone;
  final WorkoutTarget target;
  final String? intervalId;

  const WorkoutTimelineStep({
    required this.id,
    required this.sequenceIndex,
    required this.isRecovery,
    required this.durationMin,
    required this.zone,
    required this.target,
    this.intervalId,
  }) : assert(durationMin > 0);
}
