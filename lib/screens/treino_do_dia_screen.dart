import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/route_suggestion.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/stat_box.dart';

/// Port of screen 03. Shows today's target already translated into
/// terrain, and a teaser of the best-matched route (full detail lives on
/// screen 04, opened via "Ver no mapa").
class TreinoDoDiaScreen extends StatelessWidget {
  const TreinoDoDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const suggestion = RouteSuggestion(
      id: 'demo-route-01',
      name: 'Subida da Serra',
      routeType: RouteType.loop,
      distanceM: 850,
      elevationGainM: 44,
      estimatedMovingTimeMin: 3,
      score: RouteScoreBreakdown(
        intensityMatchPct: 98,
        durationMatchPct: 96,
        sequenceMatchPct: 100,
        continuityScorePct: 95,
        safetyScorePct: 95,
        trafficScorePct: 90,
        surfaceScorePct: 100,
        practicalityScorePct: 96,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Treino de hoje',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text('4x8min a 180w', style: AppTextStyles.screenSubtitle),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: StatBox(label: 'ALVO', value: '180w')),
                  SizedBox(width: 8),
                  Expanded(child: StatBox(label: 'GRADIENTE', value: '4-6%')),
                  SizedBox(width: 8),
                  Expanded(child: StatBox(label: 'TRECHO', value: '800m')),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pushNamed('/route-map'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion.name,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                              '${suggestion.gradientAvgPct.toStringAsFixed(1)}% · ${suggestion.distanceM}m',
                              style: AppTextStyles.label),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${suggestion.matchPct}%',
                            style: AppTextStyles.numeric.copyWith(
                                fontSize: 12, color: AppColors.greenText)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TrailwattBottomNav(currentIndex: 0),
    );
  }
}
