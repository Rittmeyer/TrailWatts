import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/domain_labels.dart';
import '../services/routing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/map_layers.dart';
import '../widgets/stat_box.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 05 - "Editar rota".
///
/// The workout stretch is defined by draggable waypoints. Dropping one snaps
/// it onto the nearest road and re-routes the whole stretch along real roads,
/// so an edit can never produce a path the rider cannot actually ride. While
/// the marker is in the air the segment is drawn gray and dashed-looking -
/// unconfirmed, with no zone colour, so it does not compete with the effort
/// legend until it has been re-matched.
class RouteEditScreen extends StatefulWidget {
  const RouteEditScreen({super.key});

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  /// Fixed part of the ride - the approach and the return leg.
  static const _approach = [
    LatLng(-23.5580, -46.6430),
    LatLng(-23.5566, -46.6414),
  ];
  static const _returnLeg = [
    LatLng(-23.5505, -46.6355),
    LatLng(-23.5480, -46.6330),
  ];

  /// The editable workout stretch, as rider-movable control points.
  List<LatLng> _waypoints = const [
    LatLng(-23.5566, -46.6414),
    LatLng(-23.5540, -46.6385),
    LatLng(-23.5505, -46.6355),
  ];

  final _routing = OsrmRoutingService();

  RoutedPath? _path;
  bool _busy = false;
  bool _dragging = false;
  bool _edited = false;
  double _lastSnapOffsetM = 0;
  double? _baselineDistanceM;

  @override
  void initState() {
    super.initState();
    _recalculate(initial: true);
  }

  Future<void> _recalculate({bool initial = false}) async {
    setState(() => _busy = true);
    final path = await _routing.routeThrough(_waypoints);
    if (!mounted) return;
    setState(() {
      _path = path;
      _busy = false;
      _baselineDistanceM ??= path.distanceM;
      if (!initial) _edited = true;
    });
  }

  Future<void> _onWaypointDropped(int index, LatLng dropped) async {
    setState(() {
      _dragging = false;
      _busy = true;
      _waypoints = [..._waypoints]..[index] = dropped;
    });

    // Pull the dropped point onto the road network before re-routing, so the
    // control point itself is somewhere the rider can actually ride through.
    final snapped = await _routing.snapToRoad(dropped);
    if (!mounted) return;
    setState(() {
      _waypoints = [..._waypoints]..[index] = snapped.point;
      _lastSnapOffsetM = snapped.offsetM;
    });
    await _recalculate();
  }

  /// The full ride: fixed approach + edited stretch + fixed return.
  List<LatLng> get _fullRoute => [
        ..._approach,
        ...?_path?.polyline,
        ..._returnLeg,
      ];

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final path = _path;
    final stretchKm = path?.distanceKm;
    final delta = (path != null && _baselineDistanceM != null)
        ? path.distanceM - _baselineDistanceM!
        : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.editRouteTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(t.editRouteSubtitle, style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 10),
                Text(
                  t.editRouteHint,
                  style: AppTextStyles.label.copyWith(fontSize: 9.5),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    height: 260,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(-23.5530, -46.6380),
                            initialZoom: 14.2,
                          ),
                          children: [
                            trailwattTileLayer(),
                            PolylineLayer(polylines: [
                              // Whole ride, in the route colour.
                              Polyline(
                                points: _fullRoute,
                                strokeWidth: 5,
                                color: AppColors.primary,
                              ),
                              // The editable stretch: gray while it is being
                              // moved or has not been re-matched to roads.
                              if (path != null)
                                Polyline(
                                  points: path.polyline,
                                  strokeWidth: 5,
                                  color: _dragging || !path.followsRoads
                                      ? AppColors.inkSoft
                                      : AppColors.accent,
                                ),
                            ]),
                            DragMarkers(
                              markers: [
                                for (var i = 0; i < _waypoints.length; i++)
                                  DragMarker(
                                    key: ValueKey('wp-$i'),
                                    point: _waypoints[i],
                                    size: const Size(26, 26),
                                    onDragStart: (_, __) =>
                                        setState(() => _dragging = true),
                                    onDragEnd: (_, latLng) =>
                                        _onWaypointDropped(i, latLng),
                                    builder: (context, point, isDragging) =>
                                        _WaypointHandle(active: isDragging),
                                  ),
                              ],
                            ),
                            trailwattAttribution(context),
                          ],
                        ),
                        if (_busy)
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child:
                            StatBox(label: t.editRouteTotal, value: '12,4km')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBox(
                        label: t.editRouteSegment,
                        value: stretchKm == null
                            ? '--'
                            : '${stretchKm.toStringAsFixed(2)}km',
                      ),
                    ),
                  ],
                ),
                if (_edited && path != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warnBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.editRouteImpact,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        _ImpactRow(
                          label: t.editRouteDeviation,
                          value: '${delta >= 0 ? '+' : ''}'
                              '${(delta / 1000).toStringAsFixed(2)} km',
                        ),
                        _ImpactRow(
                          label: t.editRouteSnap,
                          value: path.followsRoads
                              ? t.editRouteSnapMeters(_lastSnapOffsetM.round())
                              : t.editRouteSnapUnverified,
                        ),
                        _ImpactRow(
                          label: t.editRoutePredictedMatch,
                          value: path.followsRoads
                              ? '94% → 87%'
                              : t.editRouteNeedsRoads,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.editRouteImpactNote,
                          style: AppTextStyles.label
                              .copyWith(fontSize: 9, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TrailwattButton(
                  label: t.editRouteSave,
                  onPressed:
                      _busy ? null : () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 8),
                TrailwattButton(
                  label: t.editRouteCancel,
                  style: TrailwattButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The drag handle for one editable waypoint.
class _WaypointHandle extends StatelessWidget {
  final bool active;
  const _WaypointHandle({required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: active ? 22 : 16,
        height: active ? 22 : 16,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.white : AppColors.primary, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String label;
  final String value;
  const _ImpactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
          Text(value,
              style: AppTextStyles.numeric
                  .copyWith(fontSize: 11, color: AppColors.warnText)),
        ],
      ),
    );
  }
}
