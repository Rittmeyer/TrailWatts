import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/calendar_week_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/activity_store.dart';
import 'package:trailwatt/services/workout_plan_store.dart';

import 'l10n_harness.dart';

/// Selecting a day is how the rider changes it: a day still ahead offers
/// add, edit and remove; a completed one offers none of them.
void main() {
  final store = WorkoutPlanStore.instance;
  final activities = ActivityStore.instance;
  final t = stringsFor(const Locale('pt'));

  // The stores are app-wide, so each test leaves them as it found them.
  tearDown(() {
    activities.seedDemoActivities();
    store.seedDemoPlan();
  });

  Future<void> pumpWeek(WidgetTester tester) async {
    await tester.pumpWidget(localized(
      const CalendarWeekScreen(),
      routes: {'/workout-builder': (_) => const WorkoutBuilderScreen()},
    ));
    await tester.pump();
  }

  /// The demo week is July 2026: 20 is planned, 21 completed, 22 empty.
  Future<void> selectDay(WidgetTester tester, String day) async {
    await tester.tap(find.text(day));
    await tester.pumpAndSettle();
  }

  group('which actions a day offers', () {
    testWidgets('a planned day offers edit and remove', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      expect(find.text(t.calendarEditWorkout), findsOneWidget);
      expect(find.text(t.calendarRemoveWorkout), findsOneWidget);
      expect(find.text(t.calendarAddWorkout), findsNothing);
    });

    testWidgets('an empty day offers only add', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '22');

      expect(find.text(t.calendarAddWorkout), findsOneWidget);
      expect(find.text(t.calendarEditWorkout), findsNothing);
      expect(find.text(t.calendarRemoveWorkout), findsNothing);
    });

    testWidgets('a day whose result is recorded offers only to unlink it',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '21');

      // The plan it was measured against is not the rider's to revise while
      // a ride is recorded against it.
      expect(find.text(t.calendarAddWorkout), findsNothing);
      expect(find.text(t.calendarEditWorkout), findsNothing);
      expect(find.text(t.calendarRemoveWorkout), findsNothing);
      expect(find.text(t.calendarLinkActivity), findsNothing);
      expect(find.text(t.calendarUnlinkActivity), findsOneWidget);
      expect(find.text(t.calendarDone), findsOneWidget);
    });

    testWidgets('a planned day with loose rides offers to link one',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      expect(find.text(t.calendarLinkActivity), findsOneWidget);
      expect(find.text(t.calendarUnlinkActivity), findsNothing);
    });

    testWidgets('an empty day cannot be linked - there is no plan to link to',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '22');

      expect(find.text(t.calendarLinkActivity), findsNothing);
    });
  });

  group('associating a ride with a workout', () {
    testWidgets('lists only rides that are not already someone\'s result',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');
      await tester.tap(find.text(t.calendarLinkActivity));
      await tester.pumpAndSettle();

      expect(find.text(t.calendarLinkTitle), findsOneWidget);
      expect(find.text('Subida da Serra'), findsWidgets);
      expect(find.text('Treino indoor'), findsOneWidget);
      // Already the result of 21 July.
      expect(find.text('Circuito do parque'), findsNothing);
    });

    testWidgets('picking one records it as that day\'s result', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');
      expect(activities.isDone(DateTime(2026, 7, 20)), isFalse);

      await tester.tap(find.text(t.calendarLinkActivity));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Treino indoor'));
      await tester.pumpAndSettle();

      expect(activities.linkedTo(DateTime(2026, 7, 20))?.id, 'activity-indoor');
      // The day now reads as done, and the plan it was measured against
      // stays on screen beside the result.
      expect(find.text(t.calendarDone), findsOneWidget);
      expect(find.text(t.calendarEditWorkout), findsNothing);
    });

    testWidgets('dismissing the sheet links nothing', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      await tester.tap(find.text(t.calendarLinkActivity));
      await tester.pumpAndSettle();
      // Tapping outside the sheet dismisses it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(activities.isDone(DateTime(2026, 7, 20)), isFalse);
    });
  });

  group('disassociating a ride', () {
    testWidgets('asks first, and keeps the link when cancelled',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '21');

      await tester.tap(find.text(t.calendarUnlinkActivity));
      await tester.pumpAndSettle();
      expect(find.text(t.calendarUnlinkTitle), findsOneWidget);

      await tester.tap(find.text(t.editRouteCancel));
      await tester.pumpAndSettle();

      expect(activities.isDone(DateTime(2026, 7, 21)), isTrue);
    });

    testWidgets('confirming hands the day back and keeps the ride',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '21');

      await tester.tap(find.text(t.calendarUnlinkActivity));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(t.calendarUnlinkActivity),
      ));
      await tester.pumpAndSettle();

      expect(activities.isDone(DateTime(2026, 7, 21)), isFalse);
      // The ride is still in the rider's history, just loose again.
      expect(
          activities.activities.map((a) => a.id), contains('activity-parque'));
      // The day is a plan again, with its actions back.
      expect(find.text(t.calendarEditWorkout), findsOneWidget);
      expect(find.text(t.calendarRemoveWorkout), findsOneWidget);
    });
  });

  group('removing', () {
    testWidgets('asks first, and leaves the day alone when cancelled',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      await tester.tap(find.text(t.calendarRemoveWorkout));
      await tester.pumpAndSettle();
      expect(find.text(t.calendarRemoveTitle), findsOneWidget);

      await tester.tap(find.text(t.editRouteCancel));
      await tester.pumpAndSettle();

      expect(store.hasWorkout(DateTime(2026, 7, 20)), isTrue);
    });

    testWidgets('clears the day once confirmed', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      await tester.tap(find.text(t.calendarRemoveWorkout));
      await tester.pumpAndSettle();
      // The dialog's confirm carries the same label as the button that
      // opened it, so reach for the one inside the dialog.
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(t.calendarRemoveWorkout),
      ));
      await tester.pumpAndSettle();

      expect(store.hasWorkout(DateTime(2026, 7, 20)), isFalse);
      // The day panel goes back to being a rest day, offering to add.
      expect(find.text(t.calendarAddWorkout), findsOneWidget);
    });
  });

  group('adding and editing', () {
    testWidgets('adding opens the builder and writes the day on save',
        (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '22');
      expect(store.hasWorkout(DateTime(2026, 7, 22)), isFalse);

      await tester.tap(find.text(t.calendarAddWorkout));
      await tester.pumpAndSettle();

      // Opened for a specific day, the builder saves onto it rather than
      // continuing to the route search.
      expect(find.text(t.builderSaveToDay), findsOneWidget);
      expect(find.text(t.builderContinue), findsNothing);

      await tester.ensureVisible(find.text(t.builderSaveToDay));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.builderSaveToDay));
      await tester.pumpAndSettle();

      expect(store.hasWorkout(DateTime(2026, 7, 22)), isTrue);
      // The seeded example is one block of two stimuli, so the day gets both.
      expect(store.entryFor(DateTime(2026, 7, 22))!.planned, hasLength(2));
    });

    testWidgets('editing opens on what the day already holds', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '20');

      await tester.tap(find.text(t.calendarEditWorkout));
      await tester.pumpAndSettle();

      // The planned day holds an 8 min effort and its 2 min recovery, so
      // the builder opens with those durations already filled in rather
      // than with its own example.
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text(t.builderSaveToDay), findsOneWidget);
    });

    testWidgets('the builder reached any other way still goes to the route',
        (tester) async {
      await tester.pumpWidget(localized(const WorkoutBuilderScreen()));
      await tester.pump();

      expect(find.text(t.builderContinue), findsOneWidget);
      expect(find.text(t.builderSaveToDay), findsNothing);
    });
  });
}
