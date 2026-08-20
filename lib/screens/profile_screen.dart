import 'package:flutter/material.dart';
import '../models/rider_profile.dart';
import '../l10n/domain_labels.dart';
import '../models/zone.dart';
import '../services/rider_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
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
  /// The form opens on whatever is saved, so reopening it shows the rider
  /// their own settings rather than the defaults again.
  final _store = RiderProfileStore.instance;

  late final _weightController =
      TextEditingController(text: _saved.weightKg.toStringAsFixed(0));
  late final _ftpController = TextEditingController(text: '${_saved.ftpWatts}');
  late final _hrAnchorController =
      TextEditingController(text: '${_saved.heartRateZones?.anchorBpm ?? ''}');

  RiderProfile get _saved => _store.profile;

  late ZoneScale _powerScale = _saved.powerZones.scale;
  late ZoneScale _hrScale = _saved.heartRateZones?.scale ?? ZoneScale.five;
  late HeartRateAnchor _hrAnchor =
      _saved.heartRateZones?.anchor ?? HeartRateAnchor.lactateThreshold;

  /// Null while the generic percentage table is in use.
  late List<int>? _powerBounds = _saved.powerZones.customLowerBoundsWatts;
  late List<int>? _hrBounds = _saved.heartRateZones?.customLowerBoundsBpm;

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

  /// Writes the profile everything else reads, then returns to the main
  /// screen. Before this existed the zone scale never left this widget, so
  /// picking Z1-Z5 changed nothing on the calendar or the route map.
  void _save() {
    _store.save(RiderProfile(
      weightKg: double.tryParse(_weightController.text.replaceAll(',', '.')) ??
          _saved.weightKg,
      // FTP anchors the whole power table, so an unreadable field keeps the
      // saved value rather than collapsing the table to zero.
      ftpWatts: _ftp > 0 ? _ftp : _saved.ftpWatts,
      powerZones: _powerSettings,
      heartRateZones: _hrSettings,
    ));
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      body: ContentWidth(
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.profileTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(t.profileSubtitle, style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 20),
                TrailwattField(
                  label: t.profileWeight,
                  hint: '74',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: t.profileFtp,
                  hint: '210',
                  controller: _ftpController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),

                // --- Power zones -----------------------------------------
                _SectionLabel(t.profilePowerZones),
                Text(t.profilePowerZonesAnchor, style: AppTextStyles.label),
                const SizedBox(height: 6),
                SegmentedControl(
                  options: [t.scaleFive, t.scaleSeven],
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
                _SectionLabel(t.profileHeartRateZones),
                Text(
                  t.profileHeartRateZonesNote,
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.4),
                ),
                const SizedBox(height: 8),
                SegmentedControl(
                  options: [t.scaleFive, t.scaleSeven],
                  selectedIndex: _hrScale == ZoneScale.five ? 0 : 1,
                  onChanged: (i) => setState(() {
                    _hrScale = i == 0 ? ZoneScale.five : ZoneScale.seven;
                    _hrBounds = null;
                    _hrBoundsValid = true;
                  }),
                ),
                const SizedBox(height: 10),
                Text(t.profileAnchorOn, style: AppTextStyles.label),
                const SizedBox(height: 4),
                SegmentedControl(
                  options: [t.profileAnchorThreshold, t.profileAnchorMax],
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
                      ? t.profileThresholdHr
                      : t.profileMaxHr,
                  hint: t.profileOptional,
                  controller: _hrAnchorController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                if (_hrAnchorBpm == null)
                  Text(
                    t.profileNoHrAnchor,
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
                  label: t.profileSave,
                  onPressed: _canSave ? _save : null,
                ),
                const SizedBox(height: 14),
                Text(
                  t.profileFootnote,
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      )),
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
