import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../models/calibration.dart';
import '../services/calibration_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Says which model an estimate came from.
///
/// Spec 006 asks every suggestion to expose whether the model is generic or
/// calibrated, and spec 009 asks the rider to be able to see generic,
/// calibrated or stale. Both exist for the same reason: an estimate that
/// changes without explanation is an estimate the rider stops trusting.
class ModelStateChip extends StatelessWidget {
  final CalibrationStore store;

  ModelStateChip({super.key, CalibrationStore? store})
      : store = store ?? CalibrationStore.instance;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final profile = store.profile;
        final state = store.state;

        final (label, background, foreground) = switch (state) {
          CalibrationState.calibrated => (
              t.modelCalibrated(profile!.predictionAccuracyPct.round()),
              AppColors.greenBg,
              AppColors.greenText,
            ),
          CalibrationState.stale => (
              t.modelStale,
              AppColors.warnBg,
              AppColors.warnText,
            ),
          CalibrationState.generic => (
              t.modelGeneric,
              AppColors.paper,
              AppColors.inkSoft,
            ),
        };

        return Tooltip(
          message: switch (state) {
            CalibrationState.generic => t.modelGenericWhy,
            CalibrationState.stale => t.modelStaleWhy,
            CalibrationState.calibrated => '',
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        );
      },
    );
  }
}
