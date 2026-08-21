import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/workout_block.dart';
import '../models/zone.dart';
import '../services/integrations_store.dart';
import '../services/platform/platform_api_client.dart';
import '../services/rider_profile_store.dart';
import '../services/workout_plan_store.dart';
import '../services/training_peaks_import.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/page_header.dart';
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

  /// The block's name rides on the model, so reopening a saved day brings
  /// it back; the group form lifts it out of the first stimulus.
  String? loadedName;

  factory _BlockForm.fromModel(WorkoutBlock block) => _BlockForm(
        role: block.role,
        zoneIndex: block.zone.index,
        duration: '${block.durationMin}',
        minTarget: '${block.target.minValue}',
        maxTarget: '${block.target.maxValue}',
      )..loadedName = block.name;

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

  /// Empty means unnamed, and the card shows its position instead. Kept as
  /// a controller so the field is edited in place like every other one.
  final TextEditingController name;

  _GroupForm({
    List<_BlockForm>? stimuli,
    String repeat = '1',
    String name = '',
  })  : stimuli = stimuli ?? [_BlockForm()],
        repeat = TextEditingController(text: repeat),
        name = TextEditingController(text: name);

  _GroupForm.from(_GroupForm other)
      : stimuli = [for (final b in other.stimuli) _BlockForm.from(b)],
        repeat = TextEditingController(text: other.repeat.text),
        name = TextEditingController(text: other.name.text);

  factory _GroupForm.fromModel(WorkoutBlockGroup group) => _GroupForm(
        stimuli: [for (final b in group.stimuli) _BlockForm.fromModel(b)],
        repeat: '${group.repeatCount}',
        name: group.stimuli.first.name ?? '',
      );

  int get repeatCount => (int.tryParse(repeat.text) ?? 1).clamp(1, 99);

  int get durationMin =>
      repeatCount * stimuli.fold(0, (sum, b) => sum + b.durationMin);

  void dispose() {
    for (final b in stimuli) {
      b.dispose();
    }
    repeat.dispose();
    name.dispose();
  }
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  /// Which table the whole workout is prescribed against. Power and heart
  /// rate are separate tables with their own zone counts, so switching this
  /// switches the zone list too.
  ZoneMetric _metric = ZoneMetric.power;

  /// The rider's saved profile. Read, never assumed: the zone table this
  /// screen offers has to be the one the rider configured, or a rider on
  /// Z1-Z5 would be prescribing against zones they never chose.
  RiderProfile get _rider => RiderProfileStore.instance.profile;

  final _importService = TrainingPeaksImportService();
  bool _importing = false;

  /// The calendar day this workout is being written for, when the rider got
  /// here by selecting one. Null means they came to build a workout to ride
  /// now, and the screen continues to the route search as before.
  DateTime? _planDay;
  bool _loadedPlanDay = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedPlanDay) return;
    _loadedPlanDay = true;

    final day = ModalRoute.of(context)?.settings.arguments;
    if (day is! DateTime) return;
    _planDay = day;

    // Editing a day opens on what is already planned there. The plan stores
    // a flat block sequence, so each block comes back as its own block on
    // screen - grouping is how the rider authored it, not something the
    // plan preserves.
    final planned = WorkoutPlanStore.instance.entryFor(day)?.planned;
    if (planned == null || planned.isEmpty) return;

    for (final g in _groups) {
      g.dispose();
    }
    _groups
      ..clear()
      ..addAll(planned.map((b) => _GroupForm(
            stimuli: [_BlockForm.fromModel(b)],
            name: b.name ?? '',
          )));
  }

  /// The blocks as currently on screen, expanded into timeline order.
  ///
  /// The fields are free text, so every value is brought into the range the
  /// model guarantees rather than being trusted: a duration of at least a
  /// minute, a non-negative target, and a maximum no lower than its minimum.
  /// The plan as the rider authored it - blocks with their repeats intact.
  /// The route search wants this rather than the flattened list, because a
  /// block repeated four times is four intervals to place, and it has to
  /// know that before it starts looking for ground.
  List<WorkoutBlockGroup> _toGroups() {
    WorkoutBlock blockFrom(_BlockForm form, String groupName) {
      final min = (int.tryParse(form.minTarget.text) ?? 0).clamp(0, 9999);
      final max = (int.tryParse(form.maxTarget.text) ?? min).clamp(0, 9999);
      return WorkoutBlock(
        // Every stimulus the group expands to carries the block's name, so
        // the flattened plan can be read back into named blocks.
        name: groupName.trim().isEmpty ? null : groupName.trim(),
        role: form.role,
        zone: TrainingZone(
          metric: _metric,
          scale: _scale,
          index: form.zoneIndex.clamp(1, _scale.count),
        ),
        durationMin: form.durationMin < 1 ? 1 : form.durationMin,
        target: WorkoutTarget(
          metric: _metric,
          minValue: min,
          maxValue: max < min ? min : max,
        ),
      );
    }

    return [
      for (final g in _groups)
        WorkoutBlockGroup(
          repeatCount: g.repeatCount,
          stimuli: [for (final b in g.stimuli) blockFrom(b, g.name.text)],
        ),
    ];
  }

  /// The physically real sequence, for anything that stores a plan.
  List<WorkoutBlock> _toBlocks() => flattenBlockGroups(_toGroups());

  /// Writes the workout onto today without going near a route.
  ///
  /// Today is the day a workout built from the home screen belongs to; the
  /// calendar entry point already carries its own day.
  void _saveToToday() {
    final t = tr(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      WorkoutPlanStore.instance.savePlanned(today, _toBlocks());
    } on StateError {
      // A day with a recorded result is not editable - the plan it was
      // measured against would no longer be the plan.
      messenger.showSnackBar(SnackBar(content: Text(t.builderSaveBlocked)));
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(t.builderSavedToday)));
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  /// Writes the workout onto the day the rider selected and goes back to the
  /// calendar they came from.
  void _saveToPlan() {
    final day = _planDay;
    if (day == null) return;
    WorkoutPlanStore.instance.savePlanned(day, _toBlocks());
    // The calendar announces the save: a snackbar raised here would go with
    // this screen as it pops.
    Navigator.of(context).pop(true);
  }

  ZoneScale get _scale => _metric == ZoneMetric.power
      ? _rider.powerZones.scale
      : _rider.heartRateZones?.scale ?? ZoneScale.five;

  ZoneTable get _table => ZoneTables.of(_metric, _scale,
      anchor:
          _rider.heartRateZones?.anchor ?? HeartRateAnchor.lactateThreshold);

  int get _totalMinutes => _groups.fold(0, (sum, g) => sum + g.durationMin);

  /// Absolute range for a zone on the active table, e.g. "191-222 w".
  String _rangeLabel(int index) {
    if (_metric == ZoneMetric.power) {
      final min = _rider.powerZones.lowerBoundWatts(index, _rider.ftpWatts);
      final max = _rider.powerZones.upperBoundWatts(index, _rider.ftpWatts);
      return max == null ? '≥ $min w' : '$min-$max w';
    }
    final hr = _rider.heartRateZones;
    if (hr == null) return '';
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

  _GroupForm _newGroup() => _GroupForm(stimuli: [
        _BlockForm(
          zoneIndex: 2,
          duration: '10',
          minTarget: '140',
          maxTarget: '160',
        ),
      ]);

  void _addBlock() => setState(() => _groups.add(_newGroup()));

  /// Inserts a block at [index], which is how a block gets added before the
  /// first one or between two existing ones - appending at the end was the
  /// only way to add a block before this.
  void _insertBlockAt(int index) =>
      setState(() => _groups.insert(index, _newGroup()));

  /// Moves the block at [index] one position in [delta]'s direction. The
  /// order of the blocks IS the workout's timeline, so reordering them is
  /// editing the workout, not rearranging a view.
  void _moveBlock(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _groups.length) return;
    setState(() => _groups.insert(target, _groups.removeAt(index)));
  }

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
      body: ContentWidth(
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: t.builderTitle,
                  subtitle: t.builderSubtitle,
                ),
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
                    // Both sized to their text in a row of fixed width, so
                    // a long zone-table label overflowed on a narrow phone.
                    // The label yields; the total never wraps.
                    Flexible(
                      child: Text(
                        t.builderTableLabel(
                            _metric.label(t).toLowerCase(), _scale.count),
                        style: AppTextStyles.label.copyWith(fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(t.builderTotalDuration(_totalMinutes),
                        style: AppTextStyles.numeric.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _groups.length; i++) ...[
                  // One of these before every card, so "add a block here"
                  // covers before the first and between any two - not only
                  // the append at the bottom.
                  _InsertHere(onTap: () => _insertBlockAt(i)),
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
                    onMoveUp: i > 0 ? () => _moveBlock(i, -1) : null,
                    onMoveDown:
                        i < _groups.length - 1 ? () => _moveBlock(i, 1) : null,
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
                // Coming from a calendar day, the workout belongs on that
                // day; coming from today's screen, the rider wants a route
                // to go ride. Same builder, different thing being finished.
                TrailwattButton(
                  label:
                      _planDay == null ? t.builderContinue : t.builderSaveToDay,
                  onPressed: _planDay == null
                      ? () => Navigator.of(context).pushNamed(
                            '/workout-builder/map',
                            // The search needs the workout, not just the
                            // place: which ground serves the session is the
                            // whole question.
                            arguments: _toGroups(),
                          )
                      : _saveToPlan,
                ),
                // Saving used to be reachable only by going on to the map.
                // Writing down a session and finding ground for it are two
                // different intentions, and a rider who has one should not
                // have to perform the other.
                if (_planDay == null) ...[
                  const SizedBox(height: 8),
                  TrailwattButton(
                    label: t.builderSaveOnly,
                    style: TrailwattButtonStyle.secondary,
                    onPressed: _saveToToday,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  t.builderFootnote,
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.5),
                ),
                // Clearance for the floating import button, which is
                // anchored to the window and not to this content. 64 was
                // less than the 72 the button occupies - 56 of height plus
                // 16 of margin - so at the bottom of the scroll it sat on
                // the footnote's last line by those 8 pixels. Mid-scroll it
                // still passes over content, which is what a floating
                // button does.
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      )),
      floatingActionButtonLocation: const ContentAlignedFabLocation(),
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

  /// Null at the ends of the list, which disables the arrow rather than
  /// offering a move that would do nothing.
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

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
    required this.onMoveUp,
    required this.onMoveDown,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // The name replaces the fixed "BLOCK n" eyebrow, falling back
              // to it as the hint. Once blocks can be reordered a positional
              // label is actively wrong: the block the rider thinks of as
              // the main set stops being number two the moment it moves.
              Expanded(
                child: Semantics(
                  label: t.builderBlockNameLabel,
                  textField: true,
                  child: TextField(
                    controller: group.name,
                    onChanged: (_) => onChanged(),
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      // The app-wide field styling is a filled, outlined
                      // box, which here would read as a stray rule across
                      // the card. An underline on focus only: no chrome at
                      // rest, clear feedback while it is being typed in.
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.only(bottom: 2),
                      hintText: t.builderBlock(index + 1),
                      hintStyle: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MoveButton(
                  icon: Icons.arrow_upward,
                  tooltip: t.builderMoveUp,
                  onTap: onMoveUp),
              _MoveButton(
                  icon: Icons.arrow_downward,
                  tooltip: t.builderMoveDown,
                  onTap: onMoveDown),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TinyAction(label: t.builderAddStimulus, onTap: onAddStimulus),
                _TinyAction(label: t.builderDuplicate, onTap: onDuplicate),
                if (onRemove != null)
                  _TinyAction(label: t.builderRemove, onTap: onRemove!),
              ],
            ),
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
    // A five-zone table has no Z6: clamp rather than index past the end, so
    // a block carried over from a wider table cannot crash the dropdown.
    final zoneIndex = form.zoneIndex.clamp(1, table.zones.length);
    final zone = table.byIndex(zoneIndex);

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
                      value: zoneIndex,
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
          Text(rangeLabel(zoneIndex),
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

/// The gap between two blocks, made tappable: this is where "before" and
/// "between" come from.
class _InsertHere extends StatelessWidget {
  final VoidCallback onTap;
  const _InsertHere({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.line, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(t.builderInsertHere,
                  style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            const Expanded(child: Divider(color: AppColors.line, height: 1)),
          ],
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  /// Null disables it - at the top there is no up.
  final VoidCallback? onTap;

  const _MoveButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      // Not compact: compact quietly subtracts from the constraints below,
      // which is how a button asked to be 44 came out 40.
      visualDensity: VisualDensity.standard,
      padding: const EdgeInsets.all(6),
      // 44 is the smallest target a finger hits reliably. The 28 this
      // started at was small enough that the arrows read as broken rather
      // than as missed.
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      color: AppColors.primary,
      // Not AppColors.line: at 1.2:1 against the card the disabled arrow
      // was invisible, and the first block has both arrows disabled, so
      // the control looked absent rather than inactive.
      disabledColor: AppColors.inkDisabled,
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
