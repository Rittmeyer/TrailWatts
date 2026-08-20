import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/history_entry.dart';
import '../models/zone.dart';
import '../services/activity_store.dart';
import '../services/rider_profile_store.dart';
import '../services/workout_plan_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'calendar_day_detail.dart';

/// The day panel wired to the plan and the activities: shows the selected
/// day and offers the actions that day allows.
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
    final plan = WorkoutPlanStore.instance;
    final activities = ActivityStore.instance;

    final entry = plan.entryFor(day);
    final activity = activities.linkedTo(day);
    final planned = entry != null;
    // A day whose result is recorded is not the rider's to re-plan. Unlinking
    // the activity hands it back, which is why that action stays available.
    final open = activity == null;

    return CalendarDayDetail(
      entry: entry,
      activity: activity,
      activityZone: activity == null ? null : _zoneFor(activity),
      onAdd: open && !planned ? () => _openBuilder(context) : null,
      onEdit: open && planned ? () => _openBuilder(context) : null,
      onRemove: open && planned ? () => _confirmRemove(context, t) : null,
      // Linking needs a plan to attach the ride to, and an unlinked ride to
      // attach: offering it with nothing to pick would be a dead end.
      onLink: open && planned && activities.unlinked.isNotEmpty
          ? () => _pickActivity(context, t)
          : null,
      onUnlink: activity == null ? null : () => _unlink(context, t, activity),
    );
  }

  /// The zone an activity is shown in: the one recorded with it, or resolved
  /// from the watts it actually held on the rider's current table.
  TrainingZone? _zoneFor(HistoryEntry activity) =>
      activity.zone ??
      RiderProfileStore.instance.profile
          .zoneFor(activity.realizedWatts, ZoneMetric.power);

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

  /// Asks which ride was this day's workout. Nothing is linked until the
  /// rider picks one (Feature 002, Requirement 6).
  Future<void> _pickActivity(BuildContext context, AppLocalizations t) async {
    final locale = Localizations.localeOf(context).toString();
    final candidates = ActivityStore.instance.unlinked;

    final chosen = await showModalBottomSheet<HistoryEntry>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.calendarLinkTitle,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(t.calendarLinkBody,
                  style: AppTextStyles.label.copyWith(height: 1.4)),
              const SizedBox(height: 14),
              for (final activity in candidates)
                _CandidateRow(
                  activity: activity,
                  locale: locale,
                  onTap: () => Navigator.of(sheetContext).pop(activity),
                ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !context.mounted) return;
    ActivityStore.instance.link(chosen.id, day);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.calendarActivityLinked(chosen.routeName))));
  }

  Future<void> _unlink(
      BuildContext context, AppLocalizations t, HistoryEntry activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.calendarUnlinkTitle,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        content: Text(t.calendarUnlinkBody, style: AppTextStyles.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.editRouteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.calendarUnlinkActivity),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ActivityStore.instance.unlink(activity.id);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.calendarActivityUnlinked)));
  }
}

class _CandidateRow extends StatelessWidget {
  final HistoryEntry activity;
  final String locale;
  final VoidCallback onTap;

  const _CandidateRow({
    required this.activity,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.routeName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat.MMMMd(locale).format(activity.date)} · '
                      '${t.calendarVia(activity.source.label(t))}',
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              Text('${activity.realizedWatts}w',
                  style: AppTextStyles.numeric.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
