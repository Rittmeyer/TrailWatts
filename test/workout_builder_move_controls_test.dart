import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/theme/app_colors.dart';

import 'l10n_harness.dart';

/// The move arrows have failed twice for reasons that had nothing to do
/// with moving: too small to hit, then painted in the divider colour so a
/// disabled one was invisible. Both are properties of the rendered control,
/// so both are asserted here.
void main() {
  final t = stringsFor(const Locale('pt'));

  /// The button itself, not the Tooltip inside it: IconButton wraps only
  /// the icon in the tooltip, so finding by tooltip and measuring gives the
  /// 18px glyph rather than the target a finger has to hit.
  Finder moveButton(String tooltip) =>
      find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tooltip);

  Future<void> pumpBuilder(WidgetTester tester) async {
    await tester.pumpWidget(localized(const WorkoutBuilderScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('a move arrow is big enough to hit', (tester) async {
    await pumpBuilder(tester);

    for (final tooltip in [t.builderMoveUp, t.builderMoveDown]) {
      final size = tester.getSize(moveButton(tooltip).first);
      expect(size.width, greaterThanOrEqualTo(44.0), reason: tooltip);
      expect(size.height, greaterThanOrEqualTo(44.0), reason: tooltip);
    }
  });

  testWidgets('a disabled arrow is visible, just inactive', (tester) async {
    await pumpBuilder(tester);

    // One block, so neither arrow can move anything and both are disabled -
    // the state the rider sees first.
    final down = tester.widget<IconButton>(moveButton(t.builderMoveDown).first);
    expect(down.onPressed, isNull, reason: 'a lone block cannot move down');

    final icon = tester.widget<Icon>(find.descendant(
        of: moveButton(t.builderMoveDown).first, matching: find.byType(Icon)));
    final rendered = icon.color ?? down.disabledColor;

    expect(rendered, isNot(AppColors.line),
        reason: 'the divider colour is invisible against the card');
    expect(rendered, AppColors.inkDisabled);
  });
}
