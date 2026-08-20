import 'workout_block.dart';

/// What is planned for one day.
///
/// Only the plan: whether the day is done is not stored here but read from
/// the activity linked to it. Keeping the result out of the entry is what
/// makes associating and disassociating possible at all - a day that used to
/// hold its own completed summary had nowhere to put the plan back when the
/// rider unlinked the ride.
class CalendarEntry {
  final DateTime date;
  final List<WorkoutBlock> planned;

  CalendarEntry({
    required this.date,
    required this.planned,
  }) : assert(planned.isNotEmpty, 'A planned day needs at least one block.');

  bool get hasWorkout => planned.isNotEmpty;
}
