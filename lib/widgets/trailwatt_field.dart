import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Maps to the .fld-label + .fld pair used throughout the prototype
/// (profile, criar conta, criar treino...).
class TrailwattField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? helperText;

  const TrailwattField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: AppTextStyles.body,
            decoration: InputDecoration(hintText: hint),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 3),
            Text(helperText!,
                style: AppTextStyles.label.copyWith(fontSize: 8)),
          ],
        ],
      ),
    );
  }
}
