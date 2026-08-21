import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trailwatt'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Suggest. Export. Repeat.'**
  String get splashTagline;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcome;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Trailwatt account'**
  String get authLoginSubtitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes less than a minute'**
  String get authSignupSubtitle;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authName;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'your name'**
  String get authNameHint;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
  String get authEmailHint;

  /// No description provided for @authBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get authBirthDate;

  /// No description provided for @authBirthDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get authBirthDateHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'your password'**
  String get authPasswordHint;

  /// No description provided for @authCreatePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'create a password'**
  String get authCreatePasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'repeat the password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPassword;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOr;

  /// No description provided for @authConsentPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authConsentPrefix;

  /// No description provided for @authConsentTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get authConsentTerms;

  /// No description provided for @authConsentMiddle.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get authConsentMiddle;

  /// No description provided for @authConsentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authConsentPrivacy;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weight and FTP are enough. The rest sharpens the suggestions.'**
  String get profileSubtitle;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profileWeight;

  /// No description provided for @profileFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP (watts)'**
  String get profileFtp;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @profileFootnote.
  ///
  /// In en, this message translates to:
  /// **'Weight and FTP are enough for the engine to work. Zones can stay on the generic bands or be adjusted by hand.'**
  String get profileFootnote;

  /// No description provided for @profilePowerZones.
  ///
  /// In en, this message translates to:
  /// **'POWER ZONES'**
  String get profilePowerZones;

  /// No description provided for @profilePowerZonesAnchor.
  ///
  /// In en, this message translates to:
  /// **'Anchored on FTP'**
  String get profilePowerZonesAnchor;

  /// No description provided for @profileHeartRateZones.
  ///
  /// In en, this message translates to:
  /// **'HEART RATE ZONES'**
  String get profileHeartRateZones;

  /// No description provided for @profileHeartRateZonesNote.
  ///
  /// In en, this message translates to:
  /// **'A separate table from power - the same effort falls in different zones in each.'**
  String get profileHeartRateZonesNote;

  /// No description provided for @profileAnchorOn.
  ///
  /// In en, this message translates to:
  /// **'Anchor on'**
  String get profileAnchorOn;

  /// No description provided for @profileAnchorThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold (LTHR)'**
  String get profileAnchorThreshold;

  /// No description provided for @profileAnchorMax.
  ///
  /// In en, this message translates to:
  /// **'Max HR'**
  String get profileAnchorMax;

  /// No description provided for @profileThresholdHr.
  ///
  /// In en, this message translates to:
  /// **'Threshold HR (bpm)'**
  String get profileThresholdHr;

  /// No description provided for @profileMaxHr.
  ///
  /// In en, this message translates to:
  /// **'Max HR (bpm)'**
  String get profileMaxHr;

  /// No description provided for @profileOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get profileOptional;

  /// No description provided for @profileNoHrAnchor.
  ///
  /// In en, this message translates to:
  /// **'Without this measurement the app does not calculate HR zones - and does not invent them: watts-based training keeps working.'**
  String get profileNoHrAnchor;

  /// No description provided for @scaleFive.
  ///
  /// In en, this message translates to:
  /// **'Z1-Z5'**
  String get scaleFive;

  /// No description provided for @scaleSeven.
  ///
  /// In en, this message translates to:
  /// **'Z1-Z7'**
  String get scaleSeven;

  /// No description provided for @zoneTableGeneric.
  ///
  /// In en, this message translates to:
  /// **'GENERIC'**
  String get zoneTableGeneric;

  /// No description provided for @zoneTableCustom.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get zoneTableCustom;

  /// No description provided for @zoneTableEditBounds.
  ///
  /// In en, this message translates to:
  /// **'Edit bounds'**
  String get zoneTableEditBounds;

  /// No description provided for @zoneTableRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore default'**
  String get zoneTableRestoreDefault;

  /// No description provided for @zoneTableRecalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get zoneTableRecalculate;

  /// No description provided for @zoneTableAnchorMoved.
  ///
  /// In en, this message translates to:
  /// **'The anchor changed. These bounds are the ones you typed and did not follow it.'**
  String get zoneTableAnchorMoved;

  /// No description provided for @zoneTableInvalid.
  ///
  /// In en, this message translates to:
  /// **'Each bound must be greater than the previous one. The table will not be saved while they overlap.'**
  String get zoneTableInvalid;

  /// No description provided for @zoneTableProvisional.
  ///
  /// In en, this message translates to:
  /// **'Generic bands, pending physiological review. Tap \"Edit bounds\" to use yours.'**
  String get zoneTableProvisional;

  /// No description provided for @zoneTableNeedsAnchor.
  ///
  /// In en, this message translates to:
  /// **'Set the anchor to calculate this table.'**
  String get zoneTableNeedsAnchor;

  /// No description provided for @zoneRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get zoneRecovery;

  /// No description provided for @zoneActiveRecovery.
  ///
  /// In en, this message translates to:
  /// **'Active recovery'**
  String get zoneActiveRecovery;

  /// No description provided for @zoneEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get zoneEndurance;

  /// No description provided for @zoneTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get zoneTempo;

  /// No description provided for @zoneThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get zoneThreshold;

  /// No description provided for @zoneVo2max.
  ///
  /// In en, this message translates to:
  /// **'VO2max'**
  String get zoneVo2max;

  /// No description provided for @zoneAnaerobic.
  ///
  /// In en, this message translates to:
  /// **'Anaerobic'**
  String get zoneAnaerobic;

  /// No description provided for @zoneNeuromuscular.
  ///
  /// In en, this message translates to:
  /// **'Neuromuscular'**
  String get zoneNeuromuscular;

  /// No description provided for @metricPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get metricPower;

  /// No description provided for @metricHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get metricHeartRate;

  /// No description provided for @unitWatts.
  ///
  /// In en, this message translates to:
  /// **'w'**
  String get unitWatts;

  /// No description provided for @unitBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get unitBpm;

  /// No description provided for @builderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create workout'**
  String get builderTitle;

  /// No description provided for @builderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build the workout and mark where to ride'**
  String get builderSubtitle;

  /// No description provided for @builderWatts.
  ///
  /// In en, this message translates to:
  /// **'Watts'**
  String get builderWatts;

  /// No description provided for @builderHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get builderHr;

  /// No description provided for @builderTableLabel.
  ///
  /// In en, this message translates to:
  /// **'{metric} table · Z1-Z{count}'**
  String builderTableLabel(String metric, int count);

  /// No description provided for @builderBlock.
  ///
  /// In en, this message translates to:
  /// **'BLOCK {number}'**
  String builderBlock(int number);

  /// No description provided for @builderZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get builderZone;

  /// No description provided for @builderDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get builderDuration;

  /// No description provided for @builderMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum ({unit})'**
  String builderMin(String unit);

  /// No description provided for @builderMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum ({unit})'**
  String builderMax(String unit);

  /// No description provided for @builderContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get builderContinue;

  /// No description provided for @builderFootnote.
  ///
  /// In en, this message translates to:
  /// **'The block name uses the same zone naming as the rest of the app. The workout is sovereign - the route adapts to the stimulus, not the other way round.'**
  String get builderFootnote;

  /// No description provided for @builderNoHrAnchor.
  ///
  /// In en, this message translates to:
  /// **'Set a threshold or max HR in your profile to prescribe by heart rate.'**
  String get builderNoHrAnchor;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create workout'**
  String get locationTitle;

  /// No description provided for @locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continued - where to ride'**
  String get locationSubtitle;

  /// No description provided for @locationWhere.
  ///
  /// In en, this message translates to:
  /// **'WHERE TO RIDE'**
  String get locationWhere;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the pin or tap the map · {radius} km radius'**
  String locationHint(int radius);

  /// No description provided for @locationGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate route suggestions'**
  String get locationGenerate;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout'**
  String get todayTitle;

  /// No description provided for @todaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'4x8min at 180w'**
  String get todaySubtitle;

  /// No description provided for @todayTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get todayTarget;

  /// No description provided for @todayGradient.
  ///
  /// In en, this message translates to:
  /// **'GRADIENT'**
  String get todayGradient;

  /// No description provided for @todaySegment.
  ///
  /// In en, this message translates to:
  /// **'SEGMENT'**
  String get todaySegment;

  /// No description provided for @routeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Segment suggested for today\'s workout'**
  String get routeSubtitle;

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get routeDistance;

  /// No description provided for @routeGradientLabel.
  ///
  /// In en, this message translates to:
  /// **'GRADIENT'**
  String get routeGradientLabel;

  /// No description provided for @routeMatch.
  ///
  /// In en, this message translates to:
  /// **'MATCH'**
  String get routeMatch;

  /// No description provided for @routeEditManually.
  ///
  /// In en, this message translates to:
  /// **'Edit route manually'**
  String get routeEditManually;

  /// No description provided for @routeExportTo.
  ///
  /// In en, this message translates to:
  /// **'EXPORT TO'**
  String get routeExportTo;

  /// No description provided for @routeExport.
  ///
  /// In en, this message translates to:
  /// **'Export route'**
  String get routeExport;

  /// No description provided for @routeExported.
  ///
  /// In en, this message translates to:
  /// **'Route exported to {platform}'**
  String routeExported(String platform);

  /// No description provided for @routeFootnote.
  ///
  /// In en, this message translates to:
  /// **'The segment colour follows the effort zone (Z1 to Z5, watts or HR) predicted for that point of the climb - not just \"inside or outside the target\".'**
  String get routeFootnote;

  /// No description provided for @routeDegraded.
  ///
  /// In en, this message translates to:
  /// **'Segment not verified against the road network.'**
  String get routeDegraded;

  /// No description provided for @routeSavedRescored.
  ///
  /// In en, this message translates to:
  /// **'Route re-scored and saved'**
  String get routeSavedRescored;

  /// No description provided for @editRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get editRouteTitle;

  /// No description provided for @editRouteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The workout segment inside the full ride'**
  String get editRouteSubtitle;

  /// No description provided for @editRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the points to edit. On release the point snaps to the nearest road and the route is redrawn along the streets.'**
  String get editRouteHint;

  /// No description provided for @editRouteTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL RIDE'**
  String get editRouteTotal;

  /// No description provided for @editRouteSegment.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT SEGMENT'**
  String get editRouteSegment;

  /// No description provided for @editRouteImpact.
  ///
  /// In en, this message translates to:
  /// **'Edit impact'**
  String get editRouteImpact;

  /// No description provided for @editRouteDeviation.
  ///
  /// In en, this message translates to:
  /// **'Deviation'**
  String get editRouteDeviation;

  /// No description provided for @editRouteSnap.
  ///
  /// In en, this message translates to:
  /// **'Road snap'**
  String get editRouteSnap;

  /// No description provided for @editRouteSnapMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m to the road'**
  String editRouteSnapMeters(int meters);

  /// No description provided for @editRouteSnapUnverified.
  ///
  /// In en, this message translates to:
  /// **'not verified'**
  String get editRouteSnapUnverified;

  /// No description provided for @editRoutePredictedMatch.
  ///
  /// In en, this message translates to:
  /// **'Predicted match'**
  String get editRoutePredictedMatch;

  /// No description provided for @editRouteNeedsRoads.
  ///
  /// In en, this message translates to:
  /// **'requires the road network'**
  String get editRouteNeedsRoads;

  /// No description provided for @editRouteImpactNote.
  ///
  /// In en, this message translates to:
  /// **'The app does not save a material change without re-scoring the match.'**
  String get editRouteImpactNote;

  /// No description provided for @editRouteSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editRouteSave;

  /// No description provided for @editRouteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editRouteCancel;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout result'**
  String get importTitle;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetched automatically via API'**
  String get importSubtitle;

  /// No description provided for @importConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED TO STRAVA'**
  String get importConnectedTo;

  /// No description provided for @importActivityFound.
  ///
  /// In en, this message translates to:
  /// **'Activity found'**
  String get importActivityFound;

  /// No description provided for @importActivityWhen.
  ///
  /// In en, this message translates to:
  /// **'Subida da Serra · today, 07:14'**
  String get importActivityWhen;

  /// No description provided for @importAvgPower.
  ///
  /// In en, this message translates to:
  /// **'AVG POWER'**
  String get importAvgPower;

  /// No description provided for @importAvgHr.
  ///
  /// In en, this message translates to:
  /// **'AVG HR'**
  String get importAvgHr;

  /// No description provided for @importDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get importDuration;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get importConfirm;

  /// No description provided for @importNoApi.
  ///
  /// In en, this message translates to:
  /// **'NO API CONNECTION?'**
  String get importNoApi;

  /// No description provided for @importManualPower.
  ///
  /// In en, this message translates to:
  /// **'Average power (w)'**
  String get importManualPower;

  /// No description provided for @importManualHint.
  ///
  /// In en, this message translates to:
  /// **'enter manually'**
  String get importManualHint;

  /// No description provided for @importManualHelp.
  ///
  /// In en, this message translates to:
  /// **'Less accurate - use only if the automatic import fails.'**
  String get importManualHelp;

  /// No description provided for @importManualLink.
  ///
  /// In en, this message translates to:
  /// **'Fill in manually per stimulus'**
  String get importManualLink;

  /// No description provided for @importFootnote.
  ///
  /// In en, this message translates to:
  /// **'The API finds the matching activity automatically. Manual entry only appears as a last resort, and stays visually secondary.'**
  String get importFootnote;

  /// No description provided for @manualIntervalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual entry · interval workout'**
  String get manualIntervalsSubtitle;

  /// No description provided for @manualContinuousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual entry · continuous workout'**
  String get manualContinuousSubtitle;

  /// No description provided for @manualStimulus.
  ///
  /// In en, this message translates to:
  /// **'STIMULUS {number} · {duration}'**
  String manualStimulus(int number, String duration);

  /// No description provided for @manualEnduranceRide.
  ///
  /// In en, this message translates to:
  /// **'ENDURANCE RIDE · 60 MIN'**
  String get manualEnduranceRide;

  /// No description provided for @manualTarget.
  ///
  /// In en, this message translates to:
  /// **'target {watts}w'**
  String manualTarget(int watts);

  /// No description provided for @manualAvgWatts.
  ///
  /// In en, this message translates to:
  /// **'avg watts'**
  String get manualAvgWatts;

  /// No description provided for @manualSave.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get manualSave;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get historyTitle;

  /// No description provided for @historyCurrentFtp.
  ///
  /// In en, this message translates to:
  /// **'CURRENT FTP'**
  String get historyCurrentFtp;

  /// No description provided for @historyAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get historyAccuracy;

  /// No description provided for @historyRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent workouts'**
  String get historyRecent;

  /// No description provided for @historyTargetWatts.
  ///
  /// In en, this message translates to:
  /// **'target {watts}w'**
  String historyTargetWatts(int watts);

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeek;

  /// No description provided for @calendarMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonth;

  /// No description provided for @calendarRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day - no workout planned.'**
  String get calendarRestDay;

  /// No description provided for @calendarDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get calendarDone;

  /// No description provided for @calendarVia.
  ///
  /// In en, this message translates to:
  /// **'via {source}'**
  String calendarVia(String source);

  /// No description provided for @calendarActual.
  ///
  /// In en, this message translates to:
  /// **'ACTUAL'**
  String get calendarActual;

  /// No description provided for @calendarPlanned.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get calendarPlanned;

  /// No description provided for @calendarDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get calendarDuration;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get navComingSoon;

  /// No description provided for @sourceStrava.
  ///
  /// In en, this message translates to:
  /// **'Strava'**
  String get sourceStrava;

  /// No description provided for @sourceGarmin.
  ///
  /// In en, this message translates to:
  /// **'Garmin'**
  String get sourceGarmin;

  /// No description provided for @sourceWahoo.
  ///
  /// In en, this message translates to:
  /// **'Wahoo'**
  String get sourceWahoo;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'manual entry'**
  String get sourceManual;

  /// No description provided for @landingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FOR CYCLISTS, FROM BEGINNER TO PRO'**
  String get landingEyebrow;

  /// No description provided for @landingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your workout already tells you the ideal route.'**
  String get landingHeadline;

  /// No description provided for @landingSubhead.
  ///
  /// In en, this message translates to:
  /// **'Enter today\'s workout target and Trailwatt suggests a real route that matches it.'**
  String get landingSubhead;

  /// No description provided for @landingStartFree.
  ///
  /// In en, this message translates to:
  /// **'Start free'**
  String get landingStartFree;

  /// No description provided for @landingHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'See how it works'**
  String get landingHowItWorks;

  /// No description provided for @landingFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Target by power or HR'**
  String get landingFeature1Title;

  /// No description provided for @landingFeature1Body.
  ///
  /// In en, this message translates to:
  /// **'From a 150w FTP to a 300w one, the engine works out the right gradient for your level.'**
  String get landingFeature1Body;

  /// No description provided for @landingFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'100% local calculation'**
  String get landingFeature2Title;

  /// No description provided for @landingFeature2Body.
  ///
  /// In en, this message translates to:
  /// **'The physics engine runs on the device itself. It works even with no internet.'**
  String get landingFeature2Body;

  /// No description provided for @landingFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Exports and imports on its own'**
  String get landingFeature3Title;

  /// No description provided for @landingFeature3Body.
  ///
  /// In en, this message translates to:
  /// **'Sends the finished route to Strava, Garmin or Wahoo, and fetches the result back.'**
  String get landingFeature3Body;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @routingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Routing service unavailable - straight-line distance.'**
  String get routingUnavailable;

  /// No description provided for @routingNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route found on the road network between these points.'**
  String get routingNoRoute;

  /// No description provided for @routingNeedsTwoPoints.
  ///
  /// In en, this message translates to:
  /// **'Mark at least two points to trace the route.'**
  String get routingNeedsTwoPoints;

  /// No description provided for @importPowerCurveSnack.
  ///
  /// In en, this message translates to:
  /// **'Optional connection - fills the curve via API'**
  String get importPowerCurveSnack;

  /// No description provided for @builderAddBlock.
  ///
  /// In en, this message translates to:
  /// **'+ Add block'**
  String get builderAddBlock;

  /// No description provided for @calendarWorkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'{blocks, plural, =1{1 block} other{{blocks} blocks}} · {minutes} min'**
  String calendarWorkoutSummary(int blocks, int minutes);

  /// No description provided for @builderRoleWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get builderRoleWarmUp;

  /// No description provided for @builderRoleWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get builderRoleWork;

  /// No description provided for @builderRoleRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get builderRoleRecovery;

  /// No description provided for @builderRoleCoolDown.
  ///
  /// In en, this message translates to:
  /// **'Cool-down'**
  String get builderRoleCoolDown;

  /// No description provided for @builderRole.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get builderRole;

  /// No description provided for @builderDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get builderDuplicate;

  /// No description provided for @builderRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get builderRemove;

  /// No description provided for @builderTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total: {minutes} min'**
  String builderTotalDuration(int minutes);

  /// No description provided for @builderSequenceNote.
  ///
  /// In en, this message translates to:
  /// **'A block can hold two or more stimuli: to build 4x8min Z4 with 2min easy, add a Z4 stimulus, tap \"+ Stimulus\" to add the Z1, and set how many times to repeat.'**
  String get builderSequenceNote;

  /// No description provided for @sourceTrainingPeaks.
  ///
  /// In en, this message translates to:
  /// **'TrainingPeaks'**
  String get sourceTrainingPeaks;

  /// No description provided for @builderAddStimulus.
  ///
  /// In en, this message translates to:
  /// **'+ Stimulus'**
  String get builderAddStimulus;

  /// No description provided for @builderStimulus.
  ///
  /// In en, this message translates to:
  /// **'Stimulus {number}'**
  String builderStimulus(int number);

  /// No description provided for @builderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat (x)'**
  String get builderRepeat;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, integrations and more'**
  String get moreSubtitle;

  /// No description provided for @moreProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get moreProfile;

  /// No description provided for @moreProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weight, FTP and zones'**
  String get moreProfileSubtitle;

  /// No description provided for @moreIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get moreIntegrations;

  /// No description provided for @moreIntegrationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Strava, Garmin, Wahoo and TrainingPeaks'**
  String get moreIntegrationsSubtitle;

  /// No description provided for @integrationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsTitle;

  /// No description provided for @integrationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Strava, Garmin and Wahoo to export routes and pick the result back up, and TrainingPeaks to import your planned workout.'**
  String get integrationsSubtitle;

  /// No description provided for @integrationsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get integrationsConnected;

  /// No description provided for @integrationsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get integrationsNotConnected;

  /// No description provided for @integrationsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get integrationsConnect;

  /// No description provided for @integrationsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get integrationsDisconnect;

  /// No description provided for @integrationsScopeNote.
  ///
  /// In en, this message translates to:
  /// **'The connection only reads the matching activity or planned workout - never a bulk import of your history (Article II).'**
  String get integrationsScopeNote;

  /// No description provided for @importWorkoutFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Import from TrainingPeaks'**
  String get importWorkoutFabLabel;

  /// No description provided for @importWorkoutSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Workout imported from TrainingPeaks'**
  String get importWorkoutSuccessSnack;

  /// No description provided for @importWorkoutNoConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No TrainingPeaks connection'**
  String get importWorkoutNoConnectionTitle;

  /// No description provided for @importWorkoutNoConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your account to import your preferred workout automatically, or keep building it manually.'**
  String get importWorkoutNoConnectionBody;

  /// No description provided for @importWorkoutConnectCta.
  ///
  /// In en, this message translates to:
  /// **'Connect now'**
  String get importWorkoutConnectCta;

  /// No description provided for @importWorkoutManualCta.
  ///
  /// In en, this message translates to:
  /// **'Create manually'**
  String get importWorkoutManualCta;

  /// No description provided for @integrationsExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get integrationsExpired;

  /// No description provided for @integrationsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not available in this build'**
  String get integrationsNotConfigured;

  /// No description provided for @integrationsReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get integrationsReconnect;

  /// No description provided for @integrationsNotConfiguredNote.
  ///
  /// In en, this message translates to:
  /// **'This build carries no API client id for the platform, so it cannot connect. Supply one at build time with --dart-define.'**
  String get integrationsNotConfiguredNote;

  /// No description provided for @integrationsScopes.
  ///
  /// In en, this message translates to:
  /// **'Permissions: {scopes}'**
  String integrationsScopes(String scopes);

  /// No description provided for @integrationsConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect {platform}'**
  String integrationsConnectTitle(String platform);

  /// No description provided for @integrationsConnectStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open this address and approve the access:'**
  String get integrationsConnectStep1;

  /// No description provided for @integrationsConnectStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Paste the address you were redirected to:'**
  String get integrationsConnectStep2;

  /// No description provided for @integrationsRedirectLabel.
  ///
  /// In en, this message translates to:
  /// **'Redirect URL'**
  String get integrationsRedirectLabel;

  /// No description provided for @integrationsConnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Finish connecting'**
  String get integrationsConnectConfirm;

  /// No description provided for @integrationsConnectedSnack.
  ///
  /// In en, this message translates to:
  /// **'{platform} connected'**
  String integrationsConnectedSnack(String platform);

  /// No description provided for @integrationsCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get integrationsCopyUrl;

  /// No description provided for @integrationsUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get integrationsUrlCopied;

  /// No description provided for @integrationsErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build cannot connect to that platform.'**
  String get integrationsErrorNotConfigured;

  /// No description provided for @integrationsErrorDenied.
  ///
  /// In en, this message translates to:
  /// **'Access was not granted on the platform.'**
  String get integrationsErrorDenied;

  /// No description provided for @integrationsErrorStateMismatch.
  ///
  /// In en, this message translates to:
  /// **'That redirect does not match the connection we started. Try connecting again.'**
  String get integrationsErrorStateMismatch;

  /// No description provided for @integrationsErrorNoCode.
  ///
  /// In en, this message translates to:
  /// **'The redirect carried no authorization code.'**
  String get integrationsErrorNoCode;

  /// No description provided for @integrationsErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the platform. Check your connection and try again.'**
  String get integrationsErrorNetwork;

  /// No description provided for @integrationsErrorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The platform answered with something unexpected.'**
  String get integrationsErrorInvalidResponse;

  /// No description provided for @routeExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get routeExporting;

  /// No description provided for @routeExportNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect {platform} under More › Integrations first.'**
  String routeExportNotConnected(String platform);

  /// No description provided for @routeExportNotSupported.
  ///
  /// In en, this message translates to:
  /// **'{platform} has no route API - export the file instead.'**
  String routeExportNotSupported(String platform);

  /// No description provided for @routeExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export to {platform}.'**
  String routeExportFailed(String platform);

  /// No description provided for @routeHandoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Import into {platform}'**
  String routeHandoffTitle(String platform);

  /// No description provided for @routeHandoffBody.
  ///
  /// In en, this message translates to:
  /// **'{platform} has no official endpoint for creating a route, so the app does not invent one. Here is the GPX - import it through {platform}\'s own route importer.'**
  String routeHandoffBody(String platform);

  /// No description provided for @routeHandoffCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy GPX'**
  String get routeHandoffCopy;

  /// No description provided for @routeHandoffCopied.
  ///
  /// In en, this message translates to:
  /// **'GPX copied'**
  String get routeHandoffCopied;

  /// No description provided for @importWorkoutNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'No structured workout planned in TrainingPeaks for the week ahead.'**
  String get importWorkoutNothingPlanned;

  /// No description provided for @importWorkoutReconnect.
  ///
  /// In en, this message translates to:
  /// **'Your TrainingPeaks session ended. Connect it again under More › Integrations.'**
  String get importWorkoutReconnect;

  /// No description provided for @importWorkoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the planned workout from TrainingPeaks.'**
  String get importWorkoutFailed;

  /// No description provided for @calendarAddWorkout.
  ///
  /// In en, this message translates to:
  /// **'+ Schedule a workout'**
  String get calendarAddWorkout;

  /// No description provided for @calendarEditWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get calendarEditWorkout;

  /// No description provided for @calendarRemoveWorkout.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get calendarRemoveWorkout;

  /// No description provided for @calendarRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this workout?'**
  String get calendarRemoveTitle;

  /// No description provided for @calendarRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The day goes back to being a rest day. Nothing else in the plan changes.'**
  String get calendarRemoveBody;

  /// No description provided for @calendarWorkoutRemoved.
  ///
  /// In en, this message translates to:
  /// **'Workout removed from the day'**
  String get calendarWorkoutRemoved;

  /// No description provided for @calendarWorkoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved to the day'**
  String get calendarWorkoutSaved;

  /// No description provided for @builderSaveToDay.
  ///
  /// In en, this message translates to:
  /// **'Save to this day'**
  String get builderSaveToDay;

  /// No description provided for @calendarPlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get calendarPlannedWorkout;

  /// No description provided for @calendarLinkActivity.
  ///
  /// In en, this message translates to:
  /// **'Link a ride'**
  String get calendarLinkActivity;

  /// No description provided for @calendarUnlinkActivity.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get calendarUnlinkActivity;

  /// No description provided for @calendarLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Which ride was this workout?'**
  String get calendarLinkTitle;

  /// No description provided for @calendarLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Only rides not already recorded as another day\'s result are listed. Nothing is linked until you pick one.'**
  String get calendarLinkBody;

  /// No description provided for @calendarActivityLinked.
  ///
  /// In en, this message translates to:
  /// **'{activity} recorded as this day\'s result'**
  String calendarActivityLinked(String activity);

  /// No description provided for @calendarUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink this ride?'**
  String get calendarUnlinkTitle;

  /// No description provided for @calendarUnlinkBody.
  ///
  /// In en, this message translates to:
  /// **'The ride stays in your history - it just stops being this day\'s result, and the day goes back to being planned.'**
  String get calendarUnlinkBody;

  /// No description provided for @calendarActivityUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Ride unlinked from the day'**
  String get calendarActivityUnlinked;

  /// No description provided for @historyLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'result of {day}'**
  String historyLinkedTo(String day);

  /// No description provided for @historyNotLinked.
  ///
  /// In en, this message translates to:
  /// **'not linked to a workout'**
  String get historyNotLinked;

  /// No description provided for @profileRiderSection.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get profileRiderSection;

  /// No description provided for @profileScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get profileScaleLabel;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get profileLanguage;

  /// No description provided for @profileLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to this session. \"System\" follows your device or browser.'**
  String get profileLanguageNote;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @zoneTableColumnZone.
  ///
  /// In en, this message translates to:
  /// **'ZONE'**
  String get zoneTableColumnZone;

  /// No description provided for @zoneTableColumnFrom.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get zoneTableColumnFrom;

  /// No description provided for @zoneTableColumnTo.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get zoneTableColumnTo;

  /// Back link to the screen that opened this one.
  ///
  /// In en, this message translates to:
  /// **'‹ {destination}'**
  String backTo(String destination);

  /// No description provided for @backGeneric.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backGeneric;

  /// No description provided for @historyImportResult.
  ///
  /// In en, this message translates to:
  /// **'Import result'**
  String get historyImportResult;

  /// No description provided for @manualSwitchToContinuous.
  ///
  /// In en, this message translates to:
  /// **'It was a continuous ride'**
  String get manualSwitchToContinuous;

  /// No description provided for @manualSwitchToIntervals.
  ///
  /// In en, this message translates to:
  /// **'It was an interval workout'**
  String get manualSwitchToIntervals;

  /// No description provided for @builderBlockNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block name'**
  String get builderBlockNameLabel;

  /// No description provided for @builderMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get builderMoveUp;

  /// No description provided for @builderMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get builderMoveDown;

  /// No description provided for @builderInsertHere.
  ///
  /// In en, this message translates to:
  /// **'+ Insert block here'**
  String get builderInsertHere;

  /// No description provided for @locationSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Where you want to start'**
  String get locationSearchLabel;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Address, neighbourhood or place'**
  String get locationSearchHint;

  /// No description provided for @locationSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found by that name'**
  String get locationSearchEmpty;

  /// No description provided for @locationSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'The search did not answer. Try again.'**
  String get locationSearchFailed;

  /// No description provided for @locationSearchBusy.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get locationSearchBusy;

  /// No description provided for @locationStartAt.
  ///
  /// In en, this message translates to:
  /// **'Start: {place}'**
  String locationStartAt(String place);

  /// No description provided for @locationStartOnMap.
  ///
  /// In en, this message translates to:
  /// **'Start placed on the map'**
  String get locationStartOnMap;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
