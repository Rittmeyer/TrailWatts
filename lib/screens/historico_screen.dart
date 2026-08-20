import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../models/result_source.dart';
import '../models/rider_profile.dart';
import '../models/zone.dart';
import '../l10n/domain_labels.dart';
import '../services/rider_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/stat_box.dart';
import '../widgets/zone_pill.dart';

/// Port of screen 07. previsto vs. realizado per entry - the raw material
/// for the calibration loop (Constitution Article VI).
class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  /// The zone an activity is shown in: the one recorded with it when the
  /// platform reported one, otherwise resolved from the watts the rider
  /// actually held, on the table their profile is set to. Power always
  /// resolves - it is anchored on FTP, which every profile has.
  static TrainingZone _zoneFor(HistoryEntry entry, RiderProfile rider) =>
      entry.zone ?? rider.zoneFor(entry.realizedWatts, ZoneMetric.power)!;

  @override
  Widget build(BuildContext context) {
    final entries = [
      HistoryEntry(
          date: DateTime(2026, 7, 14),
          routeName: 'Subida da Serra',
          targetWatts: 180,
          realizedWatts: 178,
          targetDurationMin: 32,
          realizedDurationMin: 33,
          source: ResultSource.strava),
      HistoryEntry(
          date: DateTime(2026, 7, 12),
          routeName: 'Circuito do parque',
          targetWatts: 150,
          realizedWatts: 142,
          targetDurationMin: 60,
          realizedDurationMin: 58,
          source: ResultSource.garmin),
      HistoryEntry(
          date: DateTime(2026, 7, 10),
          routeName: 'Treino indoor',
          targetWatts: 240,
          realizedWatts: 241,
          targetDurationMin: 20,
          realizedDurationMin: 20,
          source: ResultSource.manual),
    ];

    final t = tr(context);
    return Scaffold(
      body: SafeArea(
        // Rebuilds when the rider saves a profile: each activity's zone is
        // named on the table they chose, so switching to Z1-Z5 relabels the
        // list rather than leaving it on a table they no longer use.
        child: ListenableBuilder(
          listenable: RiderProfileStore.instance,
          builder: (context, _) {
            final rider = RiderProfileStore.instance.profile;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.historyTitle,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: StatBox(
                              label: t.historyCurrentFtp, value: '212w')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: StatBox(
                              label: t.historyAccuracy,
                              value: '94%',
                              valueColor: AppColors.greenText)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(t.historyRecent, style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final good = e.deltaWatts.abs() <= e.targetWatts * 0.05;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    good ? AppColors.accent : AppColors.line),
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  const SizedBox(height: 3),
                                  ZonePill(zone: _zoneFor(e, rider)),
                                  const SizedBox(height: 3),
                                  Text(t.historyTargetWatts(e.targetWatts),
                                      style: AppTextStyles.label
                                          .copyWith(fontSize: 11)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: good
                                      ? AppColors.greenBg
                                      : AppColors.warnBg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('${e.realizedWatts}w',
                                    style: AppTextStyles.numeric.copyWith(
                                      fontSize: 12,
                                      color: good
                                          ? AppColors.greenText
                                          : AppColors.warnText,
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
            );
          },
        ),
      ),
      bottomNavigationBar: const TrailwattBottomNav(currentIndex: 2),
    );
  }
}
