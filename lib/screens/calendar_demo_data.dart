import '../models/calendar_entry.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';

/// Demo calendar data for screens 08a-08c until the calendar is backed by
/// a real plan/history store. Keyed by calendar day (time stripped).
///
/// Built against the rider's own profile rather than a fixed table. Zones are
/// resolved from the prescribed watts through `RiderProfile.zoneFor`, so a
/// rider on Z1-Z5 sees their five zones and one on Z1-Z7 sees seven - the
/// zone number for a given effort genuinely differs between the two tables,
/// and hardcoding an index made the calendar contradict the profile.
///
/// One caveat for the real store that replaces this: a *completed* entry
/// keeps the scale it was recorded against, because a stored zone carries its
/// own metric and scale (DECISIONS_REQUIRED.md, "already decided") and
/// re-labelling finished rides when the rider changes tables would rewrite
/// history. Only the plan follows the current profile.
Map<DateTime, CalendarEntry> demoCalendarEntriesFor(RiderProfile rider) {
  TrainingZone zoneForWatts(int watts) =>
      // Power always resolves: the table is anchored on FTP, which every
      // profile has. Heart rate is the metric that can be unresolvable.
      rider.zoneFor(watts, ZoneMetric.power)!;

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
        zone: zoneForWatts((minWatts + maxWatts) ~/ 2),
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
    DateTime(2026, 7, 21): CalendarEntry(
      date: DateTime(2026, 7, 21),
      completed: CompletedSummary(
        routeName: 'Circuito do parque',
        targetWatts: 150,
        realizedWatts: 142,
        durationMin: 58,
        source: ResultSource.garmin,
        zone: zoneForWatts(142),
      ),
    ),
  };
}

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);
