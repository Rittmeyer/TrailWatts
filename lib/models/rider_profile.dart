import 'zone.dart';

/// Shared rule for a rider-entered zone table: one lower bound per zone,
/// starting at zero and strictly increasing. Anything else would leave a gap
/// or an overlap, so a value could land in two zones or in none.
bool isValidZoneBounds(List<int>? bounds, ZoneScale scale) {
  if (bounds == null) return true;
  if (bounds.length != scale.count) return false;
  if (bounds.first != 0) return false;
  for (var i = 1; i < bounds.length; i++) {
    if (bounds[i] <= bounds[i - 1]) return false;
  }
  return true;
}

/// The rider's power zone table. Always anchored on FTP; only the number of
/// zones is configurable.
class PowerZoneSettings {
  final ZoneScale scale;

  /// Rider-entered lower bounds in watts, one per zone, overriding the
  /// percentage table. Manual entry stays authoritative when present
  /// (Constitution Article II).
  final List<int>? customLowerBoundsWatts;

  const PowerZoneSettings({
    this.scale = ZoneScale.seven,
    this.customLowerBoundsWatts,
  });

  /// Whether rider-entered bounds are usable. Checked here rather than in
  /// the constructor because a const constructor cannot evaluate a list.
  bool get hasValidCustomBounds =>
      isValidZoneBounds(customLowerBoundsWatts, scale);

  /// The bounds as they would be stored if the rider switched this table to
  /// manual editing now - i.e. the generic table made concrete.
  List<int> derivedBounds(int ftpWatts) => [
        for (var i = 1; i <= scale.count; i++)
          table.byIndex(i).minFor(ftpWatts),
      ];

  ZoneTable get table => ZoneTables.of(ZoneMetric.power, scale);

  bool get isCustom => customLowerBoundsWatts != null;

  /// Lower bound of [zoneIndex] in watts, for a rider with this [ftpWatts].
  int lowerBoundWatts(int zoneIndex, int ftpWatts) =>
      customLowerBoundsWatts?[zoneIndex - 1] ??
      table.byIndex(zoneIndex).minFor(ftpWatts);

  /// Upper bound in watts, or null on the open-ended top zone.
  int? upperBoundWatts(int zoneIndex, int ftpWatts) {
    if (zoneIndex >= scale.count) return null;
    final custom = customLowerBoundsWatts;
    if (custom != null) return custom[zoneIndex] - 1;
    return table.byIndex(zoneIndex).maxFor(ftpWatts);
  }

  TrainingZone zone(int index) => TrainingZone(
        metric: ZoneMetric.power,
        scale: scale,
        index: index,
      );
}

/// The rider's heart-rate zone table. Independent of the power table: it has
/// its own zone count AND its own anchor, because a percentage of threshold
/// HR is not the same boundary as a percentage of maximum HR.
class HeartRateZoneSettings {
  final ZoneScale scale;
  final HeartRateAnchor anchor;

  /// Lactate-threshold HR. Preferred anchor when known.
  final int? lthrBpm;
  final int? hrMaxBpm;

  /// Rider-entered lower bounds in bpm, overriding the percentage table.
  final List<int>? customLowerBoundsBpm;

  const HeartRateZoneSettings({
    this.scale = ZoneScale.five,
    this.anchor = HeartRateAnchor.lactateThreshold,
    this.lthrBpm,
    this.hrMaxBpm,
    this.customLowerBoundsBpm,
  })  : assert(lthrBpm == null || lthrBpm > 0),
        assert(hrMaxBpm == null || hrMaxBpm > 0);

  ZoneTable get table =>
      ZoneTables.of(ZoneMetric.heartRate, scale, anchor: anchor);

  bool get isCustom => customLowerBoundsBpm != null;

  bool get hasValidCustomBounds =>
      isValidZoneBounds(customLowerBoundsBpm, scale);

  /// The generic table made concrete, or null when no anchor is known.
  List<int>? derivedBounds() {
    final anchorValue = anchorBpm;
    if (anchorValue == null) return null;
    return [
      for (var i = 1; i <= scale.count; i++)
        table.byIndex(i).minFor(anchorValue),
    ];
  }

  /// The bpm value the percentage table is measured against, or null when
  /// the rider has not supplied the value this anchor needs.
  int? get anchorBpm => switch (anchor) {
        HeartRateAnchor.lactateThreshold => lthrBpm,
        HeartRateAnchor.maximum => hrMaxBpm,
      };

  /// True when zones can be resolved at all - either custom bounds were
  /// entered, or the anchor this table needs is known.
  bool get isResolvable => isCustom || anchorBpm != null;

  int? lowerBoundBpm(int zoneIndex) {
    final custom = customLowerBoundsBpm;
    if (custom != null) return custom[zoneIndex - 1];
    final anchorValue = anchorBpm;
    return anchorValue == null
        ? null
        : table.byIndex(zoneIndex).minFor(anchorValue);
  }

  int? upperBoundBpm(int zoneIndex) {
    if (zoneIndex >= scale.count) return null;
    final custom = customLowerBoundsBpm;
    if (custom != null) return custom[zoneIndex] - 1;
    final anchorValue = anchorBpm;
    return anchorValue == null
        ? null
        : table.byIndex(zoneIndex).maxFor(anchorValue);
  }

  TrainingZone zone(int index) => TrainingZone(
        metric: ZoneMetric.heartRate,
        scale: scale,
        index: index,
      );
}

/// Physical/fitness profile. Authentication identity is stored separately.
class RiderProfile {
  final double weightKg;
  final int ftpWatts;
  final PowerZoneSettings powerZones;
  final HeartRateZoneSettings? heartRateZones;
  final double bikeWeightKg;
  final double cda;
  final double crr;
  final double drivetrainEfficiency;
  final Map<int, int>? powerCurveWatts;

  const RiderProfile({
    required this.weightKg,
    required this.ftpWatts,
    this.powerZones = const PowerZoneSettings(),
    this.heartRateZones,
    this.bikeWeightKg = 8,
    this.cda = 0.32,
    this.crr = 0.004,
    this.drivetrainEfficiency = 0.975,
    this.powerCurveWatts,
  })  : assert(weightKg > 0),
        assert(ftpWatts > 0),
        assert(bikeWeightKg >= 0),
        assert(cda > 0),
        assert(crr > 0),
        assert(drivetrainEfficiency > 0 && drivetrainEfficiency <= 1);

  double get systemMassKg => weightKg + bikeWeightKg;

  int? get hrMaxBpm => heartRateZones?.hrMaxBpm;

  /// The zone a measured value falls into, on the table that belongs to that
  /// metric. Returns null for heart rate when the rider has not supplied the
  /// anchor - an unknown zone is never guessed.
  TrainingZone? zoneFor(num value, ZoneMetric metric) {
    switch (metric) {
      case ZoneMetric.power:
        final def = powerZones.table.forValue(value, anchor: ftpWatts);
        return powerZones.zone(def.index);
      case ZoneMetric.heartRate:
        final hr = heartRateZones;
        final anchor = hr?.anchorBpm;
        if (hr == null || anchor == null) return null;
        final def = hr.table.forValue(value, anchor: anchor);
        return hr.zone(def.index);
    }
  }

  RiderProfile copyWith({
    double? weightKg,
    int? ftpWatts,
    PowerZoneSettings? powerZones,
    HeartRateZoneSettings? heartRateZones,
    double? bikeWeightKg,
    double? cda,
    double? crr,
    double? drivetrainEfficiency,
    Map<int, int>? powerCurveWatts,
  }) =>
      RiderProfile(
        weightKg: weightKg ?? this.weightKg,
        ftpWatts: ftpWatts ?? this.ftpWatts,
        powerZones: powerZones ?? this.powerZones,
        heartRateZones: heartRateZones ?? this.heartRateZones,
        bikeWeightKg: bikeWeightKg ?? this.bikeWeightKg,
        cda: cda ?? this.cda,
        crr: crr ?? this.crr,
        drivetrainEfficiency: drivetrainEfficiency ?? this.drivetrainEfficiency,
        powerCurveWatts: powerCurveWatts ?? this.powerCurveWatts,
      );
}
