import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';
import '../models/workout_block.dart';
import '../l10n/domain_labels.dart';
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
    final t = tr(context);
    final entry = this.entry;
    if (entry == null || !entry.hasWorkout) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(t.calendarRestDay, style: AppTextStyles.label),
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
                  child: Text(t.calendarDone,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 8,
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Text(t.calendarVia(c.source.label(t)),
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
                        label: t.calendarActual,
                        value: '${c.realizedWatts}w',
                        valueColor: AppColors.greenText)),
                const SizedBox(width: 8),
                Expanded(
                    child: StatBox(
                        label: t.calendarPlanned, value: '${c.targetWatts}w')),
                const SizedBox(width: 8),
                Expanded(
                    child: StatBox(
                        label: t.calendarDuration, value: '${c.durationMin}m')),
              ],
            ),
          ],
        ),
      );
    }

    final blocks = entry.planned!;
    // The pill shows the hardest zone in the sequence - what the day is for.
    final first = blocks.reduce((a, b) => b.zone.index > a.zone.index ? b : a);
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
            t.calendarWorkoutSummary(blocks.length, workoutDurationMin(blocks)),
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}
