import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../l10n/domain_labels.dart';
import '../models/rider_profile.dart';
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
  /// Zone index within whichever table the selected metric uses.
  int zoneIndex;
  final TextEditingController duration;
  final TextEditingController repetitions;
  final TextEditingController minTarget;
  final TextEditingController maxTarget;
  final TextEditingController rest;

  _BlockForm({
    this.zoneIndex = 4,
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
  /// Which table the whole workout is prescribed against. Power and heart
  /// rate are separate tables with their own zone counts, so switching this
  /// switches the zone list too.
  ZoneMetric _metric = ZoneMetric.power;

  /// The demo rider's profile: 7 power zones, 5 heart-rate zones anchored on
  /// threshold HR. In the real app this comes from the saved RiderProfile.
  static const _rider = RiderProfile(
    weightKg: 74,
    ftpWatts: 210,
    powerZones: PowerZoneSettings(scale: ZoneScale.seven),
    heartRateZones: HeartRateZoneSettings(
      scale: ZoneScale.five,
      anchor: HeartRateAnchor.lactateThreshold,
      lthrBpm: 168,
      hrMaxBpm: 184,
    ),
  );

  final List<_BlockForm> _blocks = [_BlockForm()];

  ZoneScale get _scale => _metric == ZoneMetric.power
      ? _rider.powerZones.scale
      : _rider.heartRateZones!.scale;

  ZoneTable get _table =>
      ZoneTables.of(_metric, _scale, anchor: _rider.heartRateZones!.anchor);

  /// Absolute range for a zone on the active table, e.g. "191-222 w".
  String _rangeLabel(int index) {
    if (_metric == ZoneMetric.power) {
      final min = _rider.powerZones.lowerBoundWatts(index, _rider.ftpWatts);
      final max = _rider.powerZones.upperBoundWatts(index, _rider.ftpWatts);
      return max == null ? '≥ $min w' : '$min-$max w';
    }
    final hr = _rider.heartRateZones!;
    final min = hr.lowerBoundBpm(index);
    final max = hr.upperBoundBpm(index);
    if (min == null) return 'sem âncora de FC';
    return max == null ? '≥ $min bpm' : '$min-$max bpm';
  }

  @override
  void dispose() {
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _addBlock() {
    setState(() => _blocks.add(_BlockForm(
          zoneIndex: 2,
          duration: '10',
          repetitions: '1',
          minTarget: '140',
          maxTarget: '160',
          rest: '0',
        )));
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final unit = _metric.unit(t);
    final table = _table;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.builderTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(t.builderSubtitle, style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 16),
                SegmentedControl(
                  options: [t.builderWatts, t.builderHr],
                  selectedIndex: _metric == ZoneMetric.power ? 0 : 1,
                  onChanged: (i) => setState(() {
                    _metric = i == 0 ? ZoneMetric.power : ZoneMetric.heartRate;
                    // Zone counts differ between the tables, so clamp any
                    // selection that no longer exists on the new one.
                    final max = _scale.count;
                    for (final b in _blocks) {
                      if (b.zoneIndex > max) b.zoneIndex = max;
                    }
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  t.builderTableLabel(
                      _metric.label(t).toLowerCase(), _scale.count),
                  style: AppTextStyles.label.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _blocks.length; i++) ...[
                  _BlockCard(
                    index: i,
                    form: _blocks[i],
                    unit: unit,
                    table: table,
                    rangeLabel: _rangeLabel,
                    onZoneChanged: (z) =>
                        setState(() => _blocks[i].zoneIndex = z),
                  ),
                  const SizedBox(height: 12),
                ],
                TrailwattButton(
                  label: t.builderAddSet,
                  style: TrailwattButtonStyle.dashed,
                  onPressed: _addBlock,
                ),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: t.builderContinue,
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/workout-builder/map'),
                ),
                const SizedBox(height: 14),
                Text(
                  t.builderFootnote,
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
  final ZoneTable table;
  final String Function(int zoneIndex) rangeLabel;
  final ValueChanged<int> onZoneChanged;

  const _BlockCard({
    required this.index,
    required this.form,
    required this.unit,
    required this.table,
    required this.rangeLabel,
    required this.onZoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.builderBlock(index + 1),
              style: AppTextStyles.label.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.0,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(t.builderZone, style: AppTextStyles.label),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: form.zoneIndex,
            isExpanded: true,
            style: AppTextStyles.body,
            decoration: const InputDecoration(),
            items: table.zones
                .map((z) => DropdownMenuItem(
                      value: z.index,
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                                color: z.color, shape: BoxShape.circle),
                          ),
                          Expanded(child: Text(z.pickerLabel(t))),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (z) {
              if (z != null) onZoneChanged(z);
            },
          ),
          const SizedBox(height: 3),
          Text(rangeLabel(form.zoneIndex),
              style: AppTextStyles.label.copyWith(fontSize: 9)),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: TrailwattField(
                  label: t.builderDuration,
                  controller: form.duration,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrailwattField(
                  label: t.builderRepetitions,
                  controller: form.repetitions,
                  keyboardType: TextInputType.number,
                  helperText: t.builderRepetitionsHelp,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TrailwattField(
                  label: t.builderMin(unit),
                  controller: form.minTarget,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrailwattField(
                  label: t.builderMax(unit),
                  controller: form.maxTarget,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          TrailwattField(
            label: t.builderRest,
            controller: form.rest,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
