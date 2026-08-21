import 'package:flutter/foundation.dart';

import '../engine/calibration_engine.dart';
import '../models/calibration.dart';
import '../models/rider_profile.dart';
import 'rider_profile_store.dart';

/// What the app has learned about this rider, and whether it still applies.
///
/// Kept apart from [RiderProfileStore] on purpose: the profile is what the
/// rider told us, and this is what the road told us. Merging them would
/// make it impossible to say which number came from where, and spec 009
/// requires the rider to be able to see exactly that.
class CalibrationStore extends ChangeNotifier {
  final CalibrationEngine engine;

  CalibrationStore({this.engine = const CalibrationEngine()});

  static final CalibrationStore instance = CalibrationStore();

  final List<CalibrationObservation> _observations = [];
  CalibrationProfile? _profile;

  /// Null until enough good rides have been seen. Null is a real answer -
  /// "we have not learned anything yet" - not a missing value.
  CalibrationProfile? get profile => _profile;

  CalibrationState get state => _profile?.state ?? CalibrationState.generic;

  int get observationCount => _observations.length;

  /// The constants the engine should actually use.
  ///
  /// The rider's declared profile, with CdA and Crr replaced only while a
  /// calibration is current. A stale calibration falls back to the declared
  /// values rather than carrying on with constants that no longer describe
  /// the rider (requirement 7).
  RiderProfile effective(RiderProfile declared) {
    final calibration = _profile;
    if (calibration == null ||
        calibration.state != CalibrationState.calibrated) {
      return declared;
    }
    return declared.copyWith(cda: calibration.cda, crr: calibration.crr);
  }

  /// Takes in what a completed ride told us, and refits when it can.
  ///
  /// An observation the engine will not learn from is still recorded: how
  /// many rides were seen and how few were usable is the honest answer to
  /// "why am I still on the generic model".
  void observe(CalibrationObservation observation, RiderProfile rider) {
    _observations.add(observation);
    _refit(rider);
  }

  void observeAll(
      Iterable<CalibrationObservation> observations, RiderProfile rider) {
    _observations.addAll(observations);
    _refit(rider);
  }

  void _refit(RiderProfile rider) {
    final fitted = engine.fit(
      observations: _observations,
      rider: rider,
      previousVersion: _profile?.version ?? 0,
    );
    // A refit that does not converge leaves the previous calibration alone.
    // Requirement 4: constants move only when the criteria are met.
    if (fitted != null) {
      _profile = fitted;
      notifyListeners();
    }
  }

  /// Marks the calibration stale when the rider changed under it.
  ///
  /// Not deleted: the rider should see that it stopped applying, rather
  /// than finding their estimates quietly different (requirement 9).
  void riderChanged(RiderProfile before, RiderProfile after) {
    final calibration = _profile;
    if (calibration == null) return;
    if (!engine.invalidates(before, after)) return;

    _profile = CalibrationProfile(
      state: CalibrationState.stale,
      version: calibration.version,
      cda: calibration.cda,
      crr: calibration.crr,
      predictionAccuracyPct: calibration.predictionAccuracyPct,
      observationCount: calibration.observationCount,
      quality: calibration.quality,
      updatedAt: calibration.updatedAt,
    );
    // The observations were made by a different rider-and-bike, so they are
    // not evidence about this one.
    _observations.clear();
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _observations.clear();
    _profile = null;
    notifyListeners();
  }
}
