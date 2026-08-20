import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum TrailwattButtonStyle { primary, secondary, dashed }

/// Maps 1:1 to .btn-primary / .btn-secondary / .add-serie-btn in the HTML
/// prototype.
class TrailwattButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TrailwattButtonStyle style;

  const TrailwattButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = TrailwattButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case TrailwattButtonStyle.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(label, style: AppTextStyles.button),
          ),
        );
      case TrailwattButtonStyle.secondary:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(label, style: AppTextStyles.button),
          ),
        );
      case TrailwattButtonStyle.dashed:
        return InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.button
                  .copyWith(color: AppColors.primary, fontSize: 10.5),
            ),
          ),
        );
    }
  }
}
