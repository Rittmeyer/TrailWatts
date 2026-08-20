import 'package:flutter/material.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  _isLogin
                      ? 'Acesse sua conta Trailwatt'
                      : 'Leva menos de um minuto',
                  style: AppTextStyles.screenSubtitle,
                ),
                const SizedBox(height: 20),
                SegmentedControl(
                  options: const ['Entrar', 'Criar conta'],
                  selectedIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 16),
                if (_isLogin) ..._loginFields() else ..._signupFields(),
                const SizedBox(height: 4),
                TrailwattButton(
                  label: _isLogin ? 'Entrar' : 'Criar conta',
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(_isLogin ? '/home' : '/profile'),
                ),
                // Social/import shortcuts are LOGIN-ONLY - Criar Conta stays
                // fully manual per Constitution Article II.
                if (_isLogin) ...[
                  const SizedBox(height: 20),
                  const _Divider(label: 'OU'),
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

  List<Widget> _loginFields() {
    return [
      const TrailwattField(label: 'Email', hint: 'nome@email.com'),
      const TrailwattField(
          label: 'Senha', hint: 'sua senha', obscureText: true),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('Esqueceu a senha?',
              style: AppTextStyles.label.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }

  List<Widget> _signupFields() {
    return [
      const TrailwattField(label: 'Nome', hint: 'seu nome'),
      const TrailwattField(label: 'Email', hint: 'nome@email.com'),
      const TrailwattField(label: 'Data de nascimento', hint: 'DD/MM/AAAA'),
      const TrailwattField(
          label: 'Senha', hint: 'crie uma senha', obscureText: true),
      const TrailwattField(
          label: 'Confirmar senha', hint: 'repita a senha', obscureText: true),
      ConsentCheckbox(
        value: _consent,
        onChanged: (v) => setState(() => _consent = v),
        label: Text.rich(
          TextSpan(
            style: AppTextStyles.label.copyWith(fontSize: 9.5),
            children: const [
              TextSpan(text: 'Concordo com os '),
              TextSpan(
                  text: 'Termos de Uso',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
              TextSpan(text: ' e a '),
              TextSpan(
                  text: 'Politica de Privacidade',
                  style: TextStyle(
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
