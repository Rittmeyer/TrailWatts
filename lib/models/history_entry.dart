import 'result_source.dart';
import 'zone.dart';

/// One normalized completed activity, used by history, by the calendar and
/// by calibration.
///
/// This is the single type for "a ride that happened". The calendar does not
/// keep its own copy of one: a day reads as done because an activity points
/// at it, so associating and disassociating is one field changing in one
/// place rather than two records to keep in step.
class HistoryEntry {
  /// Stable identity, so an activity can be linked and unlinked without
  /// being confused with another ride on the same day.
  final String id;

  final DateTime date;
  final String routeName;
  final int targetWatts;
  final int realizedWatts;
  final int targetDurationMin;
  final int realizedDurationMin;
  final ResultSource source;

  /// The planned day this activity is the result of, or null while it is
  /// just a ride the rider did.
  ///
  /// Null is a real state, not a missing value: an activity that matches no
  /// plan is still an activity, and Feature 002 is explicit that a candidate
  /// is never silently written as a workout's result - the rider links it.
  final DateTime? linkedDay;

  /// The zone this activity was recorded against, when one was recorded.
  ///
  /// Null is not "no zone" - it means nothing was stored with the activity,
  /// so the zone has to be resolved against the rider's current table at
  /// display time. When a zone *is* stored it wins, because it carries its
  /// own metric and scale: a ride recorded on a seven-zone table stays a
  /// seven-zone ride even after the rider switches to five, and re-labelling
  /// it later would rewrite what actually happened.
  final TrainingZone? zone;

  const HistoryEntry({
    required this.id,
    required this.date,
    required this.routeName,
    required this.targetWatts,
    required this.realizedWatts,
    required this.targetDurationMin,
    required this.realizedDurationMin,
    required this.source,
    this.linkedDay,
    this.zone,
  });

  bool get isLinked => linkedDay != null;

  int get deltaWatts => realizedWatts - targetWatts;
  int get deltaDurationMin => realizedDurationMin - targetDurationMin;

  /// [linkedDay] is passed explicitly so that clearing it is expressible -
  /// a plain optional parameter cannot tell "leave it" from "set to null".
  HistoryEntry copyWith({
    String? routeName,
    int? targetWatts,
    int? realizedWatts,
    TrainingZone? zone,
    Object? linkedDay = _unset,
  }) =>
      HistoryEntry(
        id: id,
        date: date,
        routeName: routeName ?? this.routeName,
        targetWatts: targetWatts ?? this.targetWatts,
        realizedWatts: realizedWatts ?? this.realizedWatts,
        targetDurationMin: targetDurationMin,
        realizedDurationMin: realizedDurationMin,
        source: source,
        linkedDay:
            linkedDay == _unset ? this.linkedDay : linkedDay as DateTime?,
        zone: zone ?? this.zone,
      );
}

const _unset = Object();
