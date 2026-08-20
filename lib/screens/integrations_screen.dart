import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/platform_integration.dart';
import '../models/result_source.dart';
import '../services/integrations_store.dart';
import '../services/platform/platform_oauth_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_button.dart';
import '../widgets/trailwatt_field.dart';

/// Connect or disconnect Strava, Garmin, Wahoo and TrainingPeaks
/// independently - spec 002, Requirement 9: disconnecting one platform MUST
/// NOT affect the others. Reachable from the "Mais" tab and, without a
/// TrainingPeaks connection, from the workout builder's import fallback.
///
/// Each row shows the connection's real state, including "not configured in
/// this build" - a build with no client id for a platform says so instead of
/// offering a Connect button that could only ever fail.
class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final store = IntegrationsStore.instance;

    return Scaffold(
      body: ContentWidth(
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: store,
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
                  for (final platform in store.platforms) ...[
                    _PlatformTile(platform: platform, store: store),
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
      )),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final ResultSource platform;
  final IntegrationsStore store;

  const _PlatformTile({required this.platform, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final state = store.stateOf(platform);
    final connection = store.connectionFor(platform);
    final connected = state == PlatformConnectionState.connected;
    final configured = state != PlatformConnectionState.notConfigured;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(platform.label(t),
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _StateBadge(state: state),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: TrailwattButton(
                  label: switch (state) {
                    PlatformConnectionState.connected =>
                      t.integrationsDisconnect,
                    PlatformConnectionState.expired => t.integrationsReconnect,
                    _ => t.integrationsConnect,
                  },
                  style: connected
                      ? TrailwattButtonStyle.secondary
                      : TrailwattButtonStyle.primary,
                  onPressed: !configured
                      ? null
                      : connected
                          ? () => store.disconnect(platform)
                          : () => _connect(context),
                ),
              ),
            ],
          ),
          if (!configured) ...[
            const SizedBox(height: 8),
            Text(t.integrationsNotConfiguredNote,
                style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.4)),
          ],
          if (connection != null && connection.scopes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t.integrationsScopes(connection.scopes.join(', ')),
                style: AppTextStyles.label.copyWith(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final t = tr(context);
    final messenger = ScaffoldMessenger.of(context);

    final PendingAuthorization pending;
    try {
      pending = store.beginConnect(platform);
    } on PlatformAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authError(t, e.failure))));
      return;
    }

    if (!context.mounted) return;
    final redirect = await showDialog<String>(
      context: context,
      builder: (_) => _AuthorizeDialog(
        platformLabel: platform.label(t),
        authorizationUrl: pending.authorizationUrl,
      ),
    );
    if (redirect == null || redirect.trim().isEmpty) return;

    final uri = Uri.tryParse(redirect.trim());
    if (uri == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(authError(t, PlatformAuthFailure.invalidResponse))));
      return;
    }

    try {
      await store.completeConnect(platform, uri);
      messenger.showSnackBar(SnackBar(
          content: Text(t.integrationsConnectedSnack(platform.label(t)))));
    } on PlatformAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authError(t, e.failure))));
    }
  }

  /// One place that turns an authorization failure code into rider-facing
  /// words, so every entry point says the same thing about the same failure.
  static String authError(AppLocalizations t, PlatformAuthFailure failure) =>
      switch (failure) {
        PlatformAuthFailure.notConfigured => t.integrationsErrorNotConfigured,
        PlatformAuthFailure.denied => t.integrationsErrorDenied,
        PlatformAuthFailure.stateMismatch => t.integrationsErrorStateMismatch,
        PlatformAuthFailure.noPendingAuthorization ||
        PlatformAuthFailure.missingCode =>
          t.integrationsErrorNoCode,
        PlatformAuthFailure.network => t.integrationsErrorNetwork,
        PlatformAuthFailure.invalidResponse =>
          t.integrationsErrorInvalidResponse,
      };
}

class _StateBadge extends StatelessWidget {
  final PlatformConnectionState state;
  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final (label, background, foreground) = switch (state) {
      PlatformConnectionState.connected => (
          t.integrationsConnected,
          AppColors.greenBg,
          AppColors.greenText
        ),
      PlatformConnectionState.expired => (
          t.integrationsExpired,
          AppColors.warnBg,
          AppColors.warnText
        ),
      PlatformConnectionState.notConfigured => (
          t.integrationsNotConfigured,
          AppColors.warnBg,
          AppColors.warnText
        ),
      PlatformConnectionState.disconnected => (
          t.integrationsNotConnected,
          AppColors.paper,
          AppColors.inkSoft
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(
              fontSize: 8.5, fontWeight: FontWeight.w800, color: foreground)),
    );
  }
}

/// The two halves of the authorization the app cannot do on its own: open the
/// platform's consent page, then hand back where it redirected to.
///
/// A deep-link handler calling `IntegrationsStore.completeConnect` directly is
/// what a shipping build wants; this dialog is the same flow with the
/// redirect delivered by hand, so the connection genuinely works before that
/// platform wiring exists rather than being stubbed out until then.
class _AuthorizeDialog extends StatefulWidget {
  final String platformLabel;
  final Uri authorizationUrl;

  const _AuthorizeDialog({
    required this.platformLabel,
    required this.authorizationUrl,
  });

  @override
  State<_AuthorizeDialog> createState() => _AuthorizeDialogState();
}

class _AuthorizeDialogState extends State<_AuthorizeDialog> {
  final _redirect = TextEditingController();

  @override
  void dispose() {
    _redirect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return AlertDialog(
      title: Text(t.integrationsConnectTitle(widget.platformLabel),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.integrationsConnectStep1,
                style: AppTextStyles.label.copyWith(height: 1.4)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.authorizationUrl.toString(),
                style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.4),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (buttonContext) => TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                        text: widget.authorizationUrl.toString()));
                    if (buttonContext.mounted) {
                      ScaffoldMessenger.of(buttonContext).showSnackBar(
                          SnackBar(content: Text(t.integrationsUrlCopied)));
                    }
                  },
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(t.integrationsCopyUrl,
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(t.integrationsConnectStep2,
                style: AppTextStyles.label.copyWith(height: 1.4)),
            const SizedBox(height: 6),
            TrailwattField(
              label: t.integrationsRedirectLabel,
              controller: _redirect,
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.editRouteCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_redirect.text),
          child: Text(t.integrationsConnectConfirm),
        ),
      ],
    );
  }
}
