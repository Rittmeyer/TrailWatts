import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/calendar_entry.dart';
import '../models/history_entry.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'stat_box.dart';
import 'trailwatt_button.dart';
import 'zone_pill.dart';

/// The panel shown below the day/week strip on screens 08a-08c.
///
/// A day can hold a plan, a result, or both - and both is the interesting
/// case, because "previsto vs. realizado" is what the calibration loop is
/// built on (Constitution Article VI). The panel shows the result on top of
/// the plan it was measured against, rather than replacing one with the
/// other.
///
/// Selecting a day is also how the rider changes it. A day still ahead
/// offers add, edit and remove; one whose result is recorded offers only to
/// unlink that result, which hands the day back.
class CalendarDayDetail extends StatelessWidget {
  final CalendarEntry? entry;

  /// The activity recorded as this day's result, if the rider linked one.
  final HistoryEntry? activity;

  /// The zone [activity] is named in, resolved by the caller against the
  /// rider's table - this widget renders, it does not decide zones.
  final TrainingZone? activityZone;

  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  /// Record an activity as this day's result.
  final VoidCallback? onLink;

  /// Take the recorded result off this day.
  final VoidCallback? onUnlink;

  const CalendarDayDetail({
    super.key,
    required this.entry,
    this.activity,
    this.activityZone,
    this.onAdd,
    this.onEdit,
    this.onRemove,
    this.onLink,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final entry = this.entry;
    final activity = this.activity;

    if (entry == null && activity == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.calendarRestDay, style: AppTextStyles.label),
            if (onAdd != null) ...[
              const SizedBox(height: 12),
              TrailwattButton(
                label: t.calendarAddWorkout,
                style: TrailwattButtonStyle.dashed,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      );
    }

    return _Card(
      accent: activity != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity != null) ..._result(context, t, activity),
          if (entry != null && activity != null) const SizedBox(height: 14),
          if (entry != null)
            ..._plan(context, t, entry, muted: activity != null),
          const SizedBox(height: 12),
          _actions(t),
        ],
      ),
    );
  }

  List<Widget> _result(
          BuildContext context, AppLocalizations t, HistoryEntry activity) =>
      [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            Text(t.calendarVia(activity.source.label(t)),
                style: AppTextStyles.label.copyWith(fontSize: 9)),
          ],
        ),
        const SizedBox(height: 8),
        if (activityZone != null) ...[
          ZonePill(zone: activityZone!),
          const SizedBox(height: 8),
        ],
        Text(activity.routeName,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: StatBox(
                    label: t.calendarActual,
                    value: '${activity.realizedWatts}w',
                    valueColor: AppColors.greenText)),
            const SizedBox(width: 8),
            Expanded(
                child: StatBox(
                    label: t.calendarPlanned,
                    value: '${activity.targetWatts}w')),
            const SizedBox(width: 8),
            Expanded(
                child: StatBox(
                    label: t.calendarDuration,
                    value: '${activity.realizedDurationMin}m')),
          ],
        ),
      ];

  List<Widget> _plan(
      BuildContext context, AppLocalizations t, CalendarEntry entry,
      {required bool muted}) {
    final blocks = entry.planned;
    // The pill shows the hardest zone in the sequence - what the day is for.
    final hardest =
        blocks.reduce((a, b) => b.zone.index > a.zone.index ? b : a);
    return [
      if (muted)
        Text(t.calendarPlannedWorkout,
            style: AppTextStyles.label.copyWith(
                fontSize: 8, letterSpacing: 1.0, fontWeight: FontWeight.w800)),
      if (muted) const SizedBox(height: 6),
      ZonePill(zone: hardest.zone),
      const SizedBox(height: 8),
      Text('Subida da Serra',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(
        t.calendarWorkoutSummary(blocks.length, workoutDurationMin(blocks)),
        style: AppTextStyles.label,
      ),
    ];
  }

  Widget _actions(AppLocalizations t) {
    final buttons = <Widget>[
      if (onEdit != null) _action(t.calendarEditWorkout, onEdit!),
      if (onRemove != null) _action(t.calendarRemoveWorkout, onRemove!),
      if (onLink != null) _action(t.calendarLinkActivity, onLink!),
      if (onUnlink != null) _action(t.calendarUnlinkActivity, onUnlink!),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _action(String label, VoidCallback onPressed) => TrailwattButton(
        label: label,
        style: TrailwattButtonStyle.secondary,
        onPressed: onPressed,
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool accent;

  const _Card({required this.child, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: accent ? AppColors.accent : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
}
