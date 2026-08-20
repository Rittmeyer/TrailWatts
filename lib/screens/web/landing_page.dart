import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/domain_labels.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/trailwatt_button.dart';

/// Port of the marketing landing page from trailwatt_fluxo.html.
/// Flutter Web CAN render this, but for a public marketing site plain
/// HTML (or Next.js) usually serves SEO and first-load time better -
/// keep this mainly as a content/copy reference, or as an in-app "Sobre"
/// screen, rather than the actual public trailwatt.app.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static List<(String, String)> _features(AppLocalizations t) => [
        (t.landingFeature1Title, t.landingFeature1Body),
        (t.landingFeature2Title, t.landingFeature2Body),
        (t.landingFeature3Title, t.landingFeature3Body),
      ];

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Text(t.landingEyebrow,
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary, letterSpacing: 1.4)),
                  const SizedBox(height: 20),
                  Text(t.landingHeadline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heroTitle),
                  const SizedBox(height: 18),
                  Text(
                    t.landingSubhead,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.inkSoft, fontSize: 15.5),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: TrailwattButton(
                          label: t.landingStartFree,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/auth'),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TrailwattButton(
                          label: t.landingHowItWorks,
                          style: TrailwattButtonStyle.secondary,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/home'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 640;
                      final children = _features(t)
                          .map((f) => SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 72) / 3
                                    : double.infinity,
                                child: _FeatureCard(title: f.$1, body: f.$2),
                              ))
                          .toList();
                      return Wrap(
                          spacing: 36, runSpacing: 24, children: children);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String body;
  const _FeatureCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 8, height: 8, color: AppColors.accent),
        const SizedBox(height: 14),
        Text(title, style: AppTextStyles.screenTitle.copyWith(fontSize: 17)),
        const SizedBox(height: 6),
        Text(body,
            style: AppTextStyles.body
                .copyWith(color: AppColors.inkSoft, fontSize: 13)),
      ],
    );
  }
}
