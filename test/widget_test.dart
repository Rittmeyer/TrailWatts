import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/main.dart';
import 'package:trailwatt/screens/calendar_week_screen.dart';
import 'package:trailwatt/screens/historico_screen.dart';
import 'package:trailwatt/screens/profile_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';

void main() {
  testWidgets('boots on the splash screen and moves on to auth',
      (tester) async {
    await tester.pumpWidget(const TrailwattApp());

    expect(find.text('TRAILWATT'), findsOneWidget);

    // The splash hands over after ~1.1s. Pump past it rather than settling:
    // the splash spinner animates forever and would never settle.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Criar conta'), findsWidgets);
  });

  group('screens build without throwing', () {
    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    testWidgets('profile, with both zone tables', (tester) async {
      await pumpScreen(tester, const ProfileScreen());
      expect(find.text('ZONAS DE POTENCIA'), findsOneWidget);
      expect(find.text('ZONAS DE FREQUENCIA CARDIACA'), findsOneWidget);
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
}
