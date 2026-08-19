import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/workout_builder_screen.dart';
import 'screens/workout_location_screen.dart';
import 'screens/treino_do_dia_screen.dart';
import 'screens/route_map_screen.dart';
import 'screens/route_edit_screen.dart';
import 'screens/import_result_screen.dart';
import 'screens/manual_result_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/calendar_week_screen.dart';
import 'screens/calendar_month_screen.dart';
import 'screens/web/landing_page.dart';

void main() => runApp(const TrailwattApp());

class TrailwattApp extends StatelessWidget {
  const TrailwattApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trailwatt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/splash',
      routes: {
        '/': (_) => const LandingPage(),
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/workout-builder': (_) => const WorkoutBuilderScreen(),
        '/workout-builder/map': (_) => const WorkoutLocationScreen(),
        '/home': (_) => const TreinoDoDiaScreen(),
        '/route-map': (_) => const RouteMapScreen(),
        '/route-edit': (_) => const RouteEditScreen(),
        '/import-result': (_) => const ImportResultScreen(),
        '/import-result/manual-intervals': (_) =>
            const ManualResultIntervalsScreen(),
        '/import-result/manual-continuous': (_) =>
            const ManualResultContinuousScreen(),
        '/history': (_) => const HistoricoScreen(),
        '/calendar/week': (_) => const CalendarWeekScreen(),
        '/calendar/month': (_) => const CalendarMonthScreen(),
      },
    );
  }
}
