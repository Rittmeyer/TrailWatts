import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The way back out of a pushed screen, naming where it goes.
///
/// A phone has a system back gesture; a browser tab has a button most people
/// will not use mid-form. Screens that can only be left by guessing are the
/// kind of thing that reads as "not intuitive", so the way out is on the
/// screen, and says where it leads.
class BackLink extends StatelessWidget {
  /// Where popping lands - the screen's name, not "back".
  final String destination;

  const BackLink({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(
            tr(context).backTo(destination),
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
