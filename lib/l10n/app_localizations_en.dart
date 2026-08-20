import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trailwatt';

  @override
  String get splashTagline => 'Suggest. Export. Repeat.';

  @override
  String get authWelcome => 'Welcome';

  @override
  String get authLoginSubtitle => 'Sign in to your Trailwatt account';

  @override
  String get authSignupSubtitle => 'Takes less than a minute';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authName => 'Name';

  @override
  String get authNameHint => 'your name';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'name@email.com';

  @override
  String get authBirthDate => 'Date of birth';

  @override
  String get authBirthDateHint => 'DD/MM/YYYY';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'your password';

  @override
  String get authCreatePasswordHint => 'create a password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'repeat the password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authOr => 'OR';

  @override
  String get authConsentPrefix => 'I agree to the ';

  @override
  String get authConsentTerms => 'Terms of Use';

  @override
  String get authConsentMiddle => ' and the ';

  @override
  String get authConsentPrivacy => 'Privacy Policy';

  @override
  String get profileTitle => 'Create profile';

  @override
  String get profileSubtitle =>
      'Weight and FTP are required. The rest is optional.';

  @override
  String get profileWeight => 'Weight (kg)';

  @override
  String get profileFtp => 'FTP (watts)';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileFootnote =>
      'Weight and FTP are enough for the engine to work. Zones can stay on the generic bands or be adjusted by hand.';

  @override
  String get profilePowerZones => 'POWER ZONES';

  @override
  String get profilePowerZonesAnchor => 'Anchored on FTP';

  @override
  String get profileHeartRateZones => 'HEART RATE ZONES';

  @override
  String get profileHeartRateZonesNote =>
      'A separate table from power - the same effort falls in different zones in each.';

  @override
  String get profileAnchorOn => 'Anchor on';

  @override
  String get profileAnchorThreshold => 'Threshold (LTHR)';

  @override
  String get profileAnchorMax => 'Max HR';

  @override
  String get profileThresholdHr => 'Threshold HR (bpm)';

  @override
  String get profileMaxHr => 'Max HR (bpm)';

  @override
  String get profileOptional => 'optional';

  @override
  String get profileNoHrAnchor =>
      'Without this measurement the app does not calculate HR zones - and does not invent them: watts-based training keeps working.';

  @override
  String get scaleFive => 'Z1-Z5';

  @override
  String get scaleSeven => 'Z1-Z7';

  @override
  String get zoneTableGeneric => 'GENERIC';

  @override
  String get zoneTableCustom => 'CUSTOM';

  @override
  String get zoneTableEditBounds => 'Edit bounds';

  @override
  String get zoneTableRestoreDefault => 'Restore default';

  @override
  String get zoneTableRecalculate => 'Recalculate';

  @override
  String get zoneTableAnchorMoved =>
      'The anchor changed. These bounds are the ones you typed and did not follow it.';

  @override
  String get zoneTableInvalid =>
      'Each bound must be greater than the previous one. The table will not be saved while they overlap.';

  @override
  String get zoneTableProvisional =>
      'Generic bands, pending physiological review. Tap \"Edit bounds\" to use yours.';

  @override
  String get zoneTableNeedsAnchor => 'Set the anchor to calculate this table.';

  @override
  String get zoneRecovery => 'Recovery';

  @override
  String get zoneActiveRecovery => 'Active recovery';

  @override
  String get zoneEndurance => 'Endurance';

  @override
  String get zoneTempo => 'Tempo';

  @override
  String get zoneThreshold => 'Threshold';

  @override
  String get zoneVo2max => 'VO2max';

  @override
  String get zoneAnaerobic => 'Anaerobic';

  @override
  String get zoneNeuromuscular => 'Neuromuscular';

  @override
  String get metricPower => 'Power';

  @override
  String get metricHeartRate => 'Heart rate';

  @override
  String get unitWatts => 'w';

  @override
  String get unitBpm => 'bpm';

  @override
  String get builderTitle => 'Create workout';

  @override
  String get builderSubtitle => 'Build the workout and mark where to ride';

  @override
  String get builderWatts => 'Watts';

  @override
  String get builderHr => 'HR';

  @override
  String builderTableLabel(String metric, int count) {
    return '$metric table · Z1-Z$count';
  }

  @override
  String builderBlock(int number) {
    return 'BLOCK $number';
  }

  @override
  String get builderZone => 'Zone';

  @override
  String get builderDuration => 'Duration (min)';

  @override
  String builderMin(String unit) {
    return 'Minimum ($unit)';
  }

  @override
  String builderMax(String unit) {
    return 'Maximum ($unit)';
  }

  @override
  String get builderContinue => 'Continue';

  @override
  String get builderFootnote =>
      'The block name uses the same zone naming as the rest of the app. The workout is sovereign - the route adapts to the stimulus, not the other way round.';

  @override
  String get builderNoHrAnchor =>
      'Set a threshold or max HR in your profile to prescribe by heart rate.';

  @override
  String get locationTitle => 'Create workout';

  @override
  String get locationSubtitle => 'Continued - where to ride';

  @override
  String get locationWhere => 'WHERE TO RIDE';

  @override
  String locationHint(int radius) {
    return 'Tap the map to mark the area · $radius km radius';
  }

  @override
  String get locationGenerate => 'Generate route suggestions';

  @override
  String get todayTitle => 'Today\'s workout';

  @override
  String get todaySubtitle => '4x8min at 180w';

  @override
  String get todayTarget => 'TARGET';

  @override
  String get todayGradient => 'GRADIENT';

  @override
  String get todaySegment => 'SEGMENT';

  @override
  String get routeSubtitle => 'Segment suggested for today\'s workout';

  @override
  String get routeDistance => 'DISTANCE';

  @override
  String get routeGradientLabel => 'GRADIENT';

  @override
  String get routeMatch => 'MATCH';

  @override
  String get routeEditManually => 'Edit route manually';

  @override
  String get routeExportTo => 'EXPORT TO';

  @override
  String get routeExport => 'Export route';

  @override
  String routeExported(String platform) {
    return 'Route exported to $platform';
  }

  @override
  String get routeFootnote =>
      'The segment colour follows the effort zone (Z1 to Z5, watts or HR) predicted for that point of the climb - not just \"inside or outside the target\".';

  @override
  String get routeDegraded => 'Segment not verified against the road network.';

  @override
  String get routeSavedRescored => 'Route re-scored and saved';

  @override
  String get editRouteTitle => 'Edit route';

  @override
  String get editRouteSubtitle => 'The workout segment inside the full ride';

  @override
  String get editRouteHint =>
      'Drag the points to edit. On release the point snaps to the nearest road and the route is redrawn along the streets.';

  @override
  String get editRouteTotal => 'TOTAL RIDE';

  @override
  String get editRouteSegment => 'WORKOUT SEGMENT';

  @override
  String get editRouteImpact => 'Edit impact';

  @override
  String get editRouteDeviation => 'Deviation';

  @override
  String get editRouteSnap => 'Road snap';

  @override
  String editRouteSnapMeters(int meters) {
    return '$meters m to the road';
  }

  @override
  String get editRouteSnapUnverified => 'not verified';

  @override
  String get editRoutePredictedMatch => 'Predicted match';

  @override
  String get editRouteNeedsRoads => 'requires the road network';

  @override
  String get editRouteImpactNote =>
      'The app does not save a material change without re-scoring the match.';

  @override
  String get editRouteSave => 'Save changes';

  @override
  String get editRouteCancel => 'Cancel';

  @override
  String get importTitle => 'Workout result';

  @override
  String get importSubtitle => 'Fetched automatically via API';

  @override
  String get importConnectedTo => 'CONNECTED TO STRAVA';

  @override
  String get importActivityFound => 'Activity found';

  @override
  String get importActivityWhen => 'Subida da Serra · today, 07:14';

  @override
  String get importAvgPower => 'AVG POWER';

  @override
  String get importAvgHr => 'AVG HR';

  @override
  String get importDuration => 'DURATION';

  @override
  String get importConfirm => 'Confirm and save';

  @override
  String get importNoApi => 'NO API CONNECTION?';

  @override
  String get importManualPower => 'Average power (w)';

  @override
  String get importManualHint => 'enter manually';

  @override
  String get importManualHelp =>
      'Less accurate - use only if the automatic import fails.';

  @override
  String get importManualLink => 'Fill in manually per stimulus';

  @override
  String get importFootnote =>
      'The API finds the matching activity automatically. Manual entry only appears as a last resort, and stays visually secondary.';

  @override
  String get manualIntervalsSubtitle => 'Manual entry · interval workout';

  @override
  String get manualContinuousSubtitle => 'Manual entry · continuous workout';

  @override
  String manualStimulus(int number, String duration) {
    return 'STIMULUS $number · $duration';
  }

  @override
  String get manualEnduranceRide => 'ENDURANCE RIDE · 60 MIN';

  @override
  String manualTarget(int watts) {
    return 'target ${watts}w';
  }

  @override
  String get manualAvgWatts => 'avg watts';

  @override
  String get manualSave => 'Save workout';

  @override
  String get historyTitle => 'Your progress';

  @override
  String get historyCurrentFtp => 'CURRENT FTP';

  @override
  String get historyAccuracy => 'ACCURACY';

  @override
  String get historyRecent => 'Recent workouts';

  @override
  String historyTargetWatts(int watts) {
    return 'target ${watts}w';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarWeek => 'Week';

  @override
  String get calendarMonth => 'Month';

  @override
  String get calendarRestDay => 'Rest day - no workout planned.';

  @override
  String get calendarDone => 'DONE';

  @override
  String calendarVia(String source) {
    return 'via $source';
  }

  @override
  String get calendarActual => 'ACTUAL';

  @override
  String get calendarPlanned => 'TARGET';

  @override
  String get calendarDuration => 'DURATION';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navHistory => 'History';

  @override
  String get navMore => 'More';

  @override
  String get navComingSoon => 'Coming soon';

  @override
  String get sourceStrava => 'Strava';

  @override
  String get sourceGarmin => 'Garmin';

  @override
  String get sourceWahoo => 'Wahoo';

  @override
  String get sourceManual => 'manual entry';

  @override
  String get landingEyebrow => 'FOR CYCLISTS, FROM BEGINNER TO PRO';

  @override
  String get landingHeadline =>
      'Your workout already tells you the ideal route.';

  @override
  String get landingSubhead =>
      'Enter today\'s workout target and Trailwatt suggests a real route that matches it.';

  @override
  String get landingStartFree => 'Start free';

  @override
  String get landingHowItWorks => 'See how it works';

  @override
  String get landingFeature1Title => 'Target by power or HR';

  @override
  String get landingFeature1Body =>
      'From a 150w FTP to a 300w one, the engine works out the right gradient for your level.';

  @override
  String get landingFeature2Title => '100% local calculation';

  @override
  String get landingFeature2Body =>
      'The physics engine runs on the device itself. It works even with no internet.';

  @override
  String get landingFeature3Title => 'Exports and imports on its own';

  @override
  String get landingFeature3Body =>
      'Sends the finished route to Strava, Garmin or Wahoo, and fetches the result back.';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get routingUnavailable =>
      'Routing service unavailable - straight-line distance.';

  @override
  String get routingNoRoute =>
      'No route found on the road network between these points.';

  @override
  String get routingNeedsTwoPoints =>
      'Mark at least two points to trace the route.';

  @override
  String get importPowerCurveSnack =>
      'Optional connection - fills the curve via API';

  @override
  String get builderAddBlock => '+ Add block';

  @override
  String calendarWorkoutSummary(int blocks, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocks',
      one: '1 block',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get builderRoleWarmUp => 'Warm-up';

  @override
  String get builderRoleWork => 'Work';

  @override
  String get builderRoleRecovery => 'Recovery';

  @override
  String get builderRoleCoolDown => 'Cool-down';

  @override
  String get builderRole => 'Type';

  @override
  String get builderDuplicate => 'Duplicate';

  @override
  String get builderRemove => 'Remove';

  @override
  String builderTotalDuration(int minutes) {
    return 'Total: $minutes min';
  }

  @override
  String get builderSequenceNote =>
      'A block can hold two or more stimuli: to build 4x8min Z4 with 2min easy, add a Z4 stimulus, tap \"+ Stimulus\" to add the Z1, and set how many times to repeat.';

  @override
  String get sourceTrainingPeaks => 'TrainingPeaks';

  @override
  String get builderAddStimulus => '+ Stimulus';

  @override
  String builderStimulus(int number) {
    return 'Stimulus $number';
  }

  @override
  String get builderRepeat => 'Repeat (x)';

  @override
  String get moreTitle => 'More';

  @override
  String get moreSubtitle => 'Profile, integrations and more';

  @override
  String get moreProfile => 'Profile';

  @override
  String get moreProfileSubtitle => 'Weight, FTP and zones';

  @override
  String get moreIntegrations => 'Integrations';

  @override
  String get moreIntegrationsSubtitle =>
      'Strava, Garmin, Wahoo and TrainingPeaks';

  @override
  String get integrationsTitle => 'Integrations';

  @override
  String get integrationsSubtitle =>
      'Connect Strava, Garmin and Wahoo to export routes and pick the result back up, and TrainingPeaks to import your planned workout.';

  @override
  String get integrationsConnected => 'Connected';

  @override
  String get integrationsNotConnected => 'Not connected';

  @override
  String get integrationsConnect => 'Connect';

  @override
  String get integrationsDisconnect => 'Disconnect';

  @override
  String get integrationsScopeNote =>
      'The connection only reads the matching activity or planned workout - never a bulk import of your history (Article II).';

  @override
  String get importWorkoutFabLabel => 'Import from TrainingPeaks';

  @override
  String get importWorkoutSuccessSnack => 'Workout imported from TrainingPeaks';

  @override
  String get importWorkoutNoConnectionTitle => 'No TrainingPeaks connection';

  @override
  String get importWorkoutNoConnectionBody =>
      'Connect your account to import your preferred workout automatically, or keep building it manually.';

  @override
  String get importWorkoutConnectCta => 'Connect now';

  @override
  String get importWorkoutManualCta => 'Create manually';

  @override
  String get integrationsExpired => 'Session expired';

  @override
  String get integrationsNotConfigured => 'Not available in this build';

  @override
  String get integrationsReconnect => 'Reconnect';

  @override
  String get integrationsNotConfiguredNote =>
      'This build carries no API client id for the platform, so it cannot connect. Supply one at build time with --dart-define.';

  @override
  String integrationsScopes(String scopes) {
    return 'Permissions: $scopes';
  }

  @override
  String integrationsConnectTitle(String platform) {
    return 'Connect $platform';
  }

  @override
  String get integrationsConnectStep1 =>
      '1. Open this address and approve the access:';

  @override
  String get integrationsConnectStep2 =>
      '2. Paste the address you were redirected to:';

  @override
  String get integrationsRedirectLabel => 'Redirect URL';

  @override
  String get integrationsConnectConfirm => 'Finish connecting';

  @override
  String integrationsConnectedSnack(String platform) {
    return '$platform connected';
  }

  @override
  String get integrationsCopyUrl => 'Copy address';

  @override
  String get integrationsUrlCopied => 'Address copied';

  @override
  String get integrationsErrorNotConfigured =>
      'This build cannot connect to that platform.';

  @override
  String get integrationsErrorDenied =>
      'Access was not granted on the platform.';

  @override
  String get integrationsErrorStateMismatch =>
      'That redirect does not match the connection we started. Try connecting again.';

  @override
  String get integrationsErrorNoCode =>
      'The redirect carried no authorization code.';

  @override
  String get integrationsErrorNetwork =>
      'Could not reach the platform. Check your connection and try again.';

  @override
  String get integrationsErrorInvalidResponse =>
      'The platform answered with something unexpected.';

  @override
  String get routeExporting => 'Exporting...';

  @override
  String routeExportNotConnected(String platform) {
    return 'Connect $platform under More › Integrations first.';
  }

  @override
  String routeExportNotSupported(String platform) {
    return '$platform has no route API - export the file instead.';
  }

  @override
  String routeExportFailed(String platform) {
    return 'Could not export to $platform.';
  }

  @override
  String routeHandoffTitle(String platform) {
    return 'Import into $platform';
  }

  @override
  String routeHandoffBody(String platform) {
    return '$platform has no official endpoint for creating a route, so the app does not invent one. Here is the GPX - import it through $platform\'s own route importer.';
  }

  @override
  String get routeHandoffCopy => 'Copy GPX';

  @override
  String get routeHandoffCopied => 'GPX copied';

  @override
  String get importWorkoutNothingPlanned =>
      'No structured workout planned in TrainingPeaks for the week ahead.';

  @override
  String get importWorkoutReconnect =>
      'Your TrainingPeaks session ended. Connect it again under More › Integrations.';

  @override
  String get importWorkoutFailed =>
      'Could not read the planned workout from TrainingPeaks.';

  @override
  String get calendarAddWorkout => '+ Schedule a workout';

  @override
  String get calendarEditWorkout => 'Edit';

  @override
  String get calendarRemoveWorkout => 'Remove';

  @override
  String get calendarRemoveTitle => 'Remove this workout?';

  @override
  String get calendarRemoveBody =>
      'The day goes back to being a rest day. Nothing else in the plan changes.';

  @override
  String get calendarWorkoutRemoved => 'Workout removed from the day';

  @override
  String get calendarWorkoutSaved => 'Workout saved to the day';

  @override
  String get builderSaveToDay => 'Save to this day';

  @override
  String get calendarPlannedWorkout => 'PLANNED';

  @override
  String get calendarLinkActivity => 'Link a ride';

  @override
  String get calendarUnlinkActivity => 'Unlink';

  @override
  String get calendarLinkTitle => 'Which ride was this workout?';

  @override
  String get calendarLinkBody =>
      'Only rides not already recorded as another day\'s result are listed. Nothing is linked until you pick one.';

  @override
  String calendarActivityLinked(String activity) {
    return '$activity recorded as this day\'s result';
  }

  @override
  String get calendarUnlinkTitle => 'Unlink this ride?';

  @override
  String get calendarUnlinkBody =>
      'The ride stays in your history - it just stops being this day\'s result, and the day goes back to being planned.';

  @override
  String get calendarActivityUnlinked => 'Ride unlinked from the day';

  @override
  String historyLinkedTo(String day) {
    return 'result of $day';
  }

  @override
  String get historyNotLinked => 'not linked to a workout';
}
