import 'package:flutter/foundation.dart';

import '../models/rider_profile.dart';
import '../models/zone.dart';

/// The rider's profile, shared by every screen that needs it.
///
/// This exists because the profile screen used to be the only place that knew
/// the rider's zone scale: it held the choice in widget state and dropped it
/// on save, while the calendar, the route map and the workout builder each
/// hardcoded seven power zones. A rider on Z1-Z5 saw Z1-Z7 everywhere outside
/// the profile form.
///
/// Weight and FTP are the only inputs the physics engine needs
/// (Constitution Article I); the zone scales are what the rest of the UI
/// reads, which is why they belong in one place rather than in each screen's
/// own constant.
///
/// In memory only, like `IntegrationsStore` - persisting it is a real
/// requirement for a shipping build and belongs with the account, not with a
/// singleton here.
class RiderProfileStore extends ChangeNotifier {
  RiderProfileStore({RiderProfile? profile}) : _profile = profile ?? demoRider;

  static final RiderProfileStore instance = RiderProfileStore();

  /// What a rider sees before they have saved anything: the pairing the
  /// product defaults to (seven power zones, five heart-rate zones anchored
  /// on threshold), per DECISIONS_REQUIRED.md.
  static const demoRider = RiderProfile(
    weightKg: 74,
    ftpWatts: 210,
    powerZones: PowerZoneSettings(scale: ZoneScale.seven),
    heartRateZones: HeartRateZoneSettings(
      scale: ZoneScale.five,
      anchor: HeartRateAnchor.lactateThreshold,
      lthrBpm: 168,
      hrMaxBpm: 184,
    ),
  );

  RiderProfile _profile;
  RiderProfile get profile => _profile;

  /// The power table the rider is actually on. Screens that show a zone
  /// legend or resolve a wattage read this rather than assuming a scale.
  ZoneScale get powerScale => _profile.powerZones.scale;

  /// The heart-rate table, or null when the rider has not configured one -
  /// an absent HR table is not the same as a five-zone one, and a screen
  /// that needs an anchor has to handle its absence rather than guess.
  HeartRateZoneSettings? get heartRateZones => _profile.heartRateZones;

  void save(RiderProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
