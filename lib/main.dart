import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'services/integrations_store.dart';
import 'services/locale_store.dart';
import 'services/route_suggestion_store.dart';
import 'services/platform/platform_oauth_service.dart';
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
import 'screens/more_screen.dart';
import 'screens/integrations_screen.dart';
import 'screens/web/landing_page.dart';

void main() {
  // DateFormat needs the symbol data for whatever locale the device is in
  // before any date is formatted; flutter_localizations does not cover it.
  initializeDateFormatting();
  runApp(const TrailwattApp());
}

class TrailwattApp extends StatefulWidget {
  const TrailwattApp({super.key});

  @override
  State<TrailwattApp> createState() => _TrailwattAppState();
}

class _TrailwattAppState extends State<TrailwattApp> {
  @override
  void initState() {
    super.initState();
    _captureLaunchRedirect();
    // Terrain a previous run downloaded is read back now rather than in the
    // middle of the first search.
    RouteSuggestionStore.instance.warmUp();
  }

  /// An OAuth redirect can be how the app was launched: on the web the
  /// platform sends the browser back to this page with the code in the URL,
  /// which reloads the app. Reading it here is what turns "copy the address
  /// and paste it back" into a connection that just completes.
  ///
  /// Anything that is not a redirect the app is waiting for is left alone -
  /// a URL carrying a state nobody issued is not ours to act on.
  Future<void> _captureLaunchRedirect() async {
    final store = IntegrationsStore.instance;
    final launch = Uri.base;
    if (!store.awaitsRedirect(launch)) return;
    try {
      await store.completeFromRedirect(launch);
    } on PlatformAuthException {
      // The integrations screen shows the connection never happened; there
      // is no screen yet at launch to put a message on.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the rider picks a language in the profile; with no
    // choice made, locale stays null and the device decides as before.
    return ListenableBuilder(
      listenable: LocaleStore.instance,
      builder: (context, _) => MaterialApp(
        locale: LocaleStore.instance.locale,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Follows the device locale, falling back to English for anything we
        // do not translate yet.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // On web the browser reports '/', which would otherwise be overridden
        // by initialRoute and leave the landing page unreachable; a browser
        // visitor gets the marketing page, the app gets the splash.
        initialRoute: kIsWeb ? '/' : '/splash',
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
          '/more': (_) => const MoreScreen(),
          '/integrations': (_) => const IntegrationsScreen(),
        },
      ),
    );
  }
}
