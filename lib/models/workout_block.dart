import 'zone.dart';

/// The target metric IS the zone metric - one concept, one enum, so a
/// watts target can never be paired with a heart-rate zone by accident.
typedef WorkoutTargetMetric = ZoneMetric;

class WorkoutTarget {
  final ZoneMetric metric;
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
  final TrainingZone zone;
  final int durationMin;
  final int repetitions;
  final WorkoutTarget target;
  final int? recoveryDurationMin;
  final TrainingZone? recoveryZone;
  final WorkoutTarget? recoveryTarget;

  // Not const: the metric-agreement invariants below read fields off the
  // zone and target objects, which a const constructor cannot evaluate.
  WorkoutBlock({
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
        ),
        // A block prescribed in watts must reference a power zone, and one
        // prescribed in heart rate a heart-rate zone: the two tables are
        // independent and their zone numbers are not interchangeable.
        assert(
          zone.metric == target.metric,
          'Block zone metric must match its target metric.',
        ),
        assert(
          recoveryZone == null ||
              recoveryTarget == null ||
              recoveryZone.metric == recoveryTarget.metric,
          'Recovery zone metric must match its recovery target metric.',
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
  final TrainingZone zone;
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
