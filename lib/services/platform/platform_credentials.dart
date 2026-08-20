import '../../models/result_source.dart';

/// What a platform's official API actually lets Trailwatt do.
///
/// Feature 002 is explicit that Strava, Garmin and Wahoo are NOT assumed to
/// expose equivalent capabilities, and DECISIONS_REQUIRED.md keeps "Platform
/// API capabilities" open pending per-platform verification. So capability is
/// data, not an assumption baked into the call sites: a platform without a
/// documented route-upload endpoint falls back to the official file handoff
/// (spec 002, Scope) instead of the app inventing one.
class PlatformCapabilities {
  /// The platform documents an official endpoint that accepts a route/course
  /// file. When false, exporting means handing the rider a GPX to import
  /// through the platform's own importer - never a scraped upload.
  final bool routeUpload;

  /// The platform documents an official read API for a single completed
  /// activity (spec 002, Requirement 2).
  final bool activityRead;

  /// The platform documents an official activity-created webhook/event
  /// (spec 002, Requirement 4). Without one, its fallback is the manual
  /// entry path - the app does not invent polling to fake symmetry.
  final bool activityEvents;

  const PlatformCapabilities({
    this.routeUpload = false,
    this.activityRead = false,
    this.activityEvents = false,
  });
}

/// Everything needed to talk to one platform, resolved at build time.
///
/// Nothing here is a secret: these are public-client OAuth flows using PKCE,
/// which is exactly why no client *secret* appears in this file or anywhere
/// else in the app. A mobile binary cannot keep one, so the flows that need a
/// secret must be completed by a backend, not by shipping the secret.
///
/// The endpoint defaults below are the documented public ones at the time of
/// writing and are PROVISIONAL in the same sense as the OSRM defaults in
/// `routing_service.dart`: fine for development, to be verified (and the
/// partner terms read) before release. Override any of them at build time.
class PlatformCredentials {
  final ResultSource platform;
  final String clientId;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri apiBaseUrl;
  final List<String> scopes;
  final Uri redirectUri;
  final PlatformCapabilities capabilities;

  /// Extra query parameters a specific platform requires on the authorize
  /// call (Strava's `approval_prompt`, for instance).
  final Map<String, String> extraAuthorizationParams;

  const PlatformCredentials({
    required this.platform,
    required this.clientId,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.apiBaseUrl,
    required this.scopes,
    required this.redirectUri,
    this.capabilities = const PlatformCapabilities(),
    this.extraAuthorizationParams = const {},
  });

  /// No client id supplied at build time means this build genuinely cannot
  /// connect to the platform. The UI says exactly that rather than offering a
  /// Connect button that could only ever fail (or, worse, pretend).
  bool get isConfigured => clientId.isNotEmpty;

  // --- Build-time configuration ---------------------------------------
  //
  // `String.fromEnvironment` needs a literal name, so each platform is
  // written out rather than looked up in a loop.

  static const _stravaClientId =
      String.fromEnvironment('TRAILWATT_STRAVA_CLIENT_ID');
  static const _garminClientId =
      String.fromEnvironment('TRAILWATT_GARMIN_CLIENT_ID');
  static const _wahooClientId =
      String.fromEnvironment('TRAILWATT_WAHOO_CLIENT_ID');
  static const _trainingPeaksClientId =
      String.fromEnvironment('TRAILWATT_TRAININGPEAKS_CLIENT_ID');

  /// Where the platform sends the rider back after they approve. Must match
  /// the value registered with the platform exactly.
  static const _redirectUri = String.fromEnvironment(
    'TRAILWATT_OAUTH_REDIRECT',
    defaultValue: 'trailwatt://oauth',
  );

  static PlatformCredentials strava() => PlatformCredentials(
        platform: ResultSource.strava,
        clientId: _stravaClientId,
        authorizationEndpoint:
            Uri.parse('https://www.strava.com/oauth/authorize'),
        tokenEndpoint: Uri.parse('https://www.strava.com/oauth/token'),
        apiBaseUrl: Uri.parse('https://www.strava.com/api/v3'),
        // Requirement 10: no scope broader than "read the one activity that
        // matches the route we exported".
        scopes: const ['activity:read'],
        redirectUri: Uri.parse('$_redirectUri/strava'),
        extraAuthorizationParams: const {'approval_prompt': 'auto'},
        capabilities: const PlatformCapabilities(
          // Strava's public API uploads *activities*, not routes - route
          // creation is not a documented public endpoint, so exporting a
          // suggested route is a GPX handoff into Strava's own importer.
          routeUpload: false,
          activityRead: true,
          activityEvents: true,
        ),
      );

  static PlatformCredentials garmin() => PlatformCredentials(
        platform: ResultSource.garmin,
        clientId: _garminClientId,
        authorizationEndpoint:
            Uri.parse('https://connect.garmin.com/oauth2Confirm'),
        tokenEndpoint: Uri.parse(
            'https://diauth.garmin.com/di-oauth2-service/oauth/token'),
        apiBaseUrl: Uri.parse('https://apis.garmin.com'),
        scopes: const ['ACTIVITY_EXPORT'],
        redirectUri: Uri.parse('$_redirectUri/garmin'),
        capabilities: const PlatformCapabilities(
          // Garmin's course/training push sits behind the partner programme;
          // until a build supplies a verified endpoint, exporting is a GPX
          // handoff rather than an invented API call.
          routeUpload: false,
          activityRead: true,
          activityEvents: true,
        ),
      );

  static PlatformCredentials wahoo() => PlatformCredentials(
        platform: ResultSource.wahoo,
        clientId: _wahooClientId,
        authorizationEndpoint:
            Uri.parse('https://api.wahooligan.com/oauth/authorize'),
        tokenEndpoint: Uri.parse('https://api.wahooligan.com/oauth/token'),
        apiBaseUrl: Uri.parse('https://api.wahooligan.com/v1'),
        scopes: const ['workouts_read', 'routes_write'],
        redirectUri: Uri.parse('$_redirectUri/wahoo'),
        capabilities: const PlatformCapabilities(
          // Wahoo's Cloud API does document a routes endpoint, so a route can
          // be pushed directly rather than handed off as a file.
          routeUpload: true,
          activityRead: true,
          activityEvents: true,
        ),
      );

  static PlatformCredentials trainingPeaks() => PlatformCredentials(
        platform: ResultSource.trainingPeaks,
        clientId: _trainingPeaksClientId,
        authorizationEndpoint:
            Uri.parse('https://oauth.trainingpeaks.com/OAuth/Authorize'),
        tokenEndpoint: Uri.parse('https://oauth.trainingpeaks.com/oauth/token'),
        apiBaseUrl: Uri.parse('https://api.trainingpeaks.com/v1'),
        // TrainingPeaks is here to read the rider's *planned* workout, which
        // is a different read from the completed-activity one.
        scopes: const ['workouts:read'],
        redirectUri: Uri.parse('$_redirectUri/trainingpeaks'),
        capabilities: const PlatformCapabilities(
          routeUpload: false,
          activityRead: true,
          activityEvents: false,
        ),
      );

  static PlatformCredentials of(ResultSource platform) => switch (platform) {
        ResultSource.strava => strava(),
        ResultSource.garmin => garmin(),
        ResultSource.wahoo => wahoo(),
        ResultSource.trainingPeaks => trainingPeaks(),
        // Manual entry is the fallback that exists precisely because no
        // platform is connected; it has nothing to authorize.
        ResultSource.manual => throw ArgumentError(
            'Manual entry is not a connectable platform.',
          ),
      };

  /// The platforms a rider can connect, in the order the UI lists them.
  static const connectable = [
    ResultSource.strava,
    ResultSource.garmin,
    ResultSource.wahoo,
    ResultSource.trainingPeaks,
  ];
}
