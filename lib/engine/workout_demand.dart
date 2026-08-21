import 'dart:math' as math;

import '../models/rider_profile.dart';
import '../models/terrain_target.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import 'cycling_power_model.dart';

/// How a repetition can be laid on the ground.
///
/// A preference about how a session feels to ride, not a fact about the
/// terrain, which is why the engine scores them but does not decide alone
/// (Feature 011).
enum RepetitionShape {
  /// Up and back down the same stretch. The return doubles as the recovery
  /// between efforts, which spec 006 already calls valid recovery terrain.
  outAndBack,

  /// A short circuit that re-enters the stretch each lap. Keeps the rider
  /// moving forwards, but needs a mesh that closes.
  loop,

  /// A different stretch for each effort. More varied, and it needs several
  /// times the terrain, which is not always there.
  distinctStretches,
}

/// One distinct instruction the search has to find ground for, and how many
/// times the session asks for it.
class StimulusDemand {
  /// A stimulus that stands for the whole group of identical ones.
  final WorkoutBlock block;

  final int repetitions;

  /// The watts this is matched at. For a heart-rate stimulus it is the
  /// equivalent, which spec 001 requires to be visible rather than hidden.
  final int targetWatts;

  const StimulusDemand({
    required this.block,
    required this.repetitions,
    required this.targetWatts,
  });

  bool get isWork => block.role == WorkoutBlockRole.work;

  /// Ground one repetition needs.
  ///
  /// Estimated on the flat, which is the fastest the rider goes at that
  /// target and therefore the most ground a repetition can ask for. Sizing
  /// a search on anything shorter would come up short on flat terrain.
  double distancePerRepetitionM(CyclingPowerModel model) {
    final solved = model.solveSpeed(
      powerW: targetWatts.toDouble(),
      gradientPct: 0,
      surface: SurfaceType.asphalt,
    );
    return solved.speedMs * block.durationMin * 60;
  }
}

/// A session broken into what a search actually has to look for.
///
/// The point of the split (Feature 011): the ground a search must find is
/// not the distance the rider covers. Four efforts on one hill ride four
/// times the hill and need it once. Cost follows the distinct stimuli, not
/// the repetitions and not the area.
class WorkoutDemand {
  final List<StimulusDemand> stimuli;
  final CyclingPowerModel model;

  const WorkoutDemand({required this.stimuli, required this.model});

  /// Groups the plan by what makes two stimuli the same instruction, keeping
  /// first-appearance order so the timeline still reads in order.
  factory WorkoutDemand.of(List<WorkoutBlockGroup> plan, RiderProfile rider) {
    final model = CyclingPowerModel(rider);
    final order = <String>[];
    final counts = <String, int>{};
    final blocks = <String, WorkoutBlock>{};

    for (final group in plan) {
      for (final stimulus in group.stimuli) {
        final key = _keyOf(stimulus);
        if (!counts.containsKey(key)) {
          order.add(key);
          blocks[key] = stimulus;
          counts[key] = 0;
        }
        // A group repeated N times asks for each of its stimuli N times.
        counts[key] = counts[key]! + group.repeatCount;
      }
    }

    return WorkoutDemand(
      model: model,
      stimuli: [
        for (final key in order)
          StimulusDemand(
            block: blocks[key]!,
            repetitions: counts[key]!,
            targetWatts: _targetWattsFor(blocks[key]!, rider),
          ),
      ],
    );
  }

  /// Two stimuli are the same instruction when a rider would not tell them
  /// apart on the road: same metric, zone, target band and duration.
  static String _keyOf(WorkoutBlock b) => [
        b.target.metric.name,
        b.zone.scale.name,
        b.zone.index,
        b.target.minValue,
        b.target.maxValue,
        b.durationMin,
        b.role.name,
      ].join('|');

  static int _targetWattsFor(WorkoutBlock block, RiderProfile rider) {
    if (block.target.metric == ZoneMetric.power) {
      return ((block.target.minValue + block.target.maxValue) / 2).round();
    }
    // Heart rate is matched on the power table's equivalent band at the same
    // zone index: the two tables are independent, and treating a bpm number
    // as a watt number would be worse than saying so.
    final bounds = rider.powerZones.customLowerBoundsWatts ??
        rider.powerZones.derivedBounds(rider.ftpWatts);
    final index = block.zone.index.clamp(1, bounds.length);
    final lower = bounds[index - 1];
    final upper = upperBoundFrom(bounds, index) ?? (lower * 1.15).round();
    return ((lower + upper) / 2).round();
  }

  /// What the rider covers: every repetition of every stimulus.
  double get riddenDistanceM => stimuli.fold(
      0.0, (sum, s) => sum + s.distancePerRepetitionM(model) * s.repetitions);

  /// Ground the search has to find, which is the number that sizes it.
  ///
  /// With repetitions reused this is one stretch per distinct stimulus. It
  /// is what makes a 4x5min session cost the same to search as a 1x5min
  /// one, and it is far smaller than [riddenDistanceM] for interval work.
  double terrainNeededM(RepetitionShape shape) => stimuli.fold(0.0, (sum, s) {
        final once = s.distancePerRepetitionM(model);
        return sum +
            switch (shape) {
              // Up and back covers the stretch twice per repetition, but the
              // stretch itself is found once.
              RepetitionShape.outAndBack => once,
              RepetitionShape.loop => once * 1.6,
              RepetitionShape.distinctStretches => once * s.repetitions,
            };
      });

  /// Radius to fetch around the start, for a search that has not begun.
  ///
  /// Half the ground needed, because an out-and-back reaches half as far as
  /// it rides, plus a margin for the roads not running where the rider wants
  /// to go. Bounded below so a short session still has somewhere to look.
  double searchRadiusM(RepetitionShape shape) =>
      math.max(3000, terrainNeededM(shape) / 2 * 1.6);

  int get distinctStimuli => stimuli.length;

  int get totalRepetitions => stimuli.fold(0, (sum, s) => sum + s.repetitions);
}
