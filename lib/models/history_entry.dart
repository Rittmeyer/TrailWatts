import 'result_source.dart';
import 'zone.dart';

/// One normalized completed-activity result used by history and calibration.
class HistoryEntry {
  final DateTime date;
  final String routeName;
  final int targetWatts;
  final int realizedWatts;
  final int targetDurationMin;
  final int realizedDurationMin;
  final ResultSource source;

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
    required this.date,
    required this.routeName,
    required this.targetWatts,
    required this.realizedWatts,
    required this.targetDurationMin,
    required this.realizedDurationMin,
    required this.source,
    this.zone,
  });

  int get deltaWatts => realizedWatts - targetWatts;
  int get deltaDurationMin => realizedDurationMin - targetDurationMin;
}
