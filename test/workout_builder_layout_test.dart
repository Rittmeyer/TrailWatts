import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';

import 'l10n_harness.dart';

/// The builder packs three-column rows of fields into whatever width it is
/// given. A row that overflows draws stripes in debug and silently clips in
/// release, so the narrow widths are worth pumping on purpose.
void main() {
  final widths = [320.0, 360.0, 400.0, 420.0, 480.0, 600.0];

  for (final width in widths) {
    testWidgets('nothing overflows at ${width.toInt()}px wide', (tester) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(localized(const WorkoutBuilderScreen()));
      await tester.pumpAndSettle();

      // An overflow is reported as a thrown exception during layout, which
      // the framework hands to us here rather than failing on its own.
      expect(tester.takeException(), isNull,
          reason: 'a row does not fit at ${width}px');
    });
  }
}
