import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/screens/calendar_month_screen.dart';
import 'package:trailwatt/screens/profile_screen.dart';
import 'package:trailwatt/screens/route_map_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/rider_profile_store.dart';

import 'l10n_harness.dart';

/// The rider chose Z1-Z5 in their profile, and every other screen has to
/// honour that. Before `RiderProfileStore` existed the choice never left the
/// profile form: the calendar, the route legend and the workout builder each
/// hardcoded seven power zones, so a five-zone rider was shown Z6 and Z7
/// throughout.
const _fiveZoneRider = RiderProfile(
  weightKg: 74,
  ftpWatts: 210,
  powerZones: PowerZoneSettings(scale: ZoneScale.five),
  heartRateZones: HeartRateZoneSettings(
    scale: ZoneScale.five,
    anchor: HeartRateAnchor.lactateThreshold,
    lthrBpm: 168,
  ),
);

void main() {
  final store = RiderProfileStore.instance;

  // The store is app-wide, so each test leaves it as it found it.
  tearDown(() => store.save(RiderProfileStore.demoRider));

  group('the calendar renders the rider\'s own zone table', () {
    testWidgets('a five-zone profile shows five zones, with no Z6 or Z7',
        (tester) async {
      store.save(_fiveZoneRider);

      await tester.pumpWidget(localized(const CalendarMonthScreen()));
      await tester.pump();

      expect(find.textContaining('Z5 ·'), findsOneWidget);
      expect(find.textContaining('Z6 ·'), findsNothing);
      expect(find.textContaining('Z7 ·'), findsNothing);
    });

    testWidgets('a seven-zone profile still shows all seven', (tester) async {
      store.save(RiderProfileStore.demoRider);

      await tester.pumpWidget(localized(const CalendarMonthScreen()));
      await tester.pump();

      expect(find.textContaining('Z6 ·'), findsOneWidget);
      expect(find.textContaining('Z7 ·'), findsOneWidget);
    });

    testWidgets('changing the profile updates a calendar already on screen',
        (tester) async {
      await tester.pumpWidget(localized(const CalendarMonthScreen()));
      await tester.pump();
      expect(find.textContaining('Z7 ·'), findsOneWidget);

      store.save(_fiveZoneRider);
      await tester.pump();

      expect(find.textContaining('Z7 ·'), findsNothing);
    });
  });

  testWidgets('the route legend follows the profile too', (tester) async {
    store.save(_fiveZoneRider);

    await tester.pumpWidget(localized(const RouteMapScreen()));
    await tester.pump();

    expect(find.textContaining('Z5 ·'), findsOneWidget);
    expect(find.textContaining('Z6 ·'), findsNothing);
  });

  testWidgets('the workout builder offers only the zones the rider has',
      (tester) async {
    store.save(_fiveZoneRider);

    await tester.pumpWidget(localized(const WorkoutBuilderScreen()));
    await tester.pump();

    // The header names the active table.
    expect(find.textContaining('Z1-Z5'), findsOneWidget);
    expect(find.textContaining('Z1-Z7'), findsNothing);
  });

  group('the profile form is where the choice is made and kept', () {
    testWidgets('picking Z1-Z5 and saving writes it to the shared profile',
        (tester) async {
      expect(store.powerScale, ZoneScale.seven);

      await tester.pumpWidget(localized(
        const ProfileScreen(),
        routes: {'/home': (_) => const Scaffold(body: Text('home'))},
      ));
      await tester.pump();

      // The first Z1-Z5 control is the power table; the second is heart rate.
      await tester.tap(find.text('Z1-Z5').first);
      await tester.pump();

      // The form is longer than the test viewport, so the save button has to
      // be scrolled into reach or the tap silently misses it.
      final save = find.text(stringsFor(const Locale('pt')).profileSave);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.powerScale, ZoneScale.five,
          reason: 'the choice has to leave the form to mean anything');
    });

    testWidgets('reopening the form shows what the rider saved',
        (tester) async {
      store.save(_fiveZoneRider);

      await tester.pumpWidget(localized(const ProfileScreen()));
      await tester.pump();

      // Five power zones and five heart-rate zones: no Z6/Z7 row in either
      // editor.
      expect(find.text('Z6'), findsNothing);
      expect(find.text('Z7'), findsNothing);
      expect(find.text('Z5'), findsNWidgets(2));
    });

    testWidgets('an unreadable FTP keeps the saved one rather than zeroing it',
        (tester) async {
      await tester.pumpWidget(localized(
        const ProfileScreen(),
        routes: {'/home': (_) => const Scaffold(body: Text('home'))},
      ));
      await tester.pump();

      final t = stringsFor(const Locale('pt'));
      await tester.enterText(find.widgetWithText(TextField, '210').first, '');
      await tester.pump();

      final save = find.text(t.profileSave);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      // FTP anchors the entire power table; saving zero would collapse it.
      expect(store.profile.ftpWatts, 210);
      expect(find.text('home'), findsOneWidget,
          reason: 'the save must actually have run for this to prove anything');
    });
  });
}
