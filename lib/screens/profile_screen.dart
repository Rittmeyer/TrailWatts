import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of the "Criar perfil" screen. Weight and FTP are the only
/// required inputs the physics engine needs (Constitution Article I);
/// the power curve is optional and refines short/intense stimuli.
/// Import stays read-scoped and optional (Constitution Article II).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _weightController = TextEditingController(text: '74');
  final _ftpController = TextEditingController(text: '210');
  final _power5sController = TextEditingController();
  final _power1minController = TextEditingController();
  final _power5minController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _ftpController.dispose();
    _power5sController.dispose();
    _power1minController.dispose();
    _power5minController.dispose();
    super.dispose();
  }

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
                Text('Criar perfil',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Peso e FTP obrigatorios. O resto e opcional.',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 20),
                TrailwattField(
                  label: 'Peso (kg)',
                  hint: '74',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'FTP (watts)',
                  hint: '210',
                  controller: _ftpController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text('CURVA DE POTENCIA',
                    style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TrailwattField(
                  label: 'Potencia 5s (w)',
                  hint: 'opcional · ex: 850',
                  controller: _power5sController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'Potencia 1min (w)',
                  hint: 'opcional · ex: 420',
                  controller: _power1minController,
                  keyboardType: TextInputType.number,
                ),
                TrailwattField(
                  label: 'Potencia 5min (w)',
                  hint: 'opcional · ex: 260',
                  controller: _power5minController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TrailwattButton(
                  label: 'Importar do Strava/Garmin',
                  style: TrailwattButtonStyle.secondary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Conexao opcional - preenche a curva via API')));
                  },
                ),
                const SizedBox(height: 4),
                Text('preenche a curva via API',
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
                const SizedBox(height: 20),
                TrailwattButton(
                  label: 'Salvar perfil',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/workout-builder'),
                ),
                const SizedBox(height: 14),
                Text(
                  'Peso e FTP bastam para o motor funcionar. A curva de '
                  'potencia refina estimulos curtos e intensos, e pode vir '
                  'da API em vez de digitada a mao.',
                  style: AppTextStyles.label.copyWith(fontSize: 9, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
