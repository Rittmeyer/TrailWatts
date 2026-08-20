import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';

/// Port of the "Mais" destination on the bottom tab bar (08a/08b/08c). A
/// table of links to everything that isn't a tab of its own - profile and,
/// per the workout builder's TrainingPeaks import, the platform
/// integrations (Garmin, Strava, TrainingPeaks).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return TrailwattShell(
      navIndex: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.moreTitle,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text(t.moreSubtitle, style: AppTextStyles.screenSubtitle),
            const SizedBox(height: 20),
            _MoreRow(
              icon: Icons.person_outline,
              title: t.moreProfile,
              subtitle: t.moreProfileSubtitle,
              onTap: () => Navigator.of(context).pushNamed('/profile'),
            ),
            const SizedBox(height: 10),
            _MoreRow(
              icon: Icons.sync_outlined,
              title: t.moreIntegrations,
              subtitle: t.moreIntegrationsSubtitle,
              onTap: () => Navigator.of(context).pushNamed('/integrations'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.label),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
