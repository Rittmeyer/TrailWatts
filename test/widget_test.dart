import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/main.dart';
import 'package:trailwatt/screens/calendar_week_screen.dart';
import 'package:trailwatt/screens/historico_screen.dart';
import 'package:trailwatt/screens/profile_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';

import 'l10n_harness.dart';

void main() {
  testWidgets('boots on the splash screen and moves on to auth',
      (tester) async {
    await tester.pumpWidget(const TrailwattApp());
    final t = stringsFor(const Locale('en'));

    expect(find.text('TRAILWATT'), findsOneWidget);

    // The splash hands over after ~1.1s. Pump past it rather than settling:
    // the splash spinner animates forever and would never settle.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(t.authWelcome), findsOneWidget);
    expect(find.text(t.authCreateAccount), findsWidgets);
  });

  group('screens build without throwing', () {
    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(localized(screen));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    testWidgets('profile, with both zone tables', (tester) async {
      final t = stringsFor(const Locale('pt'));
      await pumpScreen(tester, const ProfileScreen());
      expect(find.text(t.profilePowerZones), findsOneWidget);
      expect(find.text(t.profileHeartRateZones), findsOneWidget);
      // Seven power zones and five heart-rate zones by default.
      expect(find.text('Z7'), findsOneWidget);
      expect(find.text('Z6'), findsOneWidget);
    });

    testWidgets('workout builder', (tester) async {
      await pumpScreen(tester, const WorkoutBuilderScreen());
      expect(find.textContaining('Z1-Z7'), findsOneWidget);
    });

    testWidgets('history', (tester) async {
      await pumpScreen(tester, const HistoricoScreen());
    });

    testWidgets('calendar week', (tester) async {
      await pumpScreen(tester, const CalendarWeekScreen());
    });
  });

  group('the app follows the locale', () {
    testWidgets('the same screen renders in pt and in en', (tester) async {
      final pt = stringsFor(const Locale('pt'));
      final en = stringsFor(const Locale('en'));
      // Guard against a "translation" that never got translated.
      expect(pt.profileTitle, isNot(en.profileTitle));

      await tester.pumpWidget(
          localized(const ProfileScreen(), locale: const Locale('pt')));
      await tester.pump();
      expect(find.text(pt.profileTitle), findsOneWidget);
      expect(find.text(en.profileTitle), findsNothing);

      await tester.pumpWidget(
          localized(const ProfileScreen(), locale: const Locale('en')));
      await tester.pump();
      expect(find.text(en.profileTitle), findsOneWidget);
      expect(find.text(pt.profileTitle), findsNothing);
    });

    testWidgets('zone names come from the locale, not the model',
        (tester) async {
      final pt = stringsFor(const Locale('pt'));
      final en = stringsFor(const Locale('en'));

      await tester.pumpWidget(
          localized(const ProfileScreen(), locale: const Locale('en')));
      await tester.pump();
      expect(find.text(en.zoneThreshold), findsWidgets);
      expect(find.text(pt.zoneThreshold), findsNothing);
    });

    testWidgets('an unsupported locale falls back rather than crashing',
        (tester) async {
      await tester.pumpWidget(
          localized(const ProfileScreen(), locale: const Locale('ja')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Falls back to the template locale.
      expect(find.text(stringsFor(const Locale('en')).profileTitle),
          findsOneWidget);
    });
  });
}
