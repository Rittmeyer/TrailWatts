import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/main.dart';
import 'package:trailwatt/routes/screen_inventory.dart';
import 'package:trailwatt/widgets/app_shell.dart';
import 'package:trailwatt/widgets/page_header.dart';

import 'l10n_harness.dart';

/// Every screen can be reached, and every screen can be left.
///
/// Both used to be false in places: the route map and the workout builder
/// had no exit on the screen at all, and the whole import flow had nothing
/// linking to it. These tests read the screen inventory, so a new screen is
/// covered the day it is added rather than the day someone notices.
void main() {
  /// Reached by the app starting up, not by a link.
  const entryPoints = {'/', '/splash', '/auth'};

  /// Reached by the bottom bar or the side rail, which is their exit too.
  const tabRoots = {'/home', '/calendar/week', '/history', '/more'};

  final candidates = screenInventory
      .where((s) => s.implemented)
      .where((s) => !entryPoints.contains(s.route))
      .toList();

  /// Starts on the "More" tab, so leaving a pushed screen has somewhere
  /// recognisable to land.
  Future<NavigatorState> start(WidgetTester tester) async {
    await tester.pumpWidget(const TrailwattApp());
    // The splash hands over to /auth after a delay of its own.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamedAndRemoveUntil('/more', (r) => false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return nav;
  }

  Future<void> settle(WidgetTester tester) async {
    // Map screens keep asking for tiles that never arrive here, so
    // pumpAndSettle would wait for a quiet frame that never comes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final t = stringsFor(const Locale('en'));

  group('every pushed screen offers a way out', () {
    for (final spec in candidates) {
      testWidgets('${spec.route} (${spec.title})', (tester) async {
        final nav = await start(tester);
        nav.pushNamed(spec.route);
        await settle(tester);

        // A screen inside the nav shell is left the way it was entered, by
        // the bottom bar or the rail. Everything else needs a header.
        if (find.byType(TrailwattShell).evaluate().isNotEmpty) {
          expect(
              find.byType(BottomNavigationBar).evaluate().length +
                  find.byType(NavigationRail).evaluate().length,
              greaterThan(0),
              reason: '${spec.route} is in the shell but shows no navigation');
          return;
        }

        expect(find.byType(PageHeader), findsOneWidget,
            reason: '${spec.route} has no header, so no exit on the screen');

        await tester.tap(find.descendant(
            of: find.byType(PageHeader), matching: find.byType(InkWell)));
        await settle(tester);

        // Back on the tab it was opened from, with the pushed screen gone.
        expect(find.text(t.moreSubtitle), findsOneWidget,
            reason: '${spec.route} did not go back when its exit was used');
        expect(find.byType(PageHeader), findsNothing);
      });
    }
  });

  group('the exit leads somewhere even with nothing to pop', () {
    testWidgets('a screen opened on an empty stack goes to the workout tab',
        (tester) async {
      final nav = await start(tester);

      // What a deep link on the web produces: the screen, and no history.
      nav.pushNamedAndRemoveUntil('/route-map', (r) => false);
      await settle(tester);
      expect(nav.canPop(), isFalse);

      await tester.tap(find.descendant(
          of: find.byType(PageHeader), matching: find.byType(InkWell)));
      await settle(tester);

      expect(find.text(t.todayTitle), findsOneWidget);
    });
  });

  group('every screen can be reached', () {
    /// Routes named anywhere in lib/ other than where they are declared.
    ///
    /// Matching the literal rather than a push call on purpose: a route can
    /// legitimately reach the navigator through a variable, and this only
    /// has to answer "does anything in the app know this screen exists".
    Set<String> linkedRoutes() {
      const declarations = {
        'lib/main.dart',
        'lib/routes/screen_inventory.dart'
      };
      final found = <String>{};
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !declarations.contains(f.path))) {
        final source = file.readAsStringSync();
        for (final spec in screenInventory) {
          if (source.contains("'${spec.route}'")) found.add(spec.route);
        }
      }
      return found;
    }

    test('no implemented screen is reachable only by typing its URL', () {
      final linked = linkedRoutes();
      // The nav shell builds its destinations from a list, so its four
      // routes are not literals anywhere a regex would find them.
      final orphans = screenInventory
          .where((s) => s.implemented)
          .where((s) => !entryPoints.contains(s.route))
          .where((s) => !tabRoots.contains(s.route))
          .where((s) => !linked.contains(s.route))
          .map((s) => '${s.route} (${s.title})')
          .toList();

      expect(orphans, isEmpty,
          reason: 'nothing in the app links to these screens');
    });
  });
}
