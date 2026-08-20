import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/workout_plan_store.dart';

import 'l10n_harness.dart';

/// Editing the sequence of blocks, not just appending to it.
///
/// The builder could only add a block at the end, and the order it produced
/// was the order they happened to be typed in. The order of the blocks IS
/// the workout's timeline, so a warm-up thought of second could not be put
/// first without deleting and retyping everything after it.
void main() {
  final t = stringsFor(const Locale('pt'));
  final plan = WorkoutPlanStore.instance;

  tearDown(plan.seedDemoPlan);

  Future<void> pumpBuilder(WidgetTester tester, {DateTime? day}) async {
    await tester
        .pumpWidget(localized(const WorkoutBuilderScreen(), arguments: day));
    await tester.pump();
  }

  /// The block name fields, top to bottom. Each block's field hints at its
  /// own position, which is what identifies it.
  Finder nameField(int index) => find.byWidgetPredicate((w) =>
      w is TextField && w.decoration?.hintText == t.builderBlock(index + 1));

  List<String> names(WidgetTester tester) {
    final out = <String>[];
    for (var i = 0;; i++) {
      final found = nameField(i).evaluate();
      if (found.isEmpty) return out;
      out.add((found.single.widget as TextField).controller?.text ?? '');
    }
  }

  /// The form is taller than the test viewport, so a tap on an off-screen
  /// control silently lands on nothing.
  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> addBlock(WidgetTester tester) async =>
      tapVisible(tester, find.text(t.builderAddBlock));

  Future<void> name(WidgetTester tester, int index, String value) async {
    await tester.enterText(nameField(index), value);
    await tester.pump();
  }

  group('adding a block anywhere in the sequence', () {
    testWidgets('before the first one', (tester) async {
      await pumpBuilder(tester);
      await name(tester, 0, 'principal');

      // The first insertion point sits above the first card.
      await tapVisible(tester, find.text(t.builderInsertHere).first);

      expect(names(tester), ['', 'principal'],
          reason: 'the new block should land above, not below');
    });

    testWidgets('between two others', (tester) async {
      await pumpBuilder(tester);
      await name(tester, 0, 'primeiro');
      await addBlock(tester);
      await name(tester, 1, 'segundo');
      expect(names(tester), ['primeiro', 'segundo']);

      // Insertion points sit above each card, so the second one is the gap
      // between the two blocks.
      await tapVisible(tester, find.text(t.builderInsertHere).at(1));

      expect(names(tester), ['primeiro', '', 'segundo']);
    });
  });

  group('moving a block', () {
    testWidgets('down, then back up, restores the order', (tester) async {
      await pumpBuilder(tester);
      await name(tester, 0, 'a');
      await addBlock(tester);
      await name(tester, 1, 'b');

      await tapVisible(tester, find.byTooltip(t.builderMoveDown).first);
      expect(names(tester), ['b', 'a']);

      await tapVisible(tester, find.byTooltip(t.builderMoveUp).last);
      expect(names(tester), ['a', 'b']);
    });

    testWidgets('the ends offer no move that would do nothing', (tester) async {
      await pumpBuilder(tester);
      await addBlock(tester);

      final ups = tester
          .widgetList<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_upward))
          .toList();
      final downs = tester
          .widgetList<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_downward))
          .toList();

      expect(ups.first.onPressed, isNull, reason: 'the top block has no up');
      expect(ups.last.onPressed, isNotNull);
      expect(downs.first.onPressed, isNotNull);
      expect(downs.last.onPressed, isNull,
          reason: 'the bottom block has no down');
    });
  });

  group('naming a block', () {
    testWidgets('an unnamed block falls back to its position', (tester) async {
      await pumpBuilder(tester);
      expect(nameField(0), findsOneWidget);
      expect(names(tester), ['']);
    });

    testWidgets('the name survives saving and reopening the day',
        (tester) async {
      final day = DateTime(2026, 7, 22);
      plan.removePlanned(day);

      await pumpBuilder(tester, day: day);
      await name(tester, 0, 'Série principal');
      await tapVisible(tester, find.text(t.builderSaveToDay));

      // Written onto every block the group expands to, because the plan
      // stores the flattened sequence.
      final saved = plan.entryFor(day)!.planned;
      expect(saved, isNotEmpty);
      expect(saved.map((b) => b.name), everyElement('Série principal'));

      await pumpBuilder(tester, day: day);
      expect(names(tester).first, 'Série principal');
    });

    testWidgets('a blank name is no name, not an empty one', (tester) async {
      final day = DateTime(2026, 7, 22);
      plan.removePlanned(day);

      await pumpBuilder(tester, day: day);
      await name(tester, 0, '   ');
      await tapVisible(tester, find.text(t.builderSaveToDay));

      expect(
          plan.entryFor(day)!.planned.map((b) => b.name), everyElement(isNull));
    });
  });
}
