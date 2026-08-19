import 'package:flutter/material.dart';
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
              .showSnackBar(const SnackBar(content: Text('Em breve')));
          return;
        }
        if (i == currentIndex) return;
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined), label: 'Treino'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined), label: 'Calendario'),
        BottomNavigationBarItem(
            icon: Icon(Icons.history), label: 'Historico'),
        BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz), label: 'Mais'),
      ],
    );
  }
}
