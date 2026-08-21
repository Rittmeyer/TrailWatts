import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/engine/workout_demand.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';

const rider = RiderProfile(weightKg: 74, ftpWatts: 210);

WorkoutBlock stimulus(
        WorkoutBlockRole role, int minutes, int zone, int minW, int maxW,
        {ZoneMetric metric = ZoneMetric.power}) =>
    WorkoutBlock(
      zone: TrainingZone(metric: metric, scale: ZoneScale.five, index: zone),
      durationMin: minutes,
      role: role,
      target: WorkoutTarget(metric: metric, minValue: minW, maxValue: maxW),
    );

/// 4x(5min Z4 + 3min Z1), after a warm-up. Eight work/recovery steps, two
/// distinct instructions.
List<WorkoutBlockGroup> intervals() => [
      WorkoutBlockGroup(
          stimuli: [stimulus(WorkoutBlockRole.warmUp, 10, 2, 110, 140)]),
      WorkoutBlockGroup(
        stimuli: [
          stimulus(WorkoutBlockRole.work, 5, 4, 220, 245),
          stimulus(WorkoutBlockRole.recovery, 3, 1, 90, 120),
        ],
        repeatCount: 4,
      ),
    ];

void main() {
  group('a session is a handful of instructions, not a list of steps', () {
    test('repeats collapse into one demand each', () {
      final demand = WorkoutDemand.of(intervals(), rider);

      expect(demand.distinctStimuli, 3,
          reason: 'warm-up, the effort, and the recovery');
      expect(demand.totalRepetitions, 1 + 4 + 4);

      final work = demand.stimuli.firstWhere((s) => s.isWork);
      expect(work.repetitions, 4,
          reason: 'the repeat count used to be flattened away before the '
              'search, so four efforts became four terrain hunts');
    });

    test('the same instruction written twice is one demand', () {
      final plan = [
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 5, 4, 220, 245)]),
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 5, 4, 220, 245)]),
      ];
      final demand = WorkoutDemand.of(plan, rider);

      expect(demand.distinctStimuli, 1);
      expect(demand.stimuli.single.repetitions, 2);
    });

    test('same zone, different duration, is a different instruction', () {
      final plan = [
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 5, 4, 220, 245)]),
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 8, 4, 220, 245)]),
      ];
      expect(WorkoutDemand.of(plan, rider).distinctStimuli, 2);
    });

    test('order of first appearance is kept', () {
      final demand = WorkoutDemand.of(intervals(), rider);
      expect(demand.stimuli.first.block.role, WorkoutBlockRole.warmUp);
    });
  });

  group('distance estimated from the workout, before any map', () {
    test('a 5-minute effort at threshold is a few kilometres', () {
      final demand = WorkoutDemand.of(intervals(), rider);
      final work = demand.stimuli.firstWhere((s) => s.isWork);
      final km = work.distancePerRepetitionM(demand.model) / 1000;

      // ~230 W on the flat is low-to-mid 30s km/h, so five minutes is
      // around three kilometres.
      expect(km, inInclusiveRange(2.2, 3.5), reason: '${km}km');
    });

    test('a harder target covers more ground in the same time', () {
      final easy = WorkoutDemand.of([
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 5, 2, 120, 140)])
      ], rider);
      final hard = WorkoutDemand.of([
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 5, 5, 300, 340)])
      ], rider);

      expect(hard.riddenDistanceM, greaterThan(easy.riddenDistanceM));
    });

    test('a heart-rate stimulus is sized on its equivalent watts', () {
      final demand = WorkoutDemand.of([
        WorkoutBlockGroup(stimuli: [
          stimulus(WorkoutBlockRole.work, 5, 4, 150, 165,
              metric: ZoneMetric.heartRate)
        ])
      ], rider);

      // Not 157 W: the bpm band is not a watt band.
      expect(demand.stimuli.single.targetWatts, greaterThan(180));
    });
  });

  group('what the search has to find is not what the rider covers', () {
    test('four efforts on one hill need the hill once', () {
      final demand = WorkoutDemand.of(intervals(), rider);

      final ridden = demand.riddenDistanceM;
      final needed = demand.terrainNeededM(RepetitionShape.outAndBack);

      expect(needed, lessThan(ridden / 2),
          reason: 'ridden ${(ridden / 1000).toStringAsFixed(1)}km vs '
              'terrain ${(needed / 1000).toStringAsFixed(1)}km - this ratio '
              'is the whole optimisation');
    });

    test('a different stretch per effort needs all of them', () {
      final demand = WorkoutDemand.of(intervals(), rider);

      expect(demand.terrainNeededM(RepetitionShape.distinctStretches),
          greaterThan(demand.terrainNeededM(RepetitionShape.outAndBack)));
    });

    test('a long continuous ride needs every metre it covers', () {
      // 200 km of endurance: one stimulus, one repetition.
      final demand = WorkoutDemand.of([
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 480, 2, 150, 175)])
      ], rider);

      expect(demand.terrainNeededM(RepetitionShape.outAndBack),
          closeTo(demand.riddenDistanceM, 1),
          reason: 'nothing to reuse when nothing repeats');
      expect(demand.riddenDistanceM / 1000, greaterThan(150));
    });

    test('the radius follows the session instead of being a fixed number', () {
      final short = WorkoutDemand.of(intervals(), rider);
      final long = WorkoutDemand.of([
        WorkoutBlockGroup(
            stimuli: [stimulus(WorkoutBlockRole.work, 480, 2, 150, 175)])
      ], rider);

      expect(long.searchRadiusM(RepetitionShape.outAndBack),
          greaterThan(short.searchRadiusM(RepetitionShape.outAndBack) * 5));
      expect(short.searchRadiusM(RepetitionShape.outAndBack),
          greaterThanOrEqualTo(3000),
          reason: 'a short session still needs somewhere to look');
    });
  });
}
