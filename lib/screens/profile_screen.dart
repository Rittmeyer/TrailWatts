import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of the "Criar perfil" screen. Weight and FTP are the only
/// required inputs the physics engine needs (Constitution Article I);
/// the power curve is optional and refines short/intense stimuli.
/// Import stays read-scoped and optional (Constitution Article II).
///
/// Power and heart-rate zones are configured separately: they are different
/// tables, each with its own zone count, and heart rate additionally needs
/// its own anchor.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _weightController = TextEditingController(text: '74');
  final _ftpController = TextEditingController(text: '210');
  final _power5sController = TextEditingController();
  final _power1minController = TextEditingController();
  final _power5minController = TextEditingController();
  final _hrAnchorController = TextEditingController(text: '168');

  ZoneScale _powerScale = ZoneScale.seven;
  ZoneScale _hrScale = ZoneScale.five;
  HeartRateAnchor _hrAnchor = HeartRateAnchor.lactateThreshold;

  @override
  void dispose() {
    _weightController.dispose();
    _ftpController.dispose();
    _power5sController.dispose();
    _power1minController.dispose();
    _power5minController.dispose();
    _hrAnchorController.dispose();
    super.dispose();
  }

  int get _ftp => int.tryParse(_ftpController.text) ?? 0;
  int? get _hrAnchorBpm => int.tryParse(_hrAnchorController.text);

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
                Text('Criar perfil',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Peso e FTP obrigatorios. O resto e opcional.',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 20),
                TrailwattField(
                  label: 'Peso (kg)',
                  hint: '74',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'FTP (watts)',
                  hint: '210',
                  controller: _ftpController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),

                // --- Power zones -----------------------------------------
                const _SectionLabel('ZONAS DE POTENCIA'),
                Text('Ancoradas no FTP', style: AppTextStyles.label),
                const SizedBox(height: 6),
                SegmentedControl(
                  options: const ['Z1-Z5', 'Z1-Z7'],
                  selectedIndex: _powerScale == ZoneScale.five ? 0 : 1,
                  onChanged: (i) => setState(() =>
                      _powerScale = i == 0 ? ZoneScale.five : ZoneScale.seven),
                ),
                const SizedBox(height: 10),
                _ZonePreview(
                  table: ZoneTables.of(ZoneMetric.power, _powerScale),
                  anchor: _ftp,
                  unit: 'w',
                ),

                // --- Heart-rate zones ------------------------------------
                const _SectionLabel('ZONAS DE FREQUENCIA CARDIACA'),
                Text(
                  'Tabela separada da de potencia - o mesmo esforco cai em '
                  'zonas diferentes nas duas.',
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.4),
                ),
                const SizedBox(height: 8),
                SegmentedControl(
                  options: const ['Z1-Z5', 'Z1-Z7'],
                  selectedIndex: _hrScale == ZoneScale.five ? 0 : 1,
                  onChanged: (i) => setState(() =>
                      _hrScale = i == 0 ? ZoneScale.five : ZoneScale.seven),
                ),
                const SizedBox(height: 10),
                Text('Ancorar em', style: AppTextStyles.label),
                const SizedBox(height: 4),
                SegmentedControl(
                  options: const ['Limiar (LTHR)', 'FC maxima'],
                  selectedIndex:
                      _hrAnchor == HeartRateAnchor.lactateThreshold ? 0 : 1,
                  onChanged: (i) => setState(() => _hrAnchor = i == 0
                      ? HeartRateAnchor.lactateThreshold
                      : HeartRateAnchor.maximum),
                ),
                const SizedBox(height: 10),
                TrailwattField(
                  label: _hrAnchor == HeartRateAnchor.lactateThreshold
                      ? 'FC de limiar (bpm)'
                      : 'FC maxima (bpm)',
                  hint: 'opcional',
                  controller: _hrAnchorController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                if (_hrAnchorBpm == null)
                  Text(
                    'Sem esta medida o app nao calcula zonas de FC - e nao '
                    'inventa: o treino em watts continua funcionando.',
                    style: AppTextStyles.label
                        .copyWith(fontSize: 9, color: AppColors.warnText),
                  )
                else
                  _ZonePreview(
                    table: ZoneTables.of(ZoneMetric.heartRate, _hrScale,
                        anchor: _hrAnchor),
                    anchor: _hrAnchorBpm!,
                    unit: 'bpm',
                    provisional: true,
                  ),

                // --- Power curve -----------------------------------------
                const _SectionLabel('CURVA DE POTENCIA'),
                TrailwattField(
                  label: 'Potencia 5s (w)',
                  hint: 'opcional · ex: 850',
                  controller: _power5sController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'Potencia 1min (w)',
                  hint: 'opcional · ex: 420',
                  controller: _power1minController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'Potencia 5min (w)',
                  hint: 'opcional · ex: 260',
                  controller: _power5minController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TrailwattButton(
                  label: 'Importar do Strava/Garmin',
                  style: TrailwattButtonStyle.secondary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Conexao opcional - preenche a curva via API')));
                  },
                ),
                const SizedBox(height: 4),
                Text('preenche a curva via API',
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Salvar perfil',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/workout-builder'),
                ),
                const SizedBox(height: 14),
                Text(
                  'Peso e FTP bastam para o motor funcionar. A curva de '
                  'potencia refina estimulos curtos e intensos, e pode vir '
                  'da API em vez de digitada a mao.',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Text(text,
          style: AppTextStyles.label.copyWith(
              fontSize: 9,
              letterSpacing: 1.0,
              color: AppColors.primary,
              fontWeight: FontWeight.w700)),
    );
  }
}

/// The resulting table, so the rider sees the actual watts/bpm each zone
/// covers instead of trusting an abstract percentage.
class _ZonePreview extends StatelessWidget {
  final ZoneTable table;
  final num anchor;
  final String unit;
  final bool provisional;

  const _ZonePreview({
    required this.table,
    required this.anchor,
    required this.unit,
    this.provisional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final z in table.zones)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 8),
                    decoration:
                        BoxDecoration(color: z.color, shape: BoxShape.circle),
                  ),
                  SizedBox(
                    width: 22,
                    child: Text(z.code,
                        style: AppTextStyles.numeric.copyWith(fontSize: 10)),
                  ),
                  Expanded(
                    child: Text(z.label,
                        style: AppTextStyles.label.copyWith(fontSize: 10)),
                  ),
                  Text(z.rangeLabel(anchor, unit),
                      style: AppTextStyles.numeric.copyWith(fontSize: 10)),
                ],
              ),
            ),
          if (provisional) ...[
            const SizedBox(height: 4),
            Text(
              'Faixas genericas, pendentes de revisao fisiologica. Podem ser '
              'editadas manualmente.',
              style: AppTextStyles.label.copyWith(fontSize: 8, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
