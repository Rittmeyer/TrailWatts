import '../models/calendar_entry.dart';
import '../models/result_source.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';

/// Demo calendar data for screens 08a-08c until the calendar is backed by
/// a real plan/history store. Keyed by calendar day (time stripped).
final demoCalendarEntries = <DateTime, CalendarEntry>{
  DateTime(2026, 7, 20): CalendarEntry(
    date: DateTime(2026, 7, 20),
    planned: const [
      WorkoutBlock(
        zone: Zone.limiar,
        durationMin: 8,
        repetitions: 4,
        target: WorkoutTarget(
            metric: WorkoutTargetMetric.watts, minValue: 170, maxValue: 190),
        recoveryDurationMin: 2,
        recoveryZone: Zone.recuperacao,
        recoveryTarget: WorkoutTarget(
            metric: WorkoutTargetMetric.watts, minValue: 90, maxValue: 110),
      ),
    ],
  ),
  DateTime(2026, 7, 21): CalendarEntry(
    date: DateTime(2026, 7, 21),
    completed: const CompletedSummary(
      routeName: 'Circuito do parque',
      targetWatts: 150,
      realizedWatts: 142,
      durationMin: 58,
      source: ResultSource.garmin,
      zone: Zone.resistencia,
    ),
  ),
};

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);
