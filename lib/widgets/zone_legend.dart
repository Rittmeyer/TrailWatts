import 'package:flutter/material.dart';
import '../models/zone.dart';
import 'zone_pill.dart';

/// The zone legend for one table. It renders whichever scale that table
/// uses, so a seven-zone power workout shows Z1-Z7 and a five-zone
/// heart-rate workout shows Z1-Z5 - the legend is never a fixed list
/// (Constitution Article VII).
class ZoneLegend extends StatelessWidget {
  final ZoneMetric metric;
  final ZoneScale scale;
  final HeartRateAnchor anchor;

  const ZoneLegend({
    super.key,
    required this.metric,
    required this.scale,
    this.anchor = HeartRateAnchor.lactateThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final table = ZoneTables.of(metric, scale, anchor: anchor);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final z in table.zones)
          ZonePill(
            zone: TrainingZone(metric: metric, scale: scale, index: z.index),
          ),
      ],
    );
  }
}
