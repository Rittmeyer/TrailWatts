import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';

/// Reads back the rider's next planned workout from TrainingPeaks, so the
/// builder can be pre-filled instead of typed out by hand. Constitution
/// Article II: this is a read of one specific, already-planned workout -
/// never a bulk import of the rider's whole TrainingPeaks library.
///
/// There is no TrainingPeaks backend wired up in this app yet (see
/// README's platform-integration note), so this stands in with a
/// representative planned session - a threshold block repeated with its
/// own recovery, exactly the "two or more stimuli in one block" case the
/// builder now supports. Swapping this body for a real API call does not
/// change any caller: the builder only depends on the returned groups.
class TrainingPeaksImportService {
  const TrainingPeaksImportService();

  Future<List<WorkoutBlockGroup>> importPreferredWorkout(
      RiderProfile rider) async {
    // Simulated network latency, so the UI's loading state is exercised
    // the same way it would be against a real API.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    return [
      WorkoutBlockGroup(
        repeatCount: 1,
        stimuli: [
          WorkoutBlock(
            role: WorkoutBlockRole.warmUp,
            zone: const TrainingZone(
                metric: ZoneMetric.power, scale: ZoneScale.seven, index: 2),
            durationMin: 10,
            target: const WorkoutTarget(
                metric: ZoneMetric.power, minValue: 120, maxValue: 140),
          ),
        ],
      ),
      WorkoutBlockGroup(
        repeatCount: 4,
        stimuli: [
          WorkoutBlock(
            zone: const TrainingZone(
                metric: ZoneMetric.power, scale: ZoneScale.seven, index: 4),
            durationMin: 8,
            target: const WorkoutTarget(
                metric: ZoneMetric.power, minValue: 191, maxValue: 222),
          ),
          WorkoutBlock(
            role: WorkoutBlockRole.recovery,
            zone: const TrainingZone(
                metric: ZoneMetric.power, scale: ZoneScale.seven, index: 1),
            durationMin: 2,
            target: const WorkoutTarget(
                metric: ZoneMetric.power, minValue: 90, maxValue: 110),
          ),
        ],
      ),
      WorkoutBlockGroup(
        repeatCount: 1,
        stimuli: [
          WorkoutBlock(
            role: WorkoutBlockRole.coolDown,
            zone: const TrainingZone(
                metric: ZoneMetric.power, scale: ZoneScale.seven, index: 1),
            durationMin: 8,
            target: const WorkoutTarget(
                metric: ZoneMetric.power, minValue: 90, maxValue: 110),
          ),
        ],
      ),
    ];
  }
}
