import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/routing_service.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/page_header.dart';
import '../widgets/map_layers.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 02b(3/3) - "Onde treinar". One map for the whole
/// workout, whatever the number of blocks above. Tap anywhere on the map
/// to move the pin - it settles onto the nearest road, so the search is
/// always centred somewhere rideable. The radius is rider-editable, 8 km
/// by default per DECISIONS_REQUIRED.md.
class WorkoutLocationScreen extends StatefulWidget {
  const WorkoutLocationScreen({super.key});

  @override
  State<WorkoutLocationScreen> createState() => _WorkoutLocationScreenState();
}

class _WorkoutLocationScreenState extends State<WorkoutLocationScreen> {
  LatLng _center = const LatLng(-23.5505, -46.6333);
  double _radiusKm = 8;

  final _routing = OsrmRoutingService();
  bool _snapping = false;

  /// Drop the pin where the rider tapped, then settle it onto the nearest
  /// road so the search starts from somewhere they can actually ride.
  Future<void> _placePin(LatLng tapped) async {
    setState(() {
      _center = tapped;
      _snapping = true;
    });
    final snapped = await _routing.snapToRoad(tapped);
    if (!mounted) return;
    setState(() {
      _center = snapped.point;
      _snapping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      body: ContentWidth(
          maxWidth: ContentWidth.wide,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: t.locationTitle,
                    subtitle: t.locationSubtitle,
                    backTo: t.builderTitle,
                  ),
                  const SizedBox(height: 12),
                  Text(t.locationWhere,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _center,
                              initialZoom: 12,
                              onTap: (tapPosition, point) => _placePin(point),
                            ),
                            children: [
                              trailwattTileLayer(),
                              CircleLayer(circles: [
                                CircleMarker(
                                  point: _center,
                                  radius: _radiusKm * 1000,
                                  useRadiusInMeter: true,
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderColor: AppColors.accent,
                                  borderStrokeWidth: 1.5,
                                ),
                              ]),
                              MarkerLayer(markers: [
                                Marker(
                                  point: _center,
                                  width: 32,
                                  height: 32,
                                  child: const Icon(Icons.location_on,
                                      color: AppColors.primary, size: 32),
                                ),
                              ]),
                              trailwattAttribution(context),
                            ],
                          ),
                          if (_snapping)
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
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.locationHint(_radiusKm.round()),
                                style:
                                    AppTextStyles.label.copyWith(fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 3,
                    max: 20,
                    divisions: 17,
                    activeColor: AppColors.accent,
                    label: '${_radiusKm.round()} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                  const SizedBox(height: 8),
                  TrailwattButton(
                    label: t.locationGenerate,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/route-map'),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
