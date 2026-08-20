import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../services/workout_plan_store.dart';
import '../theme/app_text_styles.dart';
import 'calendar_day_detail.dart';

/// The day panel wired to the plan: shows the selected day and offers the
/// actions that day allows.
///
/// Both calendar screens use it, so week and month behave identically -
/// selecting a day is the one way to change it, and neither view invents
/// its own rules about when that is allowed.
class CalendarDayActions extends StatelessWidget {
  final DateTime day;

  const CalendarDayActions({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final store = WorkoutPlanStore.instance;
    final entry = store.entryFor(day);
    // A completed day is a record of a ride: nothing to add, edit or drop.
    final editable = store.isEditable(day);

    return CalendarDayDetail(
      entry: entry,
      onAdd: editable && !store.hasWorkout(day)
          ? () => _openBuilder(context)
          : null,
      onEdit: editable && store.hasWorkout(day)
          ? () => _openBuilder(context)
          : null,
      onRemove: editable && store.hasWorkout(day)
          ? () => _confirmRemove(context, t)
          : null,
    );
  }

  /// Opens the workout builder for this specific day. The builder saves back
  /// into the plan rather than continuing to the route search, because the
  /// rider came here to fill in a day, not to go ride now.
  Future<void> _openBuilder(BuildContext context) async {
    final t = tr(context);
    // Untyped on purpose: the app's `routes` table builds
    // MaterialPageRoute<dynamic>, and asking pushNamed for a Route<bool>
    // makes Navigator cast it and throw.
    final saved = await Navigator.of(context)
        .pushNamed('/workout-builder', arguments: day);
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.calendarWorkoutSaved)));
  }

  Future<void> _confirmRemove(BuildContext context, AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.calendarRemoveTitle,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        content: Text(t.calendarRemoveBody, style: AppTextStyles.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.editRouteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.calendarRemoveWorkout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    WorkoutPlanStore.instance.removePlanned(day);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.calendarWorkoutRemoved)));
  }
}
