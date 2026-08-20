import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/rider_profile.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/widgets/zone_table_editor.dart';

import '../l10n_harness.dart';

/// Hosts the editor with a mutable anchor, the way the profile screen does.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int ftp = 210;
  List<int>? bounds;

  static const _settings = PowerZoneSettings(scale: ZoneScale.seven);

  void setFtp(int v) => setState(() => ftp = v);

  @override
  Widget build(BuildContext context) {
    return localized(
      Scaffold(
        body: SingleChildScrollView(
          child: ZoneTableEditor(
            table: ZoneTables.of(ZoneMetric.power, ZoneScale.seven),
            bounds: bounds,
            derivedBounds: _settings.derivedBounds(ftp),
            unit: 'w',
            onChanged: (b) => setState(() => bounds = b),
          ),
        ),
      ),
    );
  }
}

final _t = stringsFor(const Locale('pt'));

void main() {
  testWidgets('the generic table follows the anchor as it changes',
      (tester) async {
    await tester.pumpWidget(const _Host());

    // 56% of 210 = 118
    expect(find.text('118'), findsOneWidget);

    tester.state<_HostState>(find.byType(_Host)).setFtp(300);
    await tester.pump();

    // 56% of 300 = 168; the old value must be gone, not merely joined.
    expect(find.text('168'), findsOneWidget);
    expect(find.text('118'), findsNothing);
  });

  testWidgets('switching to custom seeds from the generic values',
      (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.text(_t.zoneTableEditBounds));
    await tester.pump();

    expect(find.text(_t.zoneTableCustom), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
  });

  testWidgets(
      'a custom table keeps the rider values when the anchor moves, '
      'and offers to recalculate', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text(_t.zoneTableEditBounds));
    await tester.pump();

    tester.state<_HostState>(find.byType(_Host)).setFtp(300);
    await tester.pump();

    // The rider's numbers are untouched...
    expect(find.text('118'), findsOneWidget);
    expect(find.text('168'), findsNothing);
    // ...but the drift is surfaced rather than left silent.
    expect(find.text(_t.zoneTableRecalculate), findsOneWidget);

    await tester.tap(find.text(_t.zoneTableRecalculate));
    await tester.pump();

    expect(find.text('168'), findsOneWidget);
    expect(find.text('118'), findsNothing);
    expect(find.text(_t.zoneTableRecalculate), findsNothing);
  });

  testWidgets('restoring the default drops back to the generic table',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text(_t.zoneTableEditBounds));
    await tester.pump();
    expect(find.text(_t.zoneTableCustom), findsOneWidget);

    await tester.tap(find.text(_t.zoneTableRestoreDefault));
    await tester.pump();

    expect(find.text(_t.zoneTableGeneric), findsOneWidget);
  });

  testWidgets('editing a bound updates the neighbouring upper bound',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text(_t.zoneTableEditBounds));
    await tester.pump();

    // Z2 starts at 118, so Z1 is shown ending at 117.
    expect(find.textContaining('117'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, '118'), '130');
    await tester.pump();

    // Z1's upper bound tracks the field being typed into.
    expect(find.textContaining('129'), findsWidgets);
  });

  testWidgets('typing keeps focus and the caret', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text(_t.zoneTableEditBounds));
    await tester.pump();

    final field = find.widgetWithText(TextField, '118');
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, '125');
    await tester.pump();

    final widget =
        tester.widget<TextField>(find.widgetWithText(TextField, '125'));
    expect(widget.controller!.text, '125');
    // A rebuilt controller would reset the selection to the start.
    expect(widget.controller!.selection.baseOffset, greaterThan(0));
  });
}
