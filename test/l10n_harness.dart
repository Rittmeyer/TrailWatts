import 'package:flutter/material.dart';
import 'package:trailwatt/l10n/app_localizations.dart';

/// Wraps a screen with the localization delegates, in a chosen locale, so
/// tests can assert on what a rider in that language actually sees.
Widget localized(Widget child, {Locale locale = const Locale('pt')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// The strings for a locale, for tests that need the expected text without
/// hardcoding a translation that may legitimately be reworded.
AppLocalizations stringsFor(Locale locale) => lookupAppLocalizations(locale);
