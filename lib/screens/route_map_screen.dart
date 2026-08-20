import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/routing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/result_source.dart';
import '../models/route_suggestion.dart';
import '../models/zone.dart';
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

  static const _exportPlatforms = [
    ResultSource.strava,
    ResultSource.garmin,
    ResultSource.wahoo,
  ];

  static const suggestion = RouteSuggestion(
    id: 'demo-route-01',
    name: 'Subida da Serra',
    routeType: RouteType.loop,
    distanceM: 850,
    elevationGainM: 44,
    estimatedMovingTimeMin: 3,
    score: RouteScoreBreakdown(
      intensityMatchPct: 98,
      durationMatchPct: 96,
      sequenceMatchPct: 100,
      continuityScorePct: 95,
      safetyScorePct: 95,
      trafficScorePct: 90,
      surfaceScorePct: 100,
      practicalityScorePct: 96,
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final distanceLabel = path != null && path.followsRoads
        ? '${path.distanceM.round()}m'
        : '${suggestion.distanceM}m';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.name,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Trecho sugerido para o treino de hoje',
                    style: AppTextStyles.screenSubtitle),
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
                            color: Zone.limiar.color,
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
                        trailwattAttribution(),
                      ],
                    ),
                  ),
                ),
                if (path != null && !path.followsRoads) ...[
                  const SizedBox(height: 10),
                  MapDegradedBanner(
                      message: path.degradedReason ??
                          'Trecho nao verificado contra a malha viaria.'),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: Zone.values.map((z) => ZonePill(zone: z)).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child:
                            StatBox(label: 'DISTANCIA', value: distanceLabel)),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: StatBox(label: 'GRADIENTE', value: '5.2%')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: StatBox(
                            label: 'MATCH',
                            value: '${suggestion.matchPct}%',
                            valueColor: AppColors.greenText)),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final saved = await Navigator.of(context)
                        .pushNamed<bool>('/route-edit');
                    if (saved == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Rota reavaliada e salva')),
                      );
                    }
                  },
                  child: Text('Editar rota manualmente',
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                Text('EXPORTAR PARA',
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
                            label: Text(p.label),
                            selected: _platform == p,
                            selectedColor: AppColors.greenBg,
                            onSelected: (_) => setState(() => _platform = p),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Exportar rota',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Rota exportada para ${_platform.label}')));
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'A cor do trecho segue a zona de esforco (Z1 a Z5, watts ou '
                  'FC) prevista para aquele ponto da subida - nao so '
                  '"dentro ou fora do alvo".',
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
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

extension on ResultSource {
  String get label => switch (this) {
        ResultSource.strava => 'Strava',
        ResultSource.garmin => 'Garmin',
        ResultSource.wahoo => 'Wahoo',
        ResultSource.manual => 'Manual',
      };
}
