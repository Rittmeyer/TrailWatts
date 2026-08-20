import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

class _Stimulus {
  final String label;
  final int targetWatts;
  const _Stimulus(this.label, this.targetWatts);
}

/// Shared scaffold for screens 06a (interval workout) and 06b (continuous
/// workout) - fully manual entry, used when there is no platform
/// connection at all. Each prescribed stimulus gets its own field: a
/// single averaged value would hide the difference between them.
class _ManualResultScreen extends StatelessWidget {
  final String subtitle;
  final List<_Stimulus> stimuli;

  const _ManualResultScreen({required this.subtitle, required this.stimuli});

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
                Text('Workout result',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 18),
                for (final s in stimuli) ...[
                  Text(s.label.toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  Text('target ${s.targetWatts}w',
                      style: AppTextStyles.label.copyWith(fontSize: 9.5)),
                  const SizedBox(height: 6),
                  const TrailwattField(
                    label: 'avg watts',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                TrailwattButton(
                  label: 'Save workout',
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/history'),
                ),
                const SizedBox(height: 14),
                Text(
                    'Shown in English - adapts to the rider\'s profile language.',
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Port of screen 06a - "Manual, intervals".
class ManualResultIntervalsScreen extends StatelessWidget {
  const ManualResultIntervalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ManualResultScreen(
      subtitle: 'Manual entry · interval workout',
      stimuli: [
        _Stimulus('Stimulus 1 · 10 min', 160),
        _Stimulus('Stimulus 2 · 4×3 min', 200),
        _Stimulus('Stimulus 3 · 4×1 min', 260),
      ],
    );
  }
}

/// Port of screen 06b - "Manual, continuous".
class ManualResultContinuousScreen extends StatelessWidget {
  const ManualResultContinuousScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ManualResultScreen(
      subtitle: 'Manual entry · continuous workout',
      stimuli: [
        _Stimulus('Endurance ride · 60 min', 150),
      ],
    );
  }
}
