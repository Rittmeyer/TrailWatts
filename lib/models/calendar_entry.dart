import 'workout_block.dart';
import 'zone.dart';
import 'result_source.dart';

class CalendarEntry {
  final DateTime date;
  final List<WorkoutBlock>? planned;
  final CompletedSummary? completed;

  const CalendarEntry({
    required this.date,
    this.planned,
    this.completed,
  }) : assert(
          (planned != null) != (completed != null),
          'Exactly one of planned or completed must be set.',
        );

  bool get isDone => completed != null;
  bool get hasWorkout => planned != null || completed != null;
}

class CompletedSummary {
  final String routeName;
  final int targetWatts;
  final int realizedWatts;
  final int durationMin;
  final ResultSource source;
  final TrainingZone zone;

  const CompletedSummary({
    required this.routeName,
    required this.targetWatts,
    required this.realizedWatts,
    required this.durationMin,
    required this.source,
    required this.zone,
  });
}
