import 'package:flutter/material.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';

/// Maps to the bottom tab bar shown on screens 08a/08b/08c ("Treino /
/// Calendario / Historico / Mais"). Shared by every screen that sits at
/// the root of a tab, so the four destinations stay one taxonomy.
class TrailwattBottomNav extends StatelessWidget {
  final int currentIndex;

  const TrailwattBottomNav({super.key, required this.currentIndex});

  static const _routes = ['/home', '/calendar/week', '/history', null];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.inkSoft,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        final route = _routes[i];
        if (route == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(tr(context).navComingSoon)));
          return;
        }
        if (i == currentIndex) return;
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
      },
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.bolt_outlined),
            label: tr(context).navWorkout),
        BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: tr(context).navCalendar),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history), label: tr(context).navHistory),
        BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz), label: tr(context).navMore),
      ],
    );
  }
}
