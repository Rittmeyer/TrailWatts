import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/stat_box.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 06 - "Resultado do treino". The API-matched activity is
/// the primary path; manual entry is the documented fallback and stays
/// visually secondary (Constitution Article III). The rider still has to
/// confirm the match - nothing here auto-confirms silently.
class ImportResultScreen extends StatelessWidget {
  const ImportResultScreen({super.key});

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
                Text(t.importSubtitle, style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t.importConnectedTo,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 8.5,
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.importActivityFound,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(t.importActivityWhen, style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: StatBox(
                                  label: t.importAvgPower, value: '182w')),
                          const SizedBox(width: 8),
                          Expanded(
                              child:
                                  StatBox(label: t.importAvgHr, value: '152')),
                          const SizedBox(width: 8),
                          Expanded(
                              child: StatBox(
                                  label: t.importDuration, value: '41m')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TrailwattButton(
                  label: t.importConfirm,
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/history'),
                ),
                const SizedBox(height: 26),
                Text(t.importNoApi,
                    style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TrailwattField(
                  label: t.importManualPower,
                  hint: t.importManualHint,
                  keyboardType: TextInputType.number,
                  helperText: t.importManualHelp,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/import-result/manual-intervals'),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(t.importManualLink,
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t.importFootnote,
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
