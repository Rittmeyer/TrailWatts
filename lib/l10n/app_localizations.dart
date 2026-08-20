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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
  /// **'Create profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weight and FTP are required. The rest is optional.'**
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
  /// **'Tap the map to mark the area · {radius} km radius'**
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
  /// **'{blocks} blocks · {minutes} min'**
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
  /// **'Recovery is a block like any other: to build 4×8min Z4 with 2min easy, add Z4, then Z1, and duplicate the pair.'**
  String get builderSequenceNote;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
