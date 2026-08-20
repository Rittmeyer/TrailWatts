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

  /// What the rider calls this block ("Aquecimento", "Serie principal").
  /// Null means they never named it, and the UI falls back to its position.
  ///
  /// It lives on the block rather than on the authoring group because the
  /// plan stores the flattened block sequence: a name kept only on the
  /// group would disappear the moment the workout was saved, which is a
  /// worse feature than no naming at all.
  final String? name;

  // Not const: the metric-agreement invariant below reads fields off the
  // zone and target objects, which a const constructor cannot evaluate.
  WorkoutBlock({
    required this.zone,
    required this.durationMin,
    required this.target,
    this.role = WorkoutBlockRole.work,
    this.name,
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
    String? name,
  }) =>
      WorkoutBlock(
        zone: zone ?? this.zone,
        durationMin: durationMin ?? this.durationMin,
        target: target ?? this.target,
        role: role ?? this.role,
        name: name ?? this.name,
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

/// A block as the rider authors it: one or more stimuli (e.g. a Z4 work
/// stimulus and its Z1 recovery) held together and, optionally, repeated as
/// one unit - so "4x8min Z4 with 2min easy" is one block with two stimuli
/// repeated 4 times, not four separate work blocks and four separate
/// recovery blocks typed out by hand. Settles the "repeat group" open
/// decision in specs/005-workout-builder/spec.md.
///
/// A group still expands to the same physically real `WorkoutBlock`
/// sequence as before - its stimuli, repeated `repeatCount` times, in
/// order - so the timeline Feature 006 matches against is exactly as
/// concrete as it always was.
class WorkoutBlockGroup {
  final List<WorkoutBlock> stimuli;
  final int repeatCount;

  WorkoutBlockGroup({
    required this.stimuli,
    this.repeatCount = 1,
  })  : assert(stimuli.isNotEmpty, 'A block needs at least one stimulus.'),
        assert(repeatCount >= 1);

  /// True once a second stimulus (e.g. recovery) has been added to the
  /// block - the case this class exists for.
  bool get isMultiStimulus => stimuli.length > 1;

  /// The physically real sequence this block stands for.
  List<WorkoutBlock> get expanded => [
        for (var i = 0; i < repeatCount; i++) ...stimuli,
      ];

  int get totalDurationMin =>
      repeatCount * stimuli.fold(0, (sum, b) => sum + b.durationMin);

  WorkoutBlockGroup copyWith({
    List<WorkoutBlock>? stimuli,
    int? repeatCount,
  }) =>
      WorkoutBlockGroup(
        stimuli: stimuli ?? this.stimuli,
        repeatCount: repeatCount ?? this.repeatCount,
      );
}

/// Flattens the rider-authored block groups into the physically real,
/// ordered block sequence `expandWorkout` and `workoutDurationMin` operate
/// on.
List<WorkoutBlock> flattenBlockGroups(List<WorkoutBlockGroup> groups) =>
    [for (final g in groups) ...g.expanded];

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
