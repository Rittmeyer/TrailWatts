import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/zone.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 02a - "Criar treino". One scrollable block editor: each
/// card is a prescribed stimulus (zone, duration, repetitions, target,
/// recovery). The prototype shows this as several phone-frames because a
/// phone screen is short - here it is one screen the rider scrolls,
/// exactly like screens 02b(1/3-2/3) demonstrate with a 3-block example.
class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _BlockForm {
  Zone zone;
  final TextEditingController duration;
  final TextEditingController repetitions;
  final TextEditingController minTarget;
  final TextEditingController maxTarget;
  final TextEditingController rest;

  _BlockForm({
    this.zone = Zone.limiar,
    String duration = '8',
    String repetitions = '4',
    String minTarget = '170',
    String maxTarget = '190',
    String rest = '2',
  })  : duration = TextEditingController(text: duration),
        repetitions = TextEditingController(text: repetitions),
        minTarget = TextEditingController(text: minTarget),
        maxTarget = TextEditingController(text: maxTarget),
        rest = TextEditingController(text: rest);

  void dispose() {
    duration.dispose();
    repetitions.dispose();
    minTarget.dispose();
    maxTarget.dispose();
    rest.dispose();
  }
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  int _metric = 0; // 0 = Watts, 1 = FC
  final List<_BlockForm> _blocks = [_BlockForm()];

  @override
  void dispose() {
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _addBlock() {
    setState(() => _blocks.add(_BlockForm(
          zone: Zone.resistencia,
          duration: '10',
          repetitions: '1',
          minTarget: '140',
          maxTarget: '160',
          rest: '0',
        )));
  }

  @override
  Widget build(BuildContext context) {
    final unit = _metric == 0 ? 'w' : 'bpm';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Criar treino',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Monte o treino e marque onde pedalar',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 16),
                SegmentedControl(
                  options: const ['Watts', 'FC'],
                  selectedIndex: _metric,
                  onChanged: (i) => setState(() => _metric = i),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _blocks.length; i++) ...[
                  _BlockCard(
                    index: i,
                    form: _blocks[i],
                    unit: unit,
                    onZoneChanged: (z) => setState(() => _blocks[i].zone = z),
                  ),
                  const SizedBox(height: 12),
                ],
                TrailwattButton(
                  label: '+ Adicionar serie',
                  style: TrailwattButtonStyle.dashed,
                  onPressed: _addBlock,
                ),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Continuar',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/workout-builder/map'),
                ),
                const SizedBox(height: 14),
                Text(
                  'O nome do bloco usa a mesma nomenclatura de zona do resto '
                  'do app. O treino e soberano - a rota se adapta ao '
                  'estimulo, nao o contrario.',
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

class _BlockCard extends StatelessWidget {
  final int index;
  final _BlockForm form;
  final String unit;
  final ValueChanged<Zone> onZoneChanged;

  const _BlockCard({
    required this.index,
    required this.form,
    required this.unit,
    required this.onZoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BLOCO ${index + 1}',
              style: AppTextStyles.label.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.0,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Zona', style: AppTextStyles.label),
          const SizedBox(height: 4),
          DropdownButtonFormField<Zone>(
            value: form.zone,
            isExpanded: true,
            style: AppTextStyles.body,
            decoration: const InputDecoration(),
            items: Zone.values
                .map((z) =>
                    DropdownMenuItem(value: z, child: Text(z.pickerLabel)))
                .toList(),
            onChanged: (z) {
              if (z != null) onZoneChanged(z);
            },
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: TrailwattField(
                  label: 'Duracao (min)',
                  controller: form.duration,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrailwattField(
                  label: 'Repeticoes',
                  controller: form.repetitions,
                  keyboardType: TextInputType.number,
                  helperText: '1 = sem repeticao',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TrailwattField(
                  label: 'Minimo ($unit)',
                  controller: form.minTarget,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrailwattField(
                  label: 'Maximo ($unit)',
                  controller: form.maxTarget,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          TrailwattField(
            label: 'Descanso entre series (min)',
            controller: form.rest,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
