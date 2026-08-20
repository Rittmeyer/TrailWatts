import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/services/activity_store.dart';
import 'package:trailwatt/services/rider_profile_store.dart';
import 'package:trailwatt/services/workout_plan_store.dart';

/// The demo plan has a plain planned day and one whose result is already
/// recorded by a linked activity.
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

WorkoutPlanStore _freshStore({RiderProfileStore? profiles}) => WorkoutPlanStore(
      profiles: profiles ?? RiderProfileStore(),
      activities: ActivityStore(),
    );

void main() {
  late WorkoutPlanStore store;

  setUp(() => store = _freshStore());

  group('what a day allows', () {
    test('a planned day can be changed', () {
      expect(store.hasWorkout(_plannedDay), isTrue);
      expect(store.isEditable(_plannedDay), isTrue);
    });

    test('an empty day has nothing but can be filled', () {
      expect(store.hasWorkout(_emptyDay), isFalse);
      expect(store.isEditable(_emptyDay), isTrue);
    });

    test('a day whose result is recorded is not the rider\'s to re-plan', () {
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

      final planned = store.entryFor(_plannedDay)!.planned;
      expect(planned, hasLength(1));
      expect(planned.single.durationMin, 42);
    });

    test('saving nothing clears the day instead of leaving it empty', () {
      // CalendarEntry requires exactly one of planned/completed, so a day
      // with an empty block list could not be represented at all.
      store.savePlanned(_plannedDay, const []);
      expect(store.entryFor(_plannedDay), isNull);
    });

    test('a day with a recorded result refuses to be re-planned', () {
      expect(() => store.savePlanned(_completedDay, [_block()]),
          throwsA(isA<StateError>()));
      // The plan the ride was measured against is untouched.
      expect(store.entryFor(_completedDay)!.planned, hasLength(1));
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

    test('a day with a recorded result refuses to be removed', () {
      expect(
          () => store.removePlanned(_completedDay), throwsA(isA<StateError>()));
      expect(store.hasWorkout(_completedDay), isTrue);
    });

    test('unlinking the ride hands the day back', () {
      final activities = ActivityStore();
      final store = WorkoutPlanStore(
          profiles: RiderProfileStore(), activities: activities);
      expect(store.isEditable(_completedDay), isFalse);

      activities.unlink(activities.linkedTo(_completedDay)!.id);

      expect(store.isEditable(_completedDay), isTrue);
      store.removePlanned(_completedDay);
      expect(store.hasWorkout(_completedDay), isFalse);
    });
  });

  group('the plan follows the rider\'s zone table', () {
    test('switching to five zones relabels the plan, keeping the watts', () {
      final profiles = RiderProfileStore();
      final store = _freshStore(profiles: profiles);
      // An anaerobic block, which only the seven-zone table has a number
      // for: the five-zone table collapses Coggan's Z5/Z6/Z7 into its top
      // zone, so Z6 has to land on Z5 there.
      store.savePlanned(_emptyDay, [_block(min: 270, max: 290, zone: 6)]);
      expect(store.entryFor(_emptyDay)!.planned.single.zone.index, 6);

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      final block = store.entryFor(_emptyDay)!.planned.single;
      expect(block.zone.index, 5);
      expect(block.zone.scale, ZoneScale.five);
      expect(block.target.minValue, 270,
          reason: 'the prescription did not change, only what to call it');
    });

    test('a zone the new table still has keeps its number', () {
      final profiles = RiderProfileStore();
      final store = _freshStore(profiles: profiles);
      store.savePlanned(_emptyDay, [_block(zone: 3)]);

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      // Both tables have a Z3, so the rider's choice survives untouched.
      expect(store.entryFor(_emptyDay)!.planned.single.zone.index, 3);
    });

    test('a recorded activity is not touched by a table change', () {
      final profiles = RiderProfileStore();
      final activities = ActivityStore();
      WorkoutPlanStore(profiles: profiles, activities: activities);
      final before = activities.linkedTo(_completedDay)!;

      profiles.save(const RiderProfile(
        weightKg: 74,
        ftpWatts: 210,
        powerZones: PowerZoneSettings(scale: ZoneScale.five),
      ));

      // A ride that happened is a record; only the plan follows the table.
      final after = activities.linkedTo(_completedDay)!;
      expect(after.realizedWatts, before.realizedWatts);
      expect(after.zone, before.zone);
    });
  });
}
