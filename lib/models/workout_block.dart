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

/// What a block is for. Recovery is a block like any other, so the timeline
/// still distinguishes work from recovery (Feature 006 matches the sequence,
/// not just the totals) without recovery being a field hidden inside a work
/// block. Warm-up and cool-down are blocks too, which settles Feature 005's
/// open decision.
enum WorkoutBlockRole { warmUp, work, recovery, coolDown }

/// One segment of the prescribed workout: a zone held at a target for a
/// duration.
///
/// A workout is an ordered list of these, and that order IS the timeline -
/// "4x8min Z4 with 2min recovery" is written as Z4, Z1, Z4, Z1, Z4, Z1, Z4.
/// There is deliberately no repetition count: with recovery as its own block,
/// N consecutive repeats of the same block would be physically identical to
/// one block N times as long, so the field could only mislead.
class WorkoutBlock {
  final TrainingZone zone;
  final int durationMin;
  final WorkoutTarget target;
  final WorkoutBlockRole role;

  // Not const: the metric-agreement invariant below reads fields off the
  // zone and target objects, which a const constructor cannot evaluate.
  WorkoutBlock({
    required this.zone,
    required this.durationMin,
    required this.target,
    this.role = WorkoutBlockRole.work,
  })  : assert(durationMin > 0),
        // A block prescribed in watts must reference a power zone, and one
        // prescribed in heart rate a heart-rate zone: the two tables are
        // independent and their zone numbers are not interchangeable.
        assert(
          zone.metric == target.metric,
          'Block zone metric must match its target metric.',
        );

  bool get isRecovery => role == WorkoutBlockRole.recovery;

  int get totalDurationMin => durationMin;

  WorkoutBlock copyWith({
    TrainingZone? zone,
    int? durationMin,
    WorkoutTarget? target,
    WorkoutBlockRole? role,
  }) =>
      WorkoutBlock(
        zone: zone ?? this.zone,
        durationMin: durationMin ?? this.durationMin,
        target: target ?? this.target,
        role: role ?? this.role,
      );
}

/// Expands an ordered list of blocks into the timeline Feature 006 matches
/// against terrain. Every block becomes exactly one step, in order.
///
/// Work steps carry an `intervalId` so a route segment can reference the
/// specific interval it satisfies; recovery, warm-up and cool-down steps do
/// not, because nothing is matched to them by interval.
List<WorkoutTimelineStep> expandWorkout(List<WorkoutBlock> blocks) {
  final steps = <WorkoutTimelineStep>[];
  var workCount = 0;
  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    final isWork = block.role == WorkoutBlockRole.work;
    if (isWork) workCount++;
    steps.add(WorkoutTimelineStep(
      id: 'step-${i + 1}',
      sequenceIndex: i,
      isRecovery: block.isRecovery,
      role: block.role,
      durationMin: block.durationMin,
      zone: block.zone,
      target: block.target,
      intervalId: isWork ? 'interval-$workCount' : null,
    ));
  }
  return steps;
}

/// Total prescribed time, recovery included - it is part of the workout, not
/// an implicit gap.
int workoutDurationMin(List<WorkoutBlock> blocks) =>
    blocks.fold(0, (sum, b) => sum + b.durationMin);

class WorkoutTimelineStep {
  final String id;
  final int sequenceIndex;
  final bool isRecovery;
  final WorkoutBlockRole role;
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
    this.role = WorkoutBlockRole.work,
    this.intervalId,
  }) : assert(durationMin > 0);
}
