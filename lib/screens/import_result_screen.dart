import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/stat_box.dart';
import '../widgets/trailwatt_field.dart';
import '../widgets/trailwatt_button.dart';

/// Port of screen 06 - "Resultado do treino". The API-matched activity is
/// the primary path; manual entry is the documented fallback and stays
/// visually secondary (Constitution Article III). The rider still has to
/// confirm the match - nothing here auto-confirms silently.
class ImportResultScreen extends StatelessWidget {
  const ImportResultScreen({super.key});

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
                Text('Resultado do treino',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Buscado automaticamente via API',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('CONECTADO AO STRAVA',
                      style: AppTextStyles.label.copyWith(
                          fontSize: 8.5,
                          color: AppColors.greenText,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Atividade encontrada',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Subida da Serra · hoje, 07:14',
                          style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                              child: StatBox(
                                  label: 'POTENCIA MED.', value: '182w')),
                          SizedBox(width: 8),
                          Expanded(
                              child: StatBox(label: 'FC MEDIA', value: '152')),
                          SizedBox(width: 8),
                          Expanded(
                              child: StatBox(label: 'DURACAO', value: '41m')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TrailwattButton(
                  label: 'Confirmar e salvar',
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/history'),
                ),
                const SizedBox(height: 26),
                Text('SEM CONEXAO COM A API?',
                    style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const TrailwattField(
                  label: 'Potencia media (w)',
                  hint: 'informar manualmente',
                  keyboardType: TextInputType.number,
                  helperText:
                      'Menos preciso - use apenas se a importacao automatica falhar.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/import-result/manual-intervals'),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Preencher manualmente por estimulo',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A API busca a atividade correspondente automaticamente. A '
                  'entrada manual so aparece como ultimo recurso, e fica '
                  'visualmente secundaria.',
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
