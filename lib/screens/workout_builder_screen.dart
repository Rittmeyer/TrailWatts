import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import '../services/integrations_store.dart';
import '../services/platform/platform_api_client.dart';
import '../services/training_peaks_import.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 02a - "Criar treino".
///
/// The workout is an ordered list of blocks, and that order is the timeline.
/// Recovery is a block like any other. A block itself MAY hold two or more
/// stimuli - e.g. a Z4 work stimulus and its Z1 recovery - held together and
/// optionally repeated as one unit, so "4x8min Z4 with 2min easy" is one
/// block typed out once and repeated 4 times, not eight separate blocks.
///
/// The rider's preferred workout can also be pulled in from TrainingPeaks
/// via the floating action button below; without a TrainingPeaks
/// connection it falls back to the manual builder already on screen.
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

  factory _BlockForm.fromModel(WorkoutBlock block) => _BlockForm(
        role: block.role,
        zoneIndex: block.zone.index,
        duration: '${block.durationMin}',
        minTarget: '${block.target.minValue}',
        maxTarget: '${block.target.maxValue}',
      );

  int get durationMin => int.tryParse(duration.text) ?? 0;

  void dispose() {
    duration.dispose();
    minTarget.dispose();
    maxTarget.dispose();
  }
}

/// A block as authored on screen: one or more stimuli held together and
/// repeated `repeatCount` times. Mirrors `WorkoutBlockGroup` one-to-one -
/// see `lib/models/workout_block.dart` for why the group exists.
class _GroupForm {
  List<_BlockForm> stimuli;
  final TextEditingController repeat;

  _GroupForm({
    List<_BlockForm>? stimuli,
    String repeat = '1',
  })  : stimuli = stimuli ?? [_BlockForm()],
        repeat = TextEditingController(text: repeat);

  _GroupForm.from(_GroupForm other)
      : stimuli = [for (final b in other.stimuli) _BlockForm.from(b)],
        repeat = TextEditingController(text: other.repeat.text);

  factory _GroupForm.fromModel(WorkoutBlockGroup group) => _GroupForm(
        stimuli: [for (final b in group.stimuli) _BlockForm.fromModel(b)],
        repeat: '${group.repeatCount}',
      );

  int get repeatCount => (int.tryParse(repeat.text) ?? 1).clamp(1, 99);

  int get durationMin =>
      repeatCount * stimuli.fold(0, (sum, b) => sum + b.durationMin);

  void dispose() {
    for (final b in stimuli) {
      b.dispose();
    }
    repeat.dispose();
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

  final _importService = TrainingPeaksImportService();
  bool _importing = false;

  /// Seeded as the worked example: one block holding two stimuli - a
  /// threshold stimulus and its own recovery stimulus - rather than two
  /// separate blocks.
  final List<_GroupForm> _groups = [
    _GroupForm(stimuli: [
      _BlockForm(),
      _BlockForm(
        role: WorkoutBlockRole.recovery,
        zoneIndex: 1,
        duration: '2',
        minTarget: '90',
        maxTarget: '110',
      ),
    ]),
  ];

  ZoneScale get _scale => _metric == ZoneMetric.power
      ? _rider.powerZones.scale
      : _rider.heartRateZones!.scale;

  ZoneTable get _table =>
      ZoneTables.of(_metric, _scale, anchor: _rider.heartRateZones!.anchor);

  int get _totalMinutes => _groups.fold(0, (sum, g) => sum + g.durationMin);

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
    for (final g in _groups) {
      g.dispose();
    }
    super.dispose();
  }

  void _addBlock() => setState(() => _groups.add(_GroupForm(stimuli: [
        _BlockForm(
          zoneIndex: 2,
          duration: '10',
          minTarget: '140',
          maxTarget: '160',
        ),
      ])));

  void _addStimulus(int i) => setState(() {
        final last = _groups[i].stimuli.last;
        final recovering = last.role == WorkoutBlockRole.recovery;
        _groups[i].stimuli.add(_BlockForm(
              role: recovering
                  ? WorkoutBlockRole.work
                  : WorkoutBlockRole.recovery,
              zoneIndex: recovering ? 4 : 1,
              duration: recovering ? '8' : '2',
              minTarget: recovering ? '170' : '90',
              maxTarget: recovering ? '190' : '110',
            ));
      });

  void _removeStimulus(int i, int j) =>
      setState(() => _groups[i].stimuli.removeAt(j).dispose());

  void _duplicate(int i) =>
      setState(() => _groups.insert(i + 1, _GroupForm.from(_groups[i])));

  void _remove(int i) => setState(() => _groups.removeAt(i).dispose());

  Future<void> _importFromTrainingPeaks() async {
    final t = tr(context);
    if (!IntegrationsStore.instance.isConnected(ResultSource.trainingPeaks)) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => _TrainingPeaksFallbackSheet(t: t),
      );
      if (!mounted || action != 'connect') return;
      await Navigator.of(context).pushNamed('/integrations');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final store = IntegrationsStore.instance;

    setState(() => _importing = true);
    try {
      final imported = await _importService.importPreferredWorkout(
        credentials: store.credentialsFor(ResultSource.trainingPeaks),
        tokens: await store.validTokensFor(ResultSource.trainingPeaks),
        rider: _rider,
      );
      if (!mounted) return;

      // Nothing structured planned is a real answer, not a failure: the
      // blocks already on screen stay exactly as the rider left them.
      if (imported.isEmpty) {
        messenger.showSnackBar(
            SnackBar(content: Text(t.importWorkoutNothingPlanned)));
        return;
      }

      setState(() {
        for (final g in _groups) {
          g.dispose();
        }
        _metric = ZoneMetric.power;
        _groups
          ..clear()
          ..addAll(imported.map(_GroupForm.fromModel));
      });
      messenger
          .showSnackBar(SnackBar(content: Text(t.importWorkoutSuccessSnack)));
    } on PlatformApiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (e.failure) {
          PlatformApiFailure.unauthorized => t.importWorkoutReconnect,
          _ => t.importWorkoutFailed,
        }),
      ));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
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
                    for (final g in _groups) {
                      for (final b in g.stimuli) {
                        if (b.zoneIndex > max) b.zoneIndex = max;
                      }
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
                for (var i = 0; i < _groups.length; i++) ...[
                  _GroupCard(
                    index: i,
                    group: _groups[i],
                    unit: unit,
                    table: table,
                    rangeLabel: _rangeLabel,
                    onChanged: () => setState(() {}),
                    onAddStimulus: () => _addStimulus(i),
                    onRemoveStimulus: (j) => _removeStimulus(i, j),
                    onDuplicate: () => _duplicate(i),
                    onRemove: _groups.length > 1 ? () => _remove(i) : null,
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
                // Room for the FAB not to cover the footnote.
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _importFromTrainingPeaks,
        icon: _importing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            : const Icon(Icons.cloud_download_outlined, size: 20),
        label: Text(t.importWorkoutFabLabel),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final int index;
  final _GroupForm group;
  final String unit;
  final ZoneTable table;
  final String Function(int zoneIndex) rangeLabel;
  final VoidCallback onChanged;
  final VoidCallback onAddStimulus;
  final ValueChanged<int> onRemoveStimulus;
  final VoidCallback onDuplicate;
  final VoidCallback? onRemove;

  const _GroupCard({
    required this.index,
    required this.group,
    required this.unit,
    required this.table,
    required this.rangeLabel,
    required this.onChanged,
    required this.onAddStimulus,
    required this.onRemoveStimulus,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    // A multi-stimulus block reads as a distinct group, so the pairing (and
    // that it repeats as one unit) is visible at a glance.
    final isGroup = group.stimuli.length > 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGroup ? AppColors.paper : null,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.builderBlock(index + 1),
                  style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TinyAction(
                      label: t.builderAddStimulus, onTap: onAddStimulus),
                  _TinyAction(label: t.builderDuplicate, onTap: onDuplicate),
                  if (onRemove != null)
                    _TinyAction(label: t.builderRemove, onTap: onRemove!),
                ],
              ),
            ],
          ),
          for (var j = 0; j < group.stimuli.length; j++) ...[
            const SizedBox(height: 10),
            _StimulusRow(
              label: isGroup ? t.builderStimulus(j + 1) : null,
              form: group.stimuli[j],
              unit: unit,
              table: table,
              rangeLabel: rangeLabel,
              onChanged: onChanged,
              onRemove:
                  group.stimuli.length > 1 ? () => onRemoveStimulus(j) : null,
            ),
          ],
          if (isGroup) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: 96,
              child: TrailwattField(
                label: t.builderRepeat,
                controller: group.repeat,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StimulusRow extends StatelessWidget {
  final String? label;
  final _BlockForm form;
  final String unit;
  final ZoneTable table;
  final String Function(int zoneIndex) rangeLabel;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _StimulusRow({
    required this.label,
    required this.form,
    required this.unit,
    required this.table,
    required this.rangeLabel,
    required this.onChanged,
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

    return Container(
      margin: EdgeInsets.only(left: label == null ? 0 : 4),
      padding: label == null ? EdgeInsets.zero : const EdgeInsets.only(left: 8),
      decoration: label == null
          ? null
          : const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.line, width: 2)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                        color: zone.color, shape: BoxShape.circle),
                  ),
                  Text(label!,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 8.5, fontWeight: FontWeight.w700)),
                  if (onRemove != null) ...[
                    const Spacer(),
                    _TinyAction(label: t.builderRemove, onTap: onRemove!),
                  ],
                ],
              ),
            ),
          Row(
            children: [
              if (label == null) ...[
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 7),
                  decoration:
                      BoxDecoration(color: zone.color, shape: BoxShape.circle),
                ),
              ],
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
                        if (r != null) {
                          form.role = r;
                          onChanged();
                        }
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
                        if (z != null) {
                          form.zoneIndex = z;
                          onChanged();
                        }
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
                  onChanged: (_) => onChanged(),
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

/// Shown when the rider asks to import their preferred workout but has no
/// TrainingPeaks connection: connect now, or keep building the block list
/// by hand - the manual path stays fully available (spec 002, Requirement
/// 8).
class _TrainingPeaksFallbackSheet extends StatelessWidget {
  final AppLocalizations t;
  const _TrainingPeaksFallbackSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.importWorkoutNoConnectionTitle,
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t.importWorkoutNoConnectionBody,
                style: AppTextStyles.label.copyWith(height: 1.5)),
            const SizedBox(height: 18),
            TrailwattButton(
              label: t.importWorkoutConnectCta,
              onPressed: () => Navigator.of(context).pop('connect'),
            ),
            const SizedBox(height: 8),
            TrailwattButton(
              label: t.importWorkoutManualCta,
              style: TrailwattButtonStyle.secondary,
              onPressed: () => Navigator.of(context).pop('manual'),
            ),
          ],
        ),
      ),
    );
  }
}
