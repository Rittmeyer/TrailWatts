import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Maps to .stat / .stat-label / .stat-value.
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatBox(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 8.5)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.numeric
                  .copyWith(fontSize: 14, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}
