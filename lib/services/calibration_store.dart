import 'package:flutter/foundation.dart';

import '../engine/activity_stream.dart';
import '../engine/calibration_engine.dart';
import '../engine/cycling_power_model.dart';
import '../models/calibration.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import 'integrations_store.dart';
import 'platform/platform_api_client.dart';
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

  /// Learns from a ride the rider just linked to a workout.
  ///
  /// Everything that can be absent is treated as absent rather than as
  /// zero: a platform with no documented stream endpoint, a ride with no
  /// power meter, a session whose token expired. None of those is an error
  /// worth interrupting the rider for - they are reasons the model stays
  /// generic, and the chip already says that it is.
  ///
  /// Returns how many usable stretches the ride contributed, so a caller
  /// can tell the rider what their ride was worth.
  Future<int> learnFrom({
    required ResultSource platform,
    required String activityId,
    required DateTime ridenAt,
    required RiderProfile rider,
    required IntegrationsStore integrations,
    ActivityStreamReader reader = const ActivityStreamReader(),
  }) async {
    final ActivityStream stream;
    try {
      final tokens = await integrations.validTokensFor(platform);
      stream = await integrations.api.activityStream(
        credentials: integrations.credentialsFor(platform),
        tokens: tokens,
        activityId: activityId,
      );
    } on PlatformApiException {
      return 0;
    }

    final model = CyclingPowerModel(effective(rider));
    final observations = reader.observationsFrom(
      stream,
      systemMassKg: rider.systemMassKg,
      ridenAt: ridenAt,
      // What the model would have said, kept for showing the rider how far
      // off it was - never used to decide whether to keep the stretch.
      predictPower: (speedKmh, gradientPct) => model.powerFor(
        speedMs: speedKmh / 3.6,
        gradientPct: gradientPct,
      ),
    );

    if (observations.isEmpty) return 0;
    observeAll(observations, rider);
    return observations.length;
  }

  @visibleForTesting
  void reset() {
    _observations.clear();
    _profile = null;
    notifyListeners();
  }
}
