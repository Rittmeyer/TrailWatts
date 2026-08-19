import 'result_source.dart';

/// One normalized completed-activity result used by history and calibration.
class HistoryEntry {
  final DateTime date;
  final String routeName;
  final int targetWatts;
  final int realizedWatts;
  final int targetDurationMin;
  final int realizedDurationMin;
  final ResultSource source;

  const HistoryEntry({
    required this.date,
    required this.routeName,
    required this.targetWatts,
    required this.realizedWatts,
    required this.targetDurationMin,
    required this.realizedDurationMin,
    required this.source,
  });

  int get deltaWatts => realizedWatts - targetWatts;
  int get deltaDurationMin => realizedDurationMin - targetDurationMin;
}
