import 'package:flutter/foundation.dart';

import '../models/history_entry.dart';
import '../screens/calendar_demo_data.dart';

/// The rider's completed activities, and which planned day each one is the
/// result of.
///
/// The link lives here, on the activity, and nowhere else. A day reads as
/// done because an activity points at it, so associating and disassociating
/// change one field - there is no second copy of the result on the calendar
/// to drift out of step with this one.
///
/// Feature 002, Requirement 6: a candidate is never silently written as a
/// workout's result. Nothing in this store links an activity on its own; the
/// rider does, and can undo it.
///
/// In memory only, like the other stores.
class ActivityStore extends ChangeNotifier {
  List<HistoryEntry> _activities = [];

  ActivityStore() {
    seedDemoActivities();
  }

  static final ActivityStore instance = ActivityStore();

  /// Most recent first, which is the order history reads in.
  List<HistoryEntry> get activities {
    final sorted = [..._activities]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  /// Activities not yet the result of any planned day - what the rider picks
  /// from when associating one.
  List<HistoryEntry> get unlinked =>
      List.unmodifiable(activities.where((a) => !a.isLinked));

  /// The activity recorded as this day's result, if the rider linked one.
  HistoryEntry? linkedTo(DateTime day) {
    final key = normalizeDay(day);
    for (final activity in _activities) {
      final linked = activity.linkedDay;
      if (linked != null && normalizeDay(linked) == key) return activity;
    }
    return null;
  }

  bool isDone(DateTime day) => linkedTo(day) != null;

  void seedDemoActivities() {
    _activities = demoActivities();
    notifyListeners();
  }

  /// Records [activityId] as the result of [day].
  ///
  /// A day holds one result, so linking to a day that already has one
  /// replaces it - the previous activity goes back to being unlinked rather
  /// than leaving the day with two results.
  void link(String activityId, DateTime day) {
    final key = normalizeDay(day);
    var changed = false;

    _activities = [
      for (final activity in _activities)
        if (activity.id == activityId)
          _also(() => changed = true, activity.copyWith(linkedDay: key))
        else if (activity.isLinked && normalizeDay(activity.linkedDay!) == key)
          _also(() => changed = true, activity.copyWith(linkedDay: null))
        else
          activity,
    ];

    if (changed) notifyListeners();
  }

  /// Takes the result off whatever day it was on. The activity stays - it
  /// still happened, it just is not this plan's result any more.
  void unlink(String activityId) {
    var changed = false;
    _activities = [
      for (final activity in _activities)
        if (activity.id == activityId && activity.isLinked)
          _also(() => changed = true, activity.copyWith(linkedDay: null))
        else
          activity,
    ];
    if (changed) notifyListeners();
  }

  static T _also<T>(void Function() effect, T value) {
    effect();
    return value;
  }
}
