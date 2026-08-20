import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout.dart';

/// The four root destinations ("Treino / Calendario / Historico / Mais"),
/// declared once. The bottom bar and the side rail are two shapes of this
/// one list, so widening a window can never change what the app offers -
/// only where the offer sits.
class _Destination {
  final IconData icon;
  final String label;
  final String route;

  const _Destination(this.icon, this.label, this.route);
}

List<_Destination> _destinations(AppLocalizations t) => [
      _Destination(Icons.bolt_outlined, t.navWorkout, '/home'),
      _Destination(
          Icons.calendar_today_outlined, t.navCalendar, '/calendar/week'),
      _Destination(Icons.history, t.navHistory, '/history'),
      _Destination(Icons.more_horiz, t.navMore, '/more'),
    ];

void _go(BuildContext context, int index, int currentIndex) {
  if (index == currentIndex) return;
  final route = _destinations(tr(context))[index].route;
  Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
}

/// The frame every root screen sits in.
///
/// It picks the navigation shape from the window width rather than from the
/// platform: a browser window dragged narrow should behave like a phone, and
/// a tablet held wide should not get phone chrome.
class TrailwattShell extends StatelessWidget {
  final int navIndex;
  final Widget child;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  const TrailwattShell({
    super.key,
    required this.navIndex,
    required this.child,
    this.floatingActionButton,
    this.maxContentWidth = ContentWidth.readable,
  });

  @override
  Widget build(BuildContext context) {
    final size = LayoutSize.of(context);
    final body = SafeArea(
      child: ContentWidth(maxWidth: maxContentWidth, child: child),
    );

    if (size.isCompact) {
      return Scaffold(
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: TrailwattBottomNav(currentIndex: navIndex),
      );
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _NavRail(
            currentIndex: navIndex,
            extended: size == LayoutSize.expanded,
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The compact shape of the four destinations.
class TrailwattBottomNav extends StatelessWidget {
  final int currentIndex;

  const TrailwattBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.inkSoft,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => _go(context, i, currentIndex),
      items: [
        for (final d in _destinations(tr(context)))
          BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
      ],
    );
  }
}

/// The wide shape of the same four destinations.
class _NavRail extends StatelessWidget {
  final int currentIndex;
  final bool extended;

  const _NavRail({required this.currentIndex, required this.extended});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return NavigationRail(
      selectedIndex: currentIndex,
      extended: extended,
      // NavigationRail rejects a labelType while extended - the labels are
      // already beside the icons there.
      labelType: extended ? null : NavigationRailLabelType.all,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.greenBg,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.inkSoft),
      selectedLabelTextStyle: AppTextStyles.label.copyWith(
          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle:
          AppTextStyles.label.copyWith(color: AppColors.inkSoft, fontSize: 12),
      leading: _RailHeader(extended: extended, title: t.appTitle),
      onDestinationSelected: (i) => _go(context, i, currentIndex),
      destinations: [
        for (final d in _destinations(t))
          NavigationRailDestination(
            icon: Icon(d.icon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

/// Says which app this is. On a phone the bottom bar sits under a screen
/// that already carries a title; a desktop rail has room to name itself.
class _RailHeader extends StatelessWidget {
  final bool extended;
  final String title;

  const _RailHeader({required this.extended, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: extended
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.terrain_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(title,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 17)),
              ],
            )
          : const Icon(Icons.terrain_outlined,
              color: AppColors.primary, size: 22),
    );
  }
}
