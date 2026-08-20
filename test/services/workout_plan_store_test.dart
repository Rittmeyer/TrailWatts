import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/rider_profile_store.dart';
import 'package:trailwatt/services/workout_plan_store.dart';

/// The demo plan has a planned day and a completed one.
final _plannedDay = DateTime(2026, 7, 20);
final _completedDay = DateTime(2026, 7, 21);
final _emptyDay = DateTime(2026, 7, 22);

WorkoutBlock _block(
        {int min = 200, int max = 220, int minutes = 10, int zone = 4}) =>
    WorkoutBlock(
      zone: TrainingZone(
          metric: ZoneMetric.power, scale: ZoneScale.seven, index: zone),
      durationMin: minutes,
      target:
          WorkoutTarget(metric: ZoneMetric.power, minValue: min, maxValue: max),
    );

void main() {
  late WorkoutPlanStore store;

  setUp(() => store = WorkoutPlanStore(profiles: RiderProfileStore()));

  group('what a day allows', () {
    test('a planned day can be changed', () {
      expect(store.hasWorkout(_plannedDay), isTrue);
      expect(store.isEditable(_plannedDay), isTrue);
    });

    test('an empty day has nothing but can be filled', () {
      expect(store.hasWorkout(_emptyDay), isFalse);
      expect(store.isEditable(_emptyDay), isTrue);
    });

    test('a completed day is a record, not a plan', () {
      expect(store.hasWorkout(_completedDay), isTrue);
      expect(store.isEditable(_completedDay), isFalse);
    });

    test('the time of day never decides which entry a date finds', () {
      // Calendar widgets hand back a DateTime with a time on it.
      final withTime = DateTime(2026, 7, 20, 17, 45);
      expect(store.entryFor(withTime), isNotNull);
    });
  });

  group('scheduling a workout', () {
    test('fills an empty day and notifies', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.savePlanned(_emptyDay, [_block()]);

      expect(store.entryFor(_emptyDay)?.planned, hasLength(1));
      expect(notifications, 1);
    });

    test('replaces what was planned rather than appending to it', () {
      store.savePlanned(_plannedDay, [_block(minutes: 42)]);

      final planned = store.entryFor(_plannedDay)!.planned!;
      expect(planned, hasLength(1));
      expect(planned.single.durationMin, 42);
    });

    test('saving nothing clears the day instead of leaving it empty', () {
      // CalendarEntry requires exactly one of planned/completed, so a day
      // with an empty block list could not be represented at all.
      store.savePlanned(_plannedDay, const []);
      expect(store.entryFor(_plannedDay), isNull);
    });

    test('a completed day refuses to be re-planned', () {
      expect(() => store.savePlanned(_completedDay, [_block()]),
          throwsA(isA<StateError>()));
      expect(store.entryFor(_completedDay)!.isDone, isTrue);
    });
  });

  group('removing a workout', () {
    test('drops the day and notifies', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.removePlanned(_plannedDay);

      expect(store.hasWorkout(_plannedDay), isFalse);
      expect(notifications, 1);
    });

    test('removing a day with nothing on it changes nothing', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.removePlanned(_emptyDay);

      expect(notifications, 0, reason: 'nothing changed, so nothing to report');
    });

    test('a completed day refuses to be removed', () {
      expect(
          () => store.removePlanned(_completedDay), throwsA(isA<StateError>()));
      expect(store.hasWorkout(_completedDay), isTrue);
    });
  });

  group('the plan follows the rider\'s zone table', () {
    test('switching to five zones relabels the plan, keeping the watts', () {
      final profiles = RiderProfileStore();
      final store = WorkoutPlanStore(profiles: profiles);
      // An anaerobic block, which only the seven-zone table has a number
      // for: the five-zone table collapses Coggan's Z5/Z6/Z7 into its top
      // zone, so Z6 has to land on Z5 there.
      store.savePlanned(_emptyDay, [_block(min: 270, max: 290, zone: 6)]);
      expect(store.entryFor(_emptyDay)!.planned!.single.zone.index, 6);

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      final block = store.entryFor(_emptyDay)!.planned!.single;
      expect(block.zone.index, 5);
      expect(block.zone.scale, ZoneScale.five);
      expect(block.target.minValue, 270,
          reason: 'the prescription did not change, only what to call it');
    });

    test('a zone the new table still has keeps its number', () {
      final profiles = RiderProfileStore();
      final store = WorkoutPlanStore(profiles: profiles);
      store.savePlanned(_emptyDay, [_block(zone: 3)]);

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      // Both tables have a Z3, so the rider's choice survives untouched.
      expect(store.entryFor(_emptyDay)!.planned!.single.zone.index, 3);
    });

    test('a completed day keeps the scale it was recorded against', () {
      final profiles = RiderProfileStore();
      final store = WorkoutPlanStore(profiles: profiles);
      final before = store.entryFor(_completedDay)!.completed!.zone;

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      // Re-labelling a finished ride would rewrite what happened.
      expect(store.entryFor(_completedDay)!.completed!.zone, before);
    });
  });
}
