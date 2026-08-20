import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';
import '../models/result_source.dart';
import '../models/workout_block.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'stat_box.dart';
import 'zone_pill.dart';

/// The panel shown below the day/week strip on screens 08a-08c: the plan
/// for a day not yet ridden, or the completed summary for one that is.
/// Same space, different content - never both at once.
class CalendarDayDetail extends StatelessWidget {
  final CalendarEntry? entry;

  const CalendarDayDetail({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry == null || !entry.hasWorkout) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Dia de descanso - sem treino planejado.',
            style: AppTextStyles.label),
      );
    }

    if (entry.isDone) {
      final c = entry.completed!;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('CONCLUIDO',
                      style: AppTextStyles.label.copyWith(
                          fontSize: 8,
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Text('via ${_sourceLabel(c.source)}',
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
              ],
            ),
            const SizedBox(height: 8),
            Text(c.routeName,
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: StatBox(
                        label: 'REAL',
                        value: '${c.realizedWatts}w',
                        valueColor: AppColors.greenText)),
                const SizedBox(width: 8),
                Expanded(
                    child: StatBox(label: 'ALVO', value: '${c.targetWatts}w')),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        StatBox(label: 'DURACAO', value: '${c.durationMin}m')),
              ],
            ),
          ],
        ),
      );
    }

    final blocks = entry.planned!;
    final first = blocks.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZonePill(zone: first.zone),
          const SizedBox(height: 8),
          Text('Subida da Serra',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            () {
              final unit = first.target.metric == WorkoutTargetMetric.watts
                  ? 'w'
                  : 'bpm';
              final reps = first.isRepeated ? '${first.repetitions}x' : '';
              return '$reps${first.durationMin}min a '
                  '${first.target.minValue}-${first.target.maxValue}$unit';
            }(),
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }

  String _sourceLabel(ResultSource s) => switch (s) {
        ResultSource.strava => 'Strava',
        ResultSource.garmin => 'Garmin',
        ResultSource.wahoo => 'Wahoo',
        ResultSource.manual => 'entrada manual',
      };
}
