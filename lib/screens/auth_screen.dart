import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';
import '../widgets/consent_checkbox.dart';

/// Port of screen 01a - one screen, two modes. Login keeps the
/// Google/Apple/Microsoft shortcuts; Criar Conta is manual-only
/// (Constitution Article II) and adds password + terms consent.
/// This is the fullest worked example in this delivery - the state
/// toggle here mirrors the trailwattSetAuthTab() JS function in the HTML
/// prototype, just as Flutter State instead of DOM manipulation.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _tab = 0; // 0 = Entrar, 1 = Criar conta
  bool _consent = true;

  bool get _isLogin => _tab == 0;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.authWelcome,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  _isLogin ? t.authLoginSubtitle : t.authSignupSubtitle,
                  style: AppTextStyles.screenSubtitle,
                ),
                const SizedBox(height: 20),
                SegmentedControl(
                  options: [t.authSignIn, t.authCreateAccount],
                  selectedIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 16),
                if (_isLogin) ..._loginFields(t) else ..._signupFields(t),
                const SizedBox(height: 4),
                TrailwattButton(
                  label: _isLogin ? t.authSignIn : t.authCreateAccount,
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(_isLogin ? '/home' : '/profile'),
                ),
                // Social/import shortcuts are LOGIN-ONLY - Criar Conta stays
                // fully manual per Constitution Article II.
                if (_isLogin) ...[
                  const SizedBox(height: 20),
                  _Divider(label: t.authOr),
                  const SizedBox(height: 14),
                  TrailwattButton(
                      label: 'Google',
                      style: TrailwattButtonStyle.secondary,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/home')),
                  const SizedBox(height: 8),
                  TrailwattButton(
                      label: 'Apple',
                      style: TrailwattButtonStyle.secondary,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/home')),
                  const SizedBox(height: 8),
                  TrailwattButton(
                      label: 'Microsoft',
                      style: TrailwattButtonStyle.secondary,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/home')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _loginFields(AppLocalizations t) {
    return [
      TrailwattField(label: t.authEmail, hint: t.authEmailHint),
      TrailwattField(
          label: t.authPassword, hint: t.authPasswordHint, obscureText: true),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(t.authForgotPassword,
              style: AppTextStyles.label.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }

  List<Widget> _signupFields(AppLocalizations t) {
    return [
      TrailwattField(label: t.authName, hint: t.authNameHint),
      TrailwattField(label: t.authEmail, hint: t.authEmailHint),
      TrailwattField(label: t.authBirthDate, hint: t.authBirthDateHint),
      TrailwattField(
          label: t.authPassword,
          hint: t.authCreatePasswordHint,
          obscureText: true),
      TrailwattField(
          label: t.authConfirmPassword,
          hint: t.authConfirmPasswordHint,
          obscureText: true),
      ConsentCheckbox(
        value: _consent,
        onChanged: (v) => setState(() => _consent = v),
        label: Text.rich(
          TextSpan(
            style: AppTextStyles.label.copyWith(fontSize: 9.5),
            children: [
              TextSpan(text: t.authConsentPrefix),
              TextSpan(
                  text: t.authConsentTerms,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
              TextSpan(text: t.authConsentMiddle),
              TextSpan(
                  text: t.authConsentPrivacy,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child:
              Text(label, style: AppTextStyles.label.copyWith(fontSize: 9.5)),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}
