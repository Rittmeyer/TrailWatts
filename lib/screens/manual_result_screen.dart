import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// One prescribed stimulus, named at render time so the heading follows the
/// rider's language like everything else.
class _Stimulus {
  final String Function(AppLocalizations) label;
  final int targetWatts;
  const _Stimulus(this.label, this.targetWatts);
}

/// Shared scaffold for screens 06a (interval workout) and 06b (continuous
/// workout) - fully manual entry, used when there is no platform
/// connection at all. Each prescribed stimulus gets its own field: a
/// single averaged value would hide the difference between them.
class _ManualResultScreen extends StatelessWidget {
  final String Function(AppLocalizations) subtitle;
  final List<_Stimulus> stimuli;

  const _ManualResultScreen({required this.subtitle, required this.stimuli});

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
                Text(t.importTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(subtitle(t), style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 18),
                for (final s in stimuli) ...[
                  Text(s.label(t).toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  Text(t.manualTarget(s.targetWatts),
                      style: AppTextStyles.label.copyWith(fontSize: 9.5)),
                  const SizedBox(height: 6),
                  TrailwattField(
                    label: t.manualAvgWatts,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                TrailwattButton(
                  label: t.manualSave,
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/history'),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

/// Port of screen 06a - manual entry for an interval workout.
class ManualResultIntervalsScreen extends StatelessWidget {
  const ManualResultIntervalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ManualResultScreen(
      subtitle: (t) => t.manualIntervalsSubtitle,
      stimuli: [
        _Stimulus((t) => t.manualStimulus(1, '10 min'), 160),
        _Stimulus((t) => t.manualStimulus(2, '4×3 min'), 200),
        _Stimulus((t) => t.manualStimulus(3, '4×1 min'), 260),
      ],
    );
  }
}

/// Port of screen 06b - manual entry for a continuous workout.
class ManualResultContinuousScreen extends StatelessWidget {
  const ManualResultContinuousScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ManualResultScreen(
      subtitle: (t) => t.manualContinuousSubtitle,
      stimuli: [
        _Stimulus((t) => t.manualEnduranceRide, 150),
      ],
    );
  }
}
