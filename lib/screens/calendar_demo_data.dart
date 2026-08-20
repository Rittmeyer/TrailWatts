import '../models/calendar_entry.dart';
import '../models/result_source.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';

/// Demo calendar data for screens 08a-08c until the calendar is backed by
/// a real plan/history store. Keyed by calendar day (time stripped).
///
/// The demo rider runs the default pairing: seven power zones, five
/// heart-rate zones. The blocks below are prescribed in watts, so they
/// reference the power table.
const _powerZones = ZoneScale.seven;

final demoCalendarEntries = <DateTime, CalendarEntry>{
  DateTime(2026, 7, 20): CalendarEntry(
    date: DateTime(2026, 7, 20),
    planned: [
      WorkoutBlock(
        zone: const TrainingZone(
            metric: ZoneMetric.power, scale: _powerZones, index: 4),
        durationMin: 8,
        repetitions: 4,
        target: const WorkoutTarget(
            metric: ZoneMetric.power, minValue: 170, maxValue: 190),
        recoveryDurationMin: 2,
        recoveryZone: const TrainingZone(
            metric: ZoneMetric.power, scale: _powerZones, index: 1),
        recoveryTarget: const WorkoutTarget(
            metric: ZoneMetric.power, minValue: 90, maxValue: 110),
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
      zone:
          TrainingZone(metric: ZoneMetric.power, scale: _powerZones, index: 2),
    ),
  ),
};

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);
