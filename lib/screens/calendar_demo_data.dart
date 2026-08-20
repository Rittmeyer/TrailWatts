import '../models/calendar_entry.dart';
import '../models/history_entry.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';

/// Demo plan and activities until a real store backs them. Keyed by calendar
/// day (time stripped) for the plan.
///
/// Built against the rider's own profile rather than a fixed table. Zones are
/// resolved from the prescribed watts through `RiderProfile.zoneFor`, so a
/// rider on Z1-Z5 sees their five zones and one on Z1-Z7 sees seven - the
/// zone number for a given effort genuinely differs between the two tables,
/// and hardcoding an index made the calendar contradict the profile.
Map<DateTime, CalendarEntry> demoCalendarEntriesFor(RiderProfile rider) {
  WorkoutBlock block({
    required int minWatts,
    required int maxWatts,
    required int durationMin,
    WorkoutBlockRole role = WorkoutBlockRole.work,
  }) =>
      WorkoutBlock(
        role: role,
        // The middle of the range is the effort being asked for; an edge
        // would land on a neighbouring zone whenever the range straddles a
        // boundary.
        zone: rider.zoneFor((minWatts + maxWatts) ~/ 2, ZoneMetric.power)!,
        durationMin: durationMin,
        target: WorkoutTarget(
          metric: ZoneMetric.power,
          minValue: minWatts,
          maxValue: maxWatts,
        ),
      );

  return {
    DateTime(2026, 7, 20): CalendarEntry(
      date: DateTime(2026, 7, 20),
      planned: [
        block(minWatts: 170, maxWatts: 190, durationMin: 8),
        block(
          minWatts: 90,
          maxWatts: 110,
          durationMin: 2,
          role: WorkoutBlockRole.recovery,
        ),
      ],
    ),
    // Already ridden: the plan stays here, and the activity below points at
    // this day. Unlinking the ride leaves this plan behind rather than
    // emptying the day.
    DateTime(2026, 7, 21): CalendarEntry(
      date: DateTime(2026, 7, 21),
      planned: [block(minWatts: 140, maxWatts: 160, durationMin: 58)],
    ),
  };
}

/// The rider's completed activities. One is already linked to its planned
/// day; the others are rides that match no plan yet, which is what the
/// rider associates by hand.
///
/// A recorded zone is deliberately absent here: nothing was stored with
/// these, so each is named on the rider's current table at display time.
List<HistoryEntry> demoActivities() => [
      HistoryEntry(
        id: 'activity-serra',
        date: DateTime(2026, 7, 14),
        routeName: 'Subida da Serra',
        targetWatts: 180,
        realizedWatts: 178,
        targetDurationMin: 32,
        realizedDurationMin: 33,
        source: ResultSource.strava,
      ),
      HistoryEntry(
        id: 'activity-parque',
        date: DateTime(2026, 7, 21),
        routeName: 'Circuito do parque',
        targetWatts: 150,
        realizedWatts: 142,
        targetDurationMin: 60,
        realizedDurationMin: 58,
        source: ResultSource.garmin,
        linkedDay: DateTime(2026, 7, 21),
      ),
      HistoryEntry(
        id: 'activity-indoor',
        date: DateTime(2026, 7, 10),
        routeName: 'Treino indoor',
        targetWatts: 240,
        realizedWatts: 241,
        targetDurationMin: 20,
        realizedDurationMin: 20,
        source: ResultSource.manual,
      ),
    ];

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);
