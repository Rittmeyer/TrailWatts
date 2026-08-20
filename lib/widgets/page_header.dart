import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The top of a screen that was pushed onto another one: the way out, then
/// the title and subtitle those screens all carried by hand anyway.
///
/// The way out is the point. Several screens here had none - you reached
/// the route map or the workout builder and the only exits were the phone's
/// back gesture or the browser's button, neither of which is on the screen.
/// Putting the exit in the header every pushed screen already needed makes
/// a dead end something you have to go out of your way to build.
///
/// It never leads nowhere. Normally it pops. When there is nothing to pop
/// back to - a deep link on the web, or a stack that was cleared - it goes
/// to the workout tab instead of rendering a link that does nothing.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Where back leads, when the screen has one entry point worth naming.
  /// Left null when a screen is reached from several places: "Back" is then
  /// the only label that is true from all of them.
  final String? backTo;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.backTo,
  });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final canPop = Navigator.of(context).canPop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => canPop
                ? Navigator.of(context).pop()
                : Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (r) => false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                t.backTo(canPop ? (backTo ?? t.backGeneric) : t.navWorkout),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTextStyles.screenSubtitle),
        ],
      ],
    );
  }
}
