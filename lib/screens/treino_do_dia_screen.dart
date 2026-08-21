import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../services/route_suggestion_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_box.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 03. Shows today's target already translated into
/// terrain, and a teaser of the best-matched route (full detail lives on
/// screen 04, opened via "Ver no mapa").
class TreinoDoDiaScreen extends StatelessWidget {
  const TreinoDoDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final suggestion = RouteSuggestionStore.instance.selected?.suggestion;
    return TrailwattShell(
      navIndex: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.todayTitle,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text(t.todaySubtitle, style: AppTextStyles.screenSubtitle),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: StatBox(label: t.todayTarget, value: '180w')),
                const SizedBox(width: 8),
                Expanded(child: StatBox(label: t.todayGradient, value: '4-6%')),
                const SizedBox(width: 8),
                Expanded(child: StatBox(label: t.todaySegment, value: '800m')),
              ],
            ),
            const SizedBox(height: 20),
            // Nothing here until a search has run. The card used to show a
            // route that did not exist, which read as a working engine.
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pushNamed(
                  suggestion == null ? '/workout-builder/map' : '/route-map'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: suggestion == null
                          ? AppColors.line
                          : AppColors.accent,
                      width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: suggestion == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(t.routeSearchNotRun,
                                style: AppTextStyles.label),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.primary),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    suggestion.name.isEmpty
                                        ? t.routeSubtitle
                                        : suggestion.name,
                                    style: AppTextStyles.body
                                        .copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                    '${suggestion.gradientAvgPct.toStringAsFixed(1)}% · '
                                    '${suggestion.distanceM}m',
                                    style: AppTextStyles.label),
                              ],
                            ),
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
            const SizedBox(height: 16),
            // The workout builder's way in. It used to be reached by saving
            // the profile, which stopped being true once saving returns
            // here - and the builder is the screen the whole app is for.
            TrailwattButton(
              label: t.builderTitle,
              style: TrailwattButtonStyle.secondary,
              onPressed: () =>
                  Navigator.of(context).pushNamed('/workout-builder'),
            ),
          ],
        ),
      ),
    );
  }
}
