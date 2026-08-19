import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Maps to .consent-row / .checkbox-box - the Termos de Uso consent row
/// on Criar Conta (01a/01b).
class ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  const ConsentCheckbox(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 1, right: 8),
              decoration: BoxDecoration(
                color: value ? AppColors.accent : Colors.transparent,
                border: Border.all(
                    color: value ? AppColors.accent : AppColors.line,
                    width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            Expanded(child: label),
          ],
        ),
      ),
    );
  }
}
