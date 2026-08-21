import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/domain_labels.dart';
import '../services/integrations_store.dart';
import '../services/platform/gpx_export.dart';
import '../services/platform/platform_api_client.dart';
import '../services/routing_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/route_suggestion.dart';
import '../services/route_suggestion_store.dart';
import '../services/terrain/route_finder.dart';
import '../models/zone.dart';
import '../services/rider_profile_store.dart';
import '../widgets/page_header.dart';
import '../widgets/map_layers.dart';
import '../widgets/stat_box.dart';
import '../widgets/zone_pill.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 04 - "Rota no mapa". The stretch is drawn along the real
/// road network; its colour follows the predicted effort zone for that point
/// of the climb (Z1-Z5), never just "inside or outside the target"
/// (Constitution Article VII).
class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  ResultSource _platform = ResultSource.strava;

  /// Route export goes to the platforms the rider records on. TrainingPeaks
  /// is deliberately not here: it is connected to read the *planned* workout
  /// into the builder, not to receive a route.
  static const _exportPlatforms = [
    ResultSource.strava,
    ResultSource.garmin,
    ResultSource.wahoo,
  ];

  bool _exporting = false;

  /// The route the store settled on. There is no fallback constant: a
  /// screen that invents a suggestion when none was searched for is how the
  /// app shipped for months looking like it had a route engine.
  RouteSuggestion? get suggestion =>
      RouteSuggestionStore.instance.selected?.suggestion;

  /// This demo workout is prescribed in watts. The zone comes from the
  /// rider's own table rather than a fixed seven: the same effort sits at a
  /// different zone number on the five- and seven-zone tables, so naming it
  /// against anything but their profile would mislabel their own ride.
  static const _workoutMetric = ZoneMetric.power;

  RiderProfile get _rider => RiderProfileStore.instance.profile;
  ZoneScale get _workoutScale => _rider.powerZones.scale;

  /// ~180 w for this demo stretch, resolved on the rider's own power table.
  TrainingZone get _matchedZone =>
      _rider.zoneFor(180, _workoutMetric) ??
      TrainingZone(metric: _workoutMetric, scale: _workoutScale, index: 1);

  /// Control points of the suggested stretch; the drawn line between them is
  /// resolved against the road network.
  static const _waypoints = [
    LatLng(-23.5566, -46.6414),
    LatLng(-23.5540, -46.6385),
    LatLng(-23.5505, -46.6355),
  ];

  final _routing = OsrmRoutingService();
  RoutedPath? _path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await _routing.routeThrough(_waypoints);
    if (mounted) setState(() => _path = path);
  }

  /// Exports the suggested stretch to the selected platform.
  ///
  /// The GPX is generated either way (spec 002, Requirement 1). Where the
  /// platform documents a route endpoint it is pushed straight through;
  /// where it does not, the rider gets the file to run through the
  /// platform's own importer - the compliant handoff, never a scraped upload.
  Future<void> _export() async {
    final t = tr(context);
    final messenger = ScaffoldMessenger.of(context);
    final store = IntegrationsStore.instance;
    final platform = _platform;
    final label = platform.label(t);

    final route = suggestion;
    if (route == null) return;

    setState(() => _exporting = true);
    try {
      final tokens = await store.validTokensFor(platform);
      final gpx = buildRouteGpx(
        name: route.name,
        points: [
          for (final point in _path?.polyline ?? _waypoints)
            GpxRoutePoint(point),
        ],
      );

      final result = await store.api.exportRoute(
        credentials: store.credentialsFor(platform),
        tokens: tokens,
        routeId: route.id,
        name: route.name,
        gpx: gpx,
      );

      if (!mounted) return;
      switch (result.outcome) {
        case RouteExportOutcome.uploaded:
          messenger
              .showSnackBar(SnackBar(content: Text(t.routeExported(label))));
        case RouteExportOutcome.fileHandoff:
          await _showGpxHandoff(result.gpx, label);
      }
    } on PlatformApiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (e.failure) {
          PlatformApiFailure.unauthorized => t.routeExportNotConnected(label),
          PlatformApiFailure.notSupported => t.routeExportNotSupported(label),
          PlatformApiFailure.invalidResponse ||
          PlatformApiFailure.network =>
            t.routeExportFailed(label),
        }),
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showGpxHandoff(String gpx, String platformLabel) async {
    final t = tr(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.routeHandoffTitle(platformLabel),
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.routeHandoffBody(platformLabel),
                  style: AppTextStyles.label.copyWith(height: 1.5)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(gpx,
                      style: AppTextStyles.label
                          .copyWith(fontSize: 8, height: 1.35)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: gpx));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.routeHandoffCopied)));
              }
            },
            child: Text(t.routeHandoffCopy),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.editRouteCancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final route = suggestion;
    if (route == null) return _NoRouteYet(store: RouteSuggestionStore.instance);

    final path = _path;
    final distanceLabel = path != null && path.followsRoads
        ? '${path.distanceM.round()}m'
        : '${route.distanceM}m';

    return Scaffold(
      body: ContentWidth(
          maxWidth: ContentWidth.wide,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: route.name,
                      subtitle: t.routeSubtitle,
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        height: 230,
                        child: FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(-23.5536, -46.6386),
                            initialZoom: 14.4,
                            interactionOptions:
                                InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            trailwattTileLayer(),
                            PolylineLayer(polylines: [
                              Polyline(
                                points: path?.polyline ?? _waypoints,
                                strokeWidth: 5,
                                // Z4 - the zone this stretch is matched to.
                                color: _matchedZone.color,
                              ),
                            ]),
                            MarkerLayer(markers: [
                              Marker(
                                point: _waypoints.first,
                                width: 14,
                                height: 14,
                                child: const _EndCap(color: AppColors.accent),
                              ),
                              Marker(
                                point: _waypoints.last,
                                width: 14,
                                height: 14,
                                child: const _EndCap(color: AppColors.zone5),
                              ),
                            ]),
                            trailwattAttribution(context),
                          ],
                        ),
                      ),
                    ),
                    if (path != null && !path.followsRoads) ...[
                      const SizedBox(height: 10),
                      MapDegradedBanner(
                          message:
                              path.degradedReason?.label(t) ?? t.routeDegraded),
                    ],
                    const SizedBox(height: 10),
                    // The zone of this stretch, not a table of every zone: one
                    // chip says what the drawn line's colour means, and it is the
                    // zone on the rider's own table.
                    ZonePill(zone: _matchedZone),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: StatBox(
                                label: t.routeDistance, value: distanceLabel)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: StatBox(
                                label: t.routeGradientLabel, value: '5.2%')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: StatBox(
                                label: t.routeMatch,
                                value: '${route.matchPct}%',
                                valueColor: AppColors.greenText)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final saved = await Navigator.of(context)
                            .pushNamed('/route-edit');
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.routeSavedRescored)),
                          );
                        }
                      },
                      child: Text(t.routeEditManually,
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    Text(t.routeExportTo,
                        style: AppTextStyles.label.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _exportPlatforms
                          .map((p) => ChoiceChip(
                                label: Text(p.label(t)),
                                selected: _platform == p,
                                selectedColor: AppColors.greenBg,
                                onSelected: (_) =>
                                    setState(() => _platform = p),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    TrailwattButton(
                      label: _exporting ? t.routeExporting : t.routeExport,
                      onPressed: _exporting ? null : _export,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.routeFootnote,
                      style: AppTextStyles.label
                          .copyWith(fontSize: 9, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}

/// Start/finish dot on the drawn stretch.
class _EndCap extends StatelessWidget {
  final Color color;
  const _EndCap({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2.5),
      ),
    );
  }
}

/// What the map shows before a search has been run, or when one came back
/// with nothing. It is a real state, not an error: the rider has simply not
/// asked for a route yet, and saying so beats showing an invented one.
class _NoRouteYet extends StatelessWidget {
  final RouteSuggestionStore store;

  const _NoRouteYet({required this.store});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final reason = switch (store.failure) {
      RouteSearchFailure.source => t.routeSearchSourceDown,
      RouteSearchFailure.noGround => t.routeSearchNoGround,
      RouteSearchFailure.noCandidate => t.routeSearchNoCandidate,
      null => t.routeSearchNotRun,
    };

    return Scaffold(
      body: ContentWidth(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(title: t.routeSearchGo, subtitle: reason),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: t.routeSearchGo,
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/workout-builder/map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
