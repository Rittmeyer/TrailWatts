import 'package:flutter/widgets.dart';

import '../models/result_source.dart';
import '../services/routing_service.dart';
import '../models/zone.dart';
import 'app_localizations.dart';

/// Rider-facing names for the domain enums.
///
/// The models carry identity (ZoneName.threshold), not words - keeping the
/// engine free of interface text and letting every surface resolve the same
/// term the same way in whatever language the rider is using.
extension ZoneNameL10n on ZoneName {
  String label(AppLocalizations t) => switch (this) {
        ZoneName.recovery => t.zoneRecovery,
        ZoneName.activeRecovery => t.zoneActiveRecovery,
        ZoneName.endurance => t.zoneEndurance,
        ZoneName.tempo => t.zoneTempo,
        ZoneName.threshold => t.zoneThreshold,
        ZoneName.vo2max => t.zoneVo2max,
        ZoneName.anaerobic => t.zoneAnaerobic,
        ZoneName.neuromuscular => t.zoneNeuromuscular,
      };
}

extension ZoneDefinitionL10n on ZoneDefinition {
  String label(AppLocalizations t) => name.label(t);

  /// e.g. "Threshold (Z4)"
  String pickerLabel(AppLocalizations t) => '${name.label(t)} ($code)';
}

extension TrainingZoneL10n on TrainingZone {
  String label(AppLocalizations t) => name.label(t);
}

extension ZoneMetricL10n on ZoneMetric {
  String label(AppLocalizations t) => switch (this) {
        ZoneMetric.power => t.metricPower,
        ZoneMetric.heartRate => t.metricHeartRate,
      };

  String unit(AppLocalizations t) => switch (this) {
        ZoneMetric.power => t.unitWatts,
        ZoneMetric.heartRate => t.unitBpm,
      };
}

extension ResultSourceL10n on ResultSource {
  String label(AppLocalizations t) => switch (this) {
        ResultSource.strava => t.sourceStrava,
        ResultSource.garmin => t.sourceGarmin,
        ResultSource.wahoo => t.sourceWahoo,
        ResultSource.manual => t.sourceManual,
      };
}

extension RouteDegradationL10n on RouteDegradation {
  String label(AppLocalizations t) => switch (this) {
        RouteDegradation.serviceUnavailable => t.routingUnavailable,
        RouteDegradation.noRoute => t.routingNoRoute,
        RouteDegradation.needsTwoPoints => t.routingNeedsTwoPoints,
      };
}

/// Shorthand used across the screens.
AppLocalizations tr(BuildContext context) => AppLocalizations.of(context);
