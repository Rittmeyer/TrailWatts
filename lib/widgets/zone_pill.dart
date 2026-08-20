import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../models/zone.dart';

/// Maps to .day-detail-zone - a filled pill in the zone's own color,
/// e.g. "Z4 · LIMIAR".
class ZonePill extends StatelessWidget {
  final TrainingZone zone;

  const ZonePill({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: zone.color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '${zone.code} · ${zone.label(t).toUpperCase()}',
        style: const TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
      ),
    );
  }
}
