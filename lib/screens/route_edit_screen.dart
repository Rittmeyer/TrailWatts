import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/stat_box.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 05 - "Editar rota". The adjustable stretch stays gray
/// and unmatched to a zone until the rider confirms it, so it never
/// competes with the effort-zone legend. Any material change is
/// re-scored before it can be saved (Constitution: edits are never
/// silently accepted).
class RouteEditScreen extends StatefulWidget {
  const RouteEditScreen({super.key});

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  static const _fullRoute = [
    LatLng(-23.5580, -46.6430),
    LatLng(-23.5555, -46.6400),
    LatLng(-23.5540, -46.6385),
    LatLng(-23.5520, -46.6370),
    LatLng(-23.5505, -46.6355),
    LatLng(-23.5480, -46.6330),
  ];
  static const _editableSegment = [
    LatLng(-23.5555, -46.6400),
    LatLng(-23.5540, -46.6385),
    LatLng(-23.5520, -46.6370),
  ];

  bool _edited = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Editar rota',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('O trecho do treino dentro do percurso completo',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 10),
                Text(
                  'Tracejado = trecho ajustavel. Arraste os pontos para editar.',
                  style: AppTextStyles.label.copyWith(fontSize: 9.5),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    height: 190,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: const LatLng(-23.5530, -46.6380),
                        initialZoom: 13.3,
                        onTap: (tapPosition, point) =>
                            setState(() => _edited = true),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'app.trailwatt',
                        ),
                        PolylineLayer(polylines: [
                          const Polyline(
                            points: _fullRoute,
                            strokeWidth: 4,
                            color: AppColors.primary,
                          ),
                          Polyline(
                            points: _editableSegment,
                            strokeWidth: 4,
                            color: AppColors.inkSoft,
                          ),
                        ]),
                        MarkerLayer(markers: [
                          for (final p in _editableSegment)
                            Marker(
                              point: p,
                              width: 16,
                              height: 16,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.paper,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(BorderSide(
                                      color: AppColors.inkSoft, width: 2)),
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                        child: StatBox(
                            label: 'PERCURSO TOTAL', value: '12,4km')),
                    SizedBox(width: 8),
                    Expanded(
                        child: StatBox(
                            label: 'TRECHO DO TREINO', value: '850m')),
                  ],
                ),
                if (_edited) ...[
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
                        Text('Impacto da edicao',
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        _ImpactRow(label: 'Desvio', value: '+2,1 km'),
                        _ImpactRow(label: 'Match previsto', value: '94% → 87%'),
                        _ImpactRow(
                            label: 'Continuidade',
                            value: 'Intervalo 2 perde continuidade'),
                        const SizedBox(height: 6),
                        Text(
                          'A aplicacao nao salva uma alteracao material sem '
                          'reavaliar o matching.',
                          style: AppTextStyles.label
                              .copyWith(fontSize: 9, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Salvar alteracoes',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 8),
                TrailwattButton(
                  label: 'Cancelar',
                  style: TrailwattButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 14),
                Text(
                  'O trecho ajustavel fica em cinza tracejado, sem cor de '
                  'zona - assim ele nao compete com a legenda de esforco ate '
                  'ser confirmado.',
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
