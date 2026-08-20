import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/screens/calendar_month_screen.dart';
import 'package:trailwatt/screens/calendar_week_screen.dart';
import 'package:trailwatt/screens/historico_screen.dart';
import 'package:trailwatt/screens/profile_screen.dart';
import 'package:trailwatt/screens/route_map_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/rider_profile_store.dart';
import 'package:trailwatt/widgets/zone_pill.dart';

import 'l10n_harness.dart';

/// Two rules, both about the rider's own zone table:
///
/// 1. The zone is named inside each individual activity - and in the profile,
///    where the table is configured. Not as a legend strip on the calendar or
///    any other overview: a month of days is not one effort.
/// 2. Whatever zone is shown is resolved on the table the rider chose. The
///    profile used to hold that choice in widget state and drop it on save,
///    while every other screen hardcoded seven power zones.

/// FTP 120 makes the two tables disagree about the same effort: 241 w is
/// 200% of it, which is neuromuscular Z7 on the seven-zone table but
/// VO2max Z5 on the five-zone one, where Coggan's top three collapse into
/// one. Anything that reads the wrong table shows the wrong zone number.
const _sevenZoneRider = RiderProfile(
  weightKg: 74,
  ftpWatts: 120,
  powerZones: PowerZoneSettings(scale: ZoneScale.seven),
);

const _fiveZoneRider = RiderProfile(
  weightKg: 74,
  ftpWatts: 120,
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

  group('each activity names its own zone, on the rider\'s table', () {
    testWidgets('history labels every activity', (tester) async {
      await tester.pumpWidget(localized(const HistoricoScreen()));
      await tester.pump();

      // Three demo activities, three zones - the list used to show watts
      // with no indication of what they meant.
      expect(find.byType(ZonePill), findsNWidgets(3));
    });

    testWidgets('a seven-zone rider sees 241 w as Z7', (tester) async {
      store.save(_sevenZoneRider);

      await tester.pumpWidget(localized(const HistoricoScreen()));
      await tester.pump();

      expect(find.textContaining('Z7 ·'), findsOneWidget);
    });

    testWidgets('the same activity is Z5 for a five-zone rider',
        (tester) async {
      store.save(_fiveZoneRider);

      await tester.pumpWidget(localized(const HistoricoScreen()));
      await tester.pump();

      // Collapsing Coggan's top three into one is the whole point of the
      // five-zone table, so all three demo efforts land in Z5 together -
      // and Z6/Z7 do not exist to be shown.
      expect(find.textContaining('Z7 ·'), findsNothing);
      expect(find.textContaining('Z6 ·'), findsNothing);
      expect(find.textContaining('Z5 ·'), findsNWidgets(3));
    });

    testWidgets('changing the profile relabels a list already on screen',
        (tester) async {
      store.save(_sevenZoneRider);
      await tester.pumpWidget(localized(const HistoricoScreen()));
      await tester.pump();
      expect(find.textContaining('Z7 ·'), findsOneWidget);

      store.save(_fiveZoneRider);
      await tester.pump();

      expect(find.textContaining('Z7 ·'), findsNothing);
    });

    testWidgets('a completed day on the calendar names its zone',
        (tester) async {
      await tester.pumpWidget(localized(const CalendarWeekScreen()));
      await tester.pump();

      // 21 July is the ride already linked to its planned day. Both are
      // named: the zone the rider actually held, and the one the plan asked
      // for - which is the comparison the calibration loop runs on.
      await tester.tap(find.text('21'));
      await tester.pumpAndSettle();

      expect(find.byType(ZonePill), findsNWidgets(2));
    });

    testWidgets('the route names the zone of that one stretch', (tester) async {
      store.save(_fiveZoneRider);

      await tester.pumpWidget(localized(const RouteMapScreen()));
      await tester.pump();

      // One chip for this stretch, not a table of every zone.
      expect(find.byType(ZonePill), findsOneWidget);
    });
  });

  group('overviews carry no zone legend', () {
    testWidgets('the month calendar shows only the selected day\'s zone',
        (tester) async {
      await tester.pumpWidget(localized(const CalendarMonthScreen()));
      await tester.pump();

      // A legend would render one pill per zone in the table; the day panel
      // renders exactly one.
      expect(find.byType(ZonePill), findsOneWidget);
    });

    testWidgets('a five-zone profile does not resurrect a legend',
        (tester) async {
      store.save(_fiveZoneRider);

      await tester.pumpWidget(localized(const CalendarMonthScreen()));
      await tester.pump();

      expect(find.byType(ZonePill), findsOneWidget);
    });
  });

  testWidgets('the workout builder offers only the zones the rider has',
      (tester) async {
    store.save(_fiveZoneRider);

    await tester.pumpWidget(localized(const WorkoutBuilderScreen()));
    await tester.pump();

    expect(find.textContaining('Z1-Z5'), findsOneWidget);
    expect(find.textContaining('Z1-Z7'), findsNothing);
  });

  group('the profile is where the table is configured and kept', () {
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
      // editor. The profile keeps its full table - that is where the rider
      // reads what each zone covers.
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
