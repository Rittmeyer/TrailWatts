import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 02a - "Criar treino".
///
/// The workout is an ordered list of blocks, and that order is the timeline.
/// Recovery is a block like any other - "4x8min Z4 with 2min easy" is built as
/// Z4, Z1, Z4, Z1, Z4, Z1, Z4 - so nothing about the prescription is hidden
/// inside a field on another block.
class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _BlockForm {
  WorkoutBlockRole role;

  /// Zone index within whichever table the selected metric uses.
  int zoneIndex;
  final TextEditingController duration;
  final TextEditingController minTarget;
  final TextEditingController maxTarget;

  _BlockForm({
    this.role = WorkoutBlockRole.work,
    this.zoneIndex = 4,
    String duration = '8',
    String minTarget = '170',
    String maxTarget = '190',
  })  : duration = TextEditingController(text: duration),
        minTarget = TextEditingController(text: minTarget),
        maxTarget = TextEditingController(text: maxTarget);

  _BlockForm.from(_BlockForm other)
      : role = other.role,
        zoneIndex = other.zoneIndex,
        duration = TextEditingController(text: other.duration.text),
        minTarget = TextEditingController(text: other.minTarget.text),
        maxTarget = TextEditingController(text: other.maxTarget.text);

  int get durationMin => int.tryParse(duration.text) ?? 0;

  void dispose() {
    duration.dispose();
    minTarget.dispose();
    maxTarget.dispose();
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

  /// Seeded as the worked example: a threshold block followed by its own
  /// recovery block.
  final List<_BlockForm> _blocks = [
    _BlockForm(),
    _BlockForm(
      role: WorkoutBlockRole.recovery,
      zoneIndex: 1,
      duration: '2',
      minTarget: '90',
      maxTarget: '110',
    ),
  ];

  ZoneScale get _scale => _metric == ZoneMetric.power
      ? _rider.powerZones.scale
      : _rider.heartRateZones!.scale;

  ZoneTable get _table =>
      ZoneTables.of(_metric, _scale, anchor: _rider.heartRateZones!.anchor);

  int get _totalMinutes => _blocks.fold(0, (sum, b) => sum + b.durationMin);

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
    if (min == null) return '';
    return max == null ? '≥ $min bpm' : '$min-$max bpm';
  }

  @override
  void dispose() {
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _addBlock() => setState(() => _blocks.add(_BlockForm(
        zoneIndex: 2,
        duration: '10',
        minTarget: '140',
        maxTarget: '160',
      )));

  void _duplicate(int i) =>
      setState(() => _blocks.insert(i + 1, _BlockForm.from(_blocks[i])));

  void _remove(int i) => setState(() => _blocks.removeAt(i).dispose());

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.builderTableLabel(
                          _metric.label(t).toLowerCase(), _scale.count),
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                    Text(t.builderTotalDuration(_totalMinutes),
                        style: AppTextStyles.numeric.copyWith(fontSize: 10)),
                  ],
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
                    onRoleChanged: (r) => setState(() => _blocks[i].role = r),
                    onDurationChanged: () => setState(() {}),
                    onDuplicate: () => _duplicate(i),
                    onRemove: _blocks.length > 1 ? () => _remove(i) : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TrailwattButton(
                  label: t.builderAddBlock,
                  style: TrailwattButtonStyle.dashed,
                  onPressed: _addBlock,
                ),
                const SizedBox(height: 10),
                Text(t.builderSequenceNote,
                    style:
                        AppTextStyles.label.copyWith(fontSize: 9, height: 1.5)),
                const SizedBox(height: 16),
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
  final ValueChanged<WorkoutBlockRole> onRoleChanged;
  final VoidCallback onDurationChanged;
  final VoidCallback onDuplicate;
  final VoidCallback? onRemove;

  const _BlockCard({
    required this.index,
    required this.form,
    required this.unit,
    required this.table,
    required this.rangeLabel,
    required this.onZoneChanged,
    required this.onRoleChanged,
    required this.onDurationChanged,
    required this.onDuplicate,
    required this.onRemove,
  });

  static String _roleLabel(WorkoutBlockRole role, AppLocalizations t) =>
      switch (role) {
        WorkoutBlockRole.warmUp => t.builderRoleWarmUp,
        WorkoutBlockRole.work => t.builderRoleWork,
        WorkoutBlockRole.recovery => t.builderRoleRecovery,
        WorkoutBlockRole.coolDown => t.builderRoleCoolDown,
      };

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final zone = table.byIndex(form.zoneIndex);
    // Recovery reads as a lighter card, so the alternation between work and
    // recovery is visible at a glance down the list.
    final isRecovery = form.role == WorkoutBlockRole.recovery;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecovery ? AppColors.paper : null,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(right: 7),
                decoration:
                    BoxDecoration(color: zone.color, shape: BoxShape.circle),
              ),
              Text(t.builderBlock(index + 1),
                  style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              _TinyAction(label: t.builderDuplicate, onTap: onDuplicate),
              if (onRemove != null) ...[
                const SizedBox(width: 10),
                _TinyAction(label: t.builderRemove, onTap: onRemove!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.builderRole, style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<WorkoutBlockRole>(
                      value: form.role,
                      isExpanded: true,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(),
                      items: WorkoutBlockRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(_roleLabel(r, t),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (r) {
                        if (r != null) onRoleChanged(r);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                child: Text(z.pickerLabel(t),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (z) {
                        if (z != null) onZoneChanged(z);
                      },
                    ),
                  ],
                ),
              ),
            ],
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
                  onChanged: (_) => onDurationChanged(),
                ),
              ),
              const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TinyAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: AppTextStyles.label.copyWith(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.w700)),
    );
  }
}
