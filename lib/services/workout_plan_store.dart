import 'package:flutter/foundation.dart';

import '../models/calendar_entry.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import '../screens/calendar_demo_data.dart';
import 'rider_profile_store.dart';

/// The rider's plan, keyed by day: what is scheduled, and what is already
/// ridden. The calendar reads it, and adding, editing or removing a day's
/// workout writes to it.
///
/// Planned days are the rider's to change; completed ones are not. A ride
/// that happened is a record, so this store refuses to overwrite or delete
/// one - the calendar hides those actions for a completed day, and the
/// refusal here is what makes that a rule rather than a UI detail.
///
/// In memory only, like the other stores: persisting the plan belongs with
/// the account, not with a singleton here.
class WorkoutPlanStore extends ChangeNotifier {
  final RiderProfileStore _profiles;
  Map<DateTime, CalendarEntry> _entries = {};

  WorkoutPlanStore({RiderProfileStore? profiles})
      : _profiles = profiles ?? RiderProfileStore.instance {
    seedDemoPlan();
    // A plan written against seven zones has to read as five when the rider
    // switches tables: the watts did not change, but what to call them did.
    _profiles.addListener(_relabelZones);
  }

  static final WorkoutPlanStore instance = WorkoutPlanStore();

  @override
  void dispose() {
    _profiles.removeListener(_relabelZones);
    super.dispose();
  }

  Map<DateTime, CalendarEntry> get entries => Map.unmodifiable(_entries);

  CalendarEntry? entryFor(DateTime day) => _entries[normalizeDay(day)];

  bool hasWorkout(DateTime day) => entryFor(day)?.hasWorkout ?? false;

  /// True when the day is still the rider's to change. A completed day is
  /// not: it records what happened.
  bool isEditable(DateTime day) => !(entryFor(day)?.isDone ?? false);

  /// Loads the demo plan. This is what the app starts with until a real
  /// plan store backs the calendar.
  void seedDemoPlan() {
    _entries = {...demoCalendarEntriesFor(_profiles.profile)};
    notifyListeners();
  }

  /// Schedules [blocks] on [day], replacing whatever was planned there.
  ///
  /// Throws [StateError] on a completed day rather than quietly writing over
  /// a ride that already happened.
  void savePlanned(DateTime day, List<WorkoutBlock> blocks) {
    final key = normalizeDay(day);
    if (_entries[key]?.isDone ?? false) {
      throw StateError('A completed day cannot be re-planned.');
    }
    if (blocks.isEmpty) {
      // Saving an empty workout is a removal, not a day with nothing in it:
      // CalendarEntry requires exactly one of planned/completed.
      _entries.remove(key);
    } else {
      _entries[key] = CalendarEntry(date: key, planned: List.of(blocks));
    }
    notifyListeners();
  }

  /// Drops the workout planned for [day]. Refuses a completed day for the
  /// same reason `savePlanned` does.
  void removePlanned(DateTime day) {
    final key = normalizeDay(day);
    if (_entries[key]?.isDone ?? false) {
      throw StateError('A completed day cannot be removed from the plan.');
    }
    if (_entries.remove(key) != null) notifyListeners();
  }

  /// Re-resolves every planned block's zone against the rider's current
  /// table, keeping the prescribed watts untouched.
  ///
  /// Completed entries are left alone: a stored zone carries its own metric
  /// and scale, and re-labelling a finished ride would rewrite what happened.
  void _relabelZones() {
    final rider = _profiles.profile;
    var changed = false;

    for (final key in _entries.keys.toList()) {
      final planned = _entries[key]!.planned;
      if (planned == null) continue;

      final relabelled = [
        for (final block in planned) _withZoneFor(block, rider),
      ];
      _entries[key] = CalendarEntry(date: key, planned: relabelled);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Moves a block's zone onto [rider]'s current table, keeping the number
  /// the rider chose wherever that table still has it.
  ///
  /// Deliberately a re-index rather than a fresh resolve from the watts: the
  /// zone is what the rider asked for and the target is what they will hold,
  /// and the builder lets those be set independently. Re-deriving would
  /// quietly overwrite the choice. Clamping is the truthful mapping in the
  /// direction that loses zones - the five-zone table's top zone is exactly
  /// where Coggan's Z5, Z6 and Z7 collapse to.
  static WorkoutBlock _withZoneFor(WorkoutBlock block, RiderProfile rider) {
    // Heart-rate blocks belong to the HR table, which has its own scale and
    // needs an anchor the rider may not have supplied.
    if (block.target.metric != ZoneMetric.power) return block;

    final scale = rider.powerZones.scale;
    final index = block.zone.index.clamp(1, scale.count);
    if (block.zone.scale == scale && block.zone.index == index) return block;

    return block.copyWith(
      zone: TrainingZone(metric: ZoneMetric.power, scale: scale, index: index),
    );
  }
}
