import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../models/result_source.dart';
import '../services/integrations_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_button.dart';

/// Connect or disconnect Garmin, Strava and TrainingPeaks independently -
/// spec 002, Requirement 9: disconnecting one platform MUST NOT affect the
/// others. Reachable from the "Mais" tab and, without a TrainingPeaks
/// connection, from the workout builder's import fallback.
class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  static const _platforms = [
    ResultSource.strava,
    ResultSource.garmin,
    ResultSource.trainingPeaks,
  ];

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: IntegrationsStore.instance,
            builder: (context, _) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('‹ ${t.moreTitle}',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(t.integrationsTitle,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(t.integrationsSubtitle,
                      style: AppTextStyles.screenSubtitle),
                  const SizedBox(height: 20),
                  for (final platform in _platforms) ...[
                    _PlatformTile(platform: platform),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    t.integrationsScopeNote,
                    style:
                        AppTextStyles.label.copyWith(fontSize: 9, height: 1.5),
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

class _PlatformTile extends StatelessWidget {
  final ResultSource platform;
  const _PlatformTile({required this.platform});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final store = IntegrationsStore.instance;
    final connected = store.isConnected(platform);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(platform.label(t),
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: connected ? AppColors.greenBg : AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    connected
                        ? t.integrationsConnected
                        : t.integrationsNotConnected,
                    style: AppTextStyles.label.copyWith(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: connected
                            ? AppColors.greenText
                            : AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: TrailwattButton(
              label:
                  connected ? t.integrationsDisconnect : t.integrationsConnect,
              style: connected
                  ? TrailwattButtonStyle.secondary
                  : TrailwattButtonStyle.primary,
              onPressed: () => connected
                  ? store.disconnect(platform)
                  : store.connect(platform),
            ),
          ),
        ],
      ),
    );
  }
}
