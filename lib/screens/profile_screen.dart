import 'package:flutter/material.dart';
import '../models/rider_profile.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';
import '../widgets/zone_table_editor.dart';

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
  final _hrAnchorController = TextEditingController(text: '168');

  ZoneScale _powerScale = ZoneScale.seven;
  ZoneScale _hrScale = ZoneScale.five;
  HeartRateAnchor _hrAnchor = HeartRateAnchor.lactateThreshold;

  /// Null while the generic percentage table is in use.
  List<int>? _powerBounds;
  List<int>? _hrBounds;

  bool _powerBoundsValid = true;
  bool _hrBoundsValid = true;

  PowerZoneSettings get _powerSettings => PowerZoneSettings(
        scale: _powerScale,
        customLowerBoundsWatts: _powerBounds,
      );

  HeartRateZoneSettings get _hrSettings => HeartRateZoneSettings(
        scale: _hrScale,
        anchor: _hrAnchor,
        lthrBpm:
            _hrAnchor == HeartRateAnchor.lactateThreshold ? _hrAnchorBpm : null,
        hrMaxBpm: _hrAnchor == HeartRateAnchor.maximum ? _hrAnchorBpm : null,
        customLowerBoundsBpm: _hrBounds,
      );

  bool get _canSave => _powerBoundsValid && _hrBoundsValid;

  @override
  void dispose() {
    _weightController.dispose();
    _ftpController.dispose();
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
                  onChanged: (i) => setState(() {
                    _powerScale = i == 0 ? ZoneScale.five : ZoneScale.seven;
                    // Custom bounds are per-scale; a 7-zone table cannot be
                    // reused as a 5-zone one, so fall back to generic.
                    _powerBounds = null;
                    _powerBoundsValid = true;
                  }),
                ),
                const SizedBox(height: 10),
                ZoneTableEditor(
                  table: ZoneTables.of(ZoneMetric.power, _powerScale),
                  bounds: _powerBounds,
                  derivedBounds: _powerSettings.derivedBounds(_ftp),
                  unit: 'w',
                  onChanged: (b) => setState(() => _powerBounds = b),
                  onValidityChanged: (v) =>
                      setState(() => _powerBoundsValid = v),
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
                  onChanged: (i) => setState(() {
                    _hrScale = i == 0 ? ZoneScale.five : ZoneScale.seven;
                    _hrBounds = null;
                    _hrBoundsValid = true;
                  }),
                ),
                const SizedBox(height: 10),
                Text('Ancorar em', style: AppTextStyles.label),
                const SizedBox(height: 4),
                SegmentedControl(
                  options: const ['Limiar (LTHR)', 'FC maxima'],
                  selectedIndex:
                      _hrAnchor == HeartRateAnchor.lactateThreshold ? 0 : 1,
                  onChanged: (i) => setState(() {
                    _hrAnchor = i == 0
                        ? HeartRateAnchor.lactateThreshold
                        : HeartRateAnchor.maximum;
                    // A different anchor means a different generic table.
                    _hrBounds = null;
                    _hrBoundsValid = true;
                  }),
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
                  ZoneTableEditor(
                    table: ZoneTables.of(ZoneMetric.heartRate, _hrScale,
                        anchor: _hrAnchor),
                    bounds: _hrBounds,
                    derivedBounds: _hrSettings.derivedBounds(),
                    unit: 'bpm',
                    provisional: true,
                    onChanged: (b) => setState(() => _hrBounds = b),
                    onValidityChanged: (v) =>
                        setState(() => _hrBoundsValid = v),
                  ),

                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Salvar perfil',
                  onPressed: _canSave
                      ? () =>
                          Navigator.of(context).pushNamed('/workout-builder')
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  'Peso e FTP bastam para o motor funcionar. As zonas podem '
                  'ficar nas faixas genericas ou ser ajustadas a mao.',
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
