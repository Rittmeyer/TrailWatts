import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/calendar_week_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/workout_plan_store.dart';

import 'l10n_harness.dart';

/// Selecting a day is how the rider changes it: a day still ahead offers
/// add, edit and remove; a completed one offers none of them.
void main() {
  final store = WorkoutPlanStore.instance;
  final t = stringsFor(const Locale('pt'));

  // The store is app-wide, so each test leaves the plan as it found it.
  tearDown(store.seedDemoPlan);

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

    testWidgets('a completed day offers none of them', (tester) async {
      await pumpWeek(tester);
      await selectDay(tester, '21');

      // It records a ride that happened; there is nothing to revise.
      expect(find.text(t.calendarAddWorkout), findsNothing);
      expect(find.text(t.calendarEditWorkout), findsNothing);
      expect(find.text(t.calendarRemoveWorkout), findsNothing);
      expect(find.text(t.calendarDone), findsOneWidget);
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
