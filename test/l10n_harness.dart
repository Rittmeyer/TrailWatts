import 'package:flutter/material.dart';
import 'package:trailwatt/l10n/app_localizations.dart';

/// Wraps a screen with the localization delegates, in a chosen locale, so
/// tests can assert on what a rider in that language actually sees.
Widget localized(
  Widget child, {
  Locale locale = const Locale('pt'),
  Map<String, WidgetBuilder> routes = const {},
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Screens that navigate on save need their destination to exist, or the
    // tap throws instead of exercising what it was meant to.
    routes: routes,
    home: child,
  );
}

/// The strings for a locale, for tests that need the expected text without
/// hardcoding a translation that may legitimately be reworded.
AppLocalizations stringsFor(Locale locale) => lookupAppLocalizations(locale);
