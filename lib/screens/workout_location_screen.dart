import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 02b(3/3) - "Onde treinar". One map for the whole
/// workout, whatever the number of blocks above. Tap anywhere on the map
/// to move the pin (stands in for the prototype's drag gesture); the
/// radius is rider-editable, 8 km by default per DECISIONS_REQUIRED.md.
class WorkoutLocationScreen extends StatefulWidget {
  const WorkoutLocationScreen({super.key});

  @override
  State<WorkoutLocationScreen> createState() => _WorkoutLocationScreenState();
}

class _WorkoutLocationScreenState extends State<WorkoutLocationScreen> {
  LatLng _center = const LatLng(-23.5505, -46.6333);
  double _radiusKm = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criar treino',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text('Continuacao - onde treinar', style: AppTextStyles.screenSubtitle),
              const SizedBox(height: 12),
              Text('ONDE TREINAR',
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
                          onTap: (tapPosition, point) =>
                              setState(() => _center = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'app.trailwatt',
                          ),
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
                        ],
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
                            'Toque no mapa para marcar a area · raio ${_radiusKm.round()}km',
                            style: AppTextStyles.label.copyWith(fontSize: 9),
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
                label: 'Gerar sugestoes de rota',
                onPressed: () => Navigator.of(context).pushNamed('/route-map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
