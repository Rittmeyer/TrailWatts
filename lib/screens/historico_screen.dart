import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../models/result_source.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/stat_box.dart';

/// Port of screen 07. previsto vs. realizado per entry - the raw material
/// for the calibration loop (Constitution Article VI).
class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      HistoryEntry(
          date: DateTime(2026, 7, 14),
          routeName: 'Subida da Serra',
          targetWatts: 180,
          realWatts: 178,
          source: ResultSource.strava),
      HistoryEntry(
          date: DateTime(2026, 7, 12),
          routeName: 'Circuito do parque',
          targetWatts: 150,
          realWatts: 142,
          source: ResultSource.garmin),
      HistoryEntry(
          date: DateTime(2026, 7, 10),
          routeName: 'Treino indoor',
          targetWatts: 240,
          realWatts: 241,
          source: ResultSource.manual),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seu progresso',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: StatBox(label: 'FTP ATUAL', value: '212w')),
                  SizedBox(width: 8),
                  Expanded(
                      child: StatBox(
                          label: 'PRECISAO',
                          value: '94%',
                          valueColor: AppColors.greenText)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Treinos recentes', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final good = e.deltaWatts.abs() <= e.targetWatts * 0.05;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: good ? AppColors.accent : AppColors.line),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.routeName,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('alvo ${e.targetWatts}w',
                                  style: AppTextStyles.label.copyWith(fontSize: 11)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: good ? AppColors.greenBg : AppColors.warnBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('${e.realWatts}w',
                                style: AppTextStyles.numeric.copyWith(
                                  fontSize: 12,
                                  color: good ? AppColors.greenText : AppColors.warnText,
                                )),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TrailwattBottomNav(currentIndex: 2),
    );
  }
}
