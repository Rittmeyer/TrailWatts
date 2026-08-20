import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Which physiological quantity a zone table is expressed in.
///
/// Power and heart rate are NOT interchangeable scales: the same effort sits
/// at different zone numbers in each, and heart rate lags power. They
/// therefore get separate tables, never one shared list of zones
/// (Constitution Article VII).
enum ZoneMetric { power, heartRate }

/// How many zones a table is divided into. Both tables support both scales
/// independently - a rider may run 7 power zones with 5 heart-rate zones,
/// which is the most common combination and the default here.
enum ZoneScale {
  five(5),
  seven(7);

  const ZoneScale(this.count);
  final int count;
}

/// What a heart-rate table's percentages are measured against. The two are
/// not interchangeable - the same zone boundary is a different percentage of
/// LTHR than of maximum heart rate - so each anchor carries its own table.
enum HeartRateAnchor { lactateThreshold, maximum }

extension ZoneMetricX on ZoneMetric {
  String get label => switch (this) {
        ZoneMetric.power => 'Potência',
        ZoneMetric.heartRate => 'Frequência cardíaca',
      };

  String get unit => switch (this) {
        ZoneMetric.power => 'w',
        ZoneMetric.heartRate => 'bpm',
      };
}

/// One zone inside a [ZoneTable]: its position, its name, and the band it
/// covers as a percentage of that table's anchor (FTP, LTHR or HR max).
@immutable
class ZoneDefinition {
  /// 1-based, so it reads the same as the rider-facing code (Z1, Z2...).
  final int index;
  final String label;

  /// Inclusive lower bound, as a percentage of the table's anchor.
  final double minPct;

  /// Exclusive upper bound. Null on the top zone, which is open-ended.
  final double? maxPct;

  const ZoneDefinition({
    required this.index,
    required this.label,
    required this.minPct,
    this.maxPct,
  })  : assert(index >= 1),
        assert(minPct >= 0),
        assert(maxPct == null || maxPct > minPct);

  String get code => 'Z$index';

  String get pickerLabel => '$label ($code)';

  /// Fixed colour mapping, shared by every surface that shows intensity.
  Color get color => switch (index) {
        1 => AppColors.zone1,
        2 => AppColors.zone2,
        3 => AppColors.zone3,
        4 => AppColors.zone4,
        5 => AppColors.zone5,
        6 => AppColors.zone6,
        _ => AppColors.zone7,
      };

  bool containsPct(double pct) =>
      pct >= minPct && (maxPct == null || pct < maxPct!);

  /// Absolute lower bound for a rider whose anchor is [anchor]
  /// (FTP in watts, or LTHR / HR max in bpm).
  int minFor(num anchor) => (anchor * minPct / 100).round();

  /// Absolute upper bound, or null on the open-ended top zone.
  int? maxFor(num anchor) =>
      maxPct == null ? null : (anchor * maxPct! / 100).round();

  /// e.g. "228-263 w", or "≥ 316 w" for the top zone.
  String rangeLabel(num anchor, String unit) {
    final min = minFor(anchor);
    final max = maxFor(anchor);
    return max == null ? '≥ $min $unit' : '$min-$max $unit';
  }
}

/// A complete set of zones for one metric at one scale.
@immutable
class ZoneTable {
  final ZoneMetric metric;
  final ZoneScale scale;

  /// Only set for heart-rate tables; power is always anchored on FTP.
  final HeartRateAnchor? anchor;
  final List<ZoneDefinition> zones;

  const ZoneTable({
    required this.metric,
    required this.scale,
    required this.zones,
    this.anchor,
  });

  ZoneDefinition byIndex(int index) => zones[index - 1];

  /// The zone a measured value falls into, given the rider's anchor.
  ZoneDefinition forValue(num value, {required num anchor}) =>
      forPct(value / anchor * 100);

  ZoneDefinition forPct(double pct) => zones.firstWhere(
        (z) => z.containsPct(pct),
        orElse: () => pct < zones.first.minPct ? zones.first : zones.last,
      );
}

/// A zone reference that travels with the workout, the route segment and the
/// history entry, so a stored "Z4" is never ambiguous about which table it
/// came from. Z4 of a 7-zone power table is not Z4 of a 5-zone HR table.
@immutable
class TrainingZone {
  final ZoneMetric metric;
  final ZoneScale scale;
  final int index;

  const TrainingZone({
    required this.metric,
    required this.scale,
    required this.index,
  }) : assert(index >= 1);

  ZoneTable get table => ZoneTables.of(metric, scale);

  ZoneDefinition get definition => table.byIndex(index);

  String get code => definition.code;
  String get label => definition.label;
  Color get color => definition.color;
  String get pickerLabel => definition.pickerLabel;

  @override
  bool operator ==(Object other) =>
      other is TrainingZone &&
      other.metric == metric &&
      other.scale == scale &&
      other.index == index;

  @override
  int get hashCode => Object.hash(metric, scale, index);

  @override
  String toString() => '$code(${metric.name}/${scale.count})';
}

/// The built-in default tables.
///
/// The power bands follow the widely used Coggan model and are stable. The
/// heart-rate bands are PROVISIONAL: percentage boundaries vary by author and
/// by anchor, and DECISIONS_REQUIRED.md keeps "generic HR mapping" open
/// pending coach/physiology review. Riders can override boundaries manually
/// (Constitution Article II), which is what the profile screen edits.
class ZoneTables {
  const ZoneTables._();

  static ZoneTable of(ZoneMetric metric, ZoneScale scale,
      {HeartRateAnchor anchor = HeartRateAnchor.lactateThreshold}) {
    return switch (metric) {
      ZoneMetric.power => scale == ZoneScale.seven ? powerSeven : powerFive,
      ZoneMetric.heartRate => switch ((scale, anchor)) {
          (ZoneScale.seven, HeartRateAnchor.lactateThreshold) =>
            heartRateSevenLthr,
          (ZoneScale.five, HeartRateAnchor.lactateThreshold) =>
            heartRateFiveLthr,
          (ZoneScale.seven, HeartRateAnchor.maximum) => heartRateSevenMax,
          (ZoneScale.five, HeartRateAnchor.maximum) => heartRateFiveMax,
        },
    };
  }

  /// Coggan seven-zone power model, as % of FTP.
  static const powerSeven = ZoneTable(
    metric: ZoneMetric.power,
    scale: ZoneScale.seven,
    zones: [
      ZoneDefinition(
          index: 1, label: 'Recuperação ativa', minPct: 0, maxPct: 56),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 56, maxPct: 76),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 76, maxPct: 91),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 91, maxPct: 106),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 106, maxPct: 121),
      ZoneDefinition(index: 6, label: 'Anaeróbico', minPct: 121, maxPct: 151),
      ZoneDefinition(index: 7, label: 'Neuromuscular', minPct: 151),
    ],
  );

  /// Five-zone power model: the same lower bands, with Coggan's Z5/Z6/Z7
  /// collapsed into one open-ended top zone.
  static const powerFive = ZoneTable(
    metric: ZoneMetric.power,
    scale: ZoneScale.five,
    zones: [
      ZoneDefinition(index: 1, label: 'Recuperação', minPct: 0, maxPct: 56),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 56, maxPct: 76),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 76, maxPct: 91),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 91, maxPct: 106),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 106),
    ],
  );

  /// PROVISIONAL - % of lactate-threshold heart rate.
  static const heartRateFiveLthr = ZoneTable(
    metric: ZoneMetric.heartRate,
    scale: ZoneScale.five,
    anchor: HeartRateAnchor.lactateThreshold,
    zones: [
      ZoneDefinition(index: 1, label: 'Recuperação', minPct: 0, maxPct: 85),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 85, maxPct: 90),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 90, maxPct: 95),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 95, maxPct: 100),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 100),
    ],
  );

  /// PROVISIONAL - % of lactate-threshold heart rate.
  static const heartRateSevenLthr = ZoneTable(
    metric: ZoneMetric.heartRate,
    scale: ZoneScale.seven,
    anchor: HeartRateAnchor.lactateThreshold,
    zones: [
      ZoneDefinition(
          index: 1, label: 'Recuperação ativa', minPct: 0, maxPct: 81),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 81, maxPct: 90),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 90, maxPct: 94),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 94, maxPct: 100),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 100, maxPct: 103),
      ZoneDefinition(index: 6, label: 'Anaeróbico', minPct: 103, maxPct: 107),
      ZoneDefinition(index: 7, label: 'Neuromuscular', minPct: 107),
    ],
  );

  /// PROVISIONAL - % of maximum heart rate. Used only when the rider knows
  /// their HR max but not their threshold HR.
  static const heartRateFiveMax = ZoneTable(
    metric: ZoneMetric.heartRate,
    scale: ZoneScale.five,
    anchor: HeartRateAnchor.maximum,
    zones: [
      ZoneDefinition(index: 1, label: 'Recuperação', minPct: 0, maxPct: 60),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 60, maxPct: 70),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 70, maxPct: 80),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 80, maxPct: 90),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 90),
    ],
  );

  /// PROVISIONAL - % of maximum heart rate.
  static const heartRateSevenMax = ZoneTable(
    metric: ZoneMetric.heartRate,
    scale: ZoneScale.seven,
    anchor: HeartRateAnchor.maximum,
    zones: [
      ZoneDefinition(
          index: 1, label: 'Recuperação ativa', minPct: 0, maxPct: 60),
      ZoneDefinition(index: 2, label: 'Resistência', minPct: 60, maxPct: 70),
      ZoneDefinition(index: 3, label: 'Tempo', minPct: 70, maxPct: 80),
      ZoneDefinition(index: 4, label: 'Limiar', minPct: 80, maxPct: 88),
      ZoneDefinition(index: 5, label: 'VO2max', minPct: 88, maxPct: 93),
      ZoneDefinition(index: 6, label: 'Anaeróbico', minPct: 93, maxPct: 97),
      ZoneDefinition(index: 7, label: 'Neuromuscular', minPct: 97),
    ],
  );
}
