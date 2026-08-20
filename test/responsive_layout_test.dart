import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/historico_screen.dart';
import 'package:trailwatt/screens/more_screen.dart';
import 'package:trailwatt/screens/profile_screen.dart';
import 'package:trailwatt/screens/treino_do_dia_screen.dart';
import 'package:trailwatt/theme/layout.dart';

import 'l10n_harness.dart';

/// The layout follows the window, not the platform: the same build has to
/// read as a phone app when the browser is narrow and as a desktop app when
/// it is not.
void main() {
  final t = stringsFor(const Locale('pt'));

  Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(
      screen,
      routes: {
        '/history': (_) => const HistoricoScreen(),
        '/more': (_) => const MoreScreen(),
      },
    ));
    await tester.pump();
  }

  /// How wide the screen's own content actually got, ignoring the rail and
  /// the empty background either side of it.
  double contentWidth(WidgetTester tester) => tester
      .getSize(find
          .descendant(
              of: find.byType(ContentWidth),
              matching: find.byType(ConstrainedBox))
          .first)
      .width;

  group('where the destinations sit', () {
    testWidgets('a phone-width window keeps them along the bottom',
        (tester) async {
      await pumpAt(tester, const Size(400, 800), const TreinoDoDiaScreen());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('a wide window moves them to a side rail', (tester) async {
      await pumpAt(tester, const Size(1400, 900), const TreinoDoDiaScreen());

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      // Four icons stretched across a wall was the complaint; a rail is only
      // an answer if it stays a rail.
      expect(tester.getSize(find.byType(NavigationRail)).width, lessThan(300));
    });

    testWidgets('the rail names the app only when it has room for it',
        (tester) async {
      await pumpAt(tester, const Size(1400, 900), const TreinoDoDiaScreen());
      expect(find.text(t.appTitle), findsOneWidget);

      await pumpAt(tester, const Size(800, 900), const TreinoDoDiaScreen());
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text(t.appTitle), findsNothing);
    });

    testWidgets('both shapes offer the same four destinations', (tester) async {
      for (final size in [const Size(400, 800), const Size(1400, 900)]) {
        await pumpAt(tester, size, const TreinoDoDiaScreen());
        for (final label in [
          t.navWorkout,
          t.navCalendar,
          t.navHistory,
          t.navMore,
        ]) {
          expect(find.text(label), findsOneWidget, reason: '$label at $size');
        }
      }
    });

    testWidgets('the rail navigates like the bottom bar does', (tester) async {
      await pumpAt(tester, const Size(1400, 900), const TreinoDoDiaScreen());

      await tester.tap(find.text(t.navMore));
      await tester.pumpAndSettle();

      expect(find.text(t.moreSubtitle), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('how wide the content gets', () {
    testWidgets('a wide window does not stretch the content with it',
        (tester) async {
      await pumpAt(tester, const Size(1400, 900), const TreinoDoDiaScreen());

      expect(contentWidth(tester), lessThanOrEqualTo(ContentWidth.readable));
    });

    testWidgets('a narrow window uses everything it has', (tester) async {
      await pumpAt(tester, const Size(400, 800), const TreinoDoDiaScreen());

      expect(contentWidth(tester), 400);
    });

    testWidgets('a pushed screen is capped too, without a rail',
        (tester) async {
      await pumpAt(tester, const Size(1400, 900), const ProfileScreen());

      expect(find.byType(NavigationRail), findsNothing);
      expect(contentWidth(tester), lessThanOrEqualTo(ContentWidth.readable));
    });
  });

  group('the breakpoints themselves', () {
    test('a width lands in one size, and the boundaries belong upward', () {
      expect(LayoutSize.fromWidth(599), LayoutSize.compact);
      expect(LayoutSize.fromWidth(600), LayoutSize.medium);
      expect(LayoutSize.fromWidth(1099), LayoutSize.medium);
      expect(LayoutSize.fromWidth(1100), LayoutSize.expanded);
    });
  });
}
