import 'package:flutter/foundation.dart';

import '../models/platform_integration.dart';
import '../models/result_source.dart';
import 'platform/oauth_tokens.dart';
import 'platform/platform_api_client.dart';
import 'platform/platform_credentials.dart';
import 'platform/auth_session_store.dart';
import 'platform/platform_oauth_service.dart';

/// The rider's platform connections, shared across every screen that needs
/// to know whether Strava, Garmin, Wahoo or TrainingPeaks is connected: the
/// Integrations screen writes it, the route export and the workout import
/// both read it.
///
/// Connections are real OAuth sessions, not a flag. A platform is
/// `connected` only when this store is holding a token the platform issued;
/// there is no code path that marks one connected without one. That matters
/// more than it sounds: a fake "connected" state would make the export and
/// import screens claim a round-trip that never happened, which is the one
/// thing AUDIT_RESULT.md's "never hide uncertainty" rules out.
///
/// Tokens live in memory only. Persisting them is a real requirement for a
/// shipping build and it needs the platform keystore/keychain rather than
/// shared preferences - deliberately left to the host app instead of being
/// half-done here with plain-text storage.
class IntegrationsStore extends ChangeNotifier {
  final PlatformOAuthService _oauth;
  final PlatformApiClient _api;
  final Map<ResultSource, PlatformCredentials> _credentials;

  final Map<ResultSource, OAuthTokens> _tokens = {};
  final Map<ResultSource, DateTime> _connectedAt = {};

  /// Half-finished authorizations. Not a plain map because on the web the
  /// redirect reloads the page and would take them with it.
  final AuthSessionStore _sessions;

  IntegrationsStore({
    PlatformOAuthService? oauth,
    PlatformApiClient? api,
    Map<ResultSource, PlatformCredentials>? credentials,
    AuthSessionStore? sessions,
  })  : _sessions = sessions ?? AuthSessionStore.forPlatform(),
        _oauth = oauth ?? PlatformOAuthService(),
        _api = api ?? PlatformApiClient(),
        _credentials = credentials ??
            {
              for (final p in PlatformCredentials.connectable)
                p: PlatformCredentials.of(p),
            };

  /// The app-wide store. Tests build their own with injected services rather
  /// than reaching for this one.
  static final IntegrationsStore instance = IntegrationsStore();

  PlatformApiClient get api => _api;

  PlatformCredentials credentialsFor(ResultSource platform) =>
      _credentials[platform] ?? PlatformCredentials.of(platform);

  List<ResultSource> get platforms => _credentials.keys.toList(growable: false);

  PlatformConnectionState stateOf(ResultSource platform) {
    if (!credentialsFor(platform).isConfigured) {
      return PlatformConnectionState.notConfigured;
    }
    final tokens = _tokens[platform];
    if (tokens == null) return PlatformConnectionState.disconnected;
    // An expired token that can still be refreshed is not a broken
    // connection, so it keeps reading as connected and is renewed on use.
    if (tokens.isExpired && !tokens.canRefresh) {
      return PlatformConnectionState.expired;
    }
    return PlatformConnectionState.connected;
  }

  PlatformConnection? connectionFor(ResultSource platform) {
    final tokens = _tokens[platform];
    if (tokens == null) return null;
    return PlatformConnection(
      platform: platform,
      state: stateOf(platform),
      scopes: tokens.scopes.isEmpty
          ? credentialsFor(platform).scopes
          : tokens.scopes,
      connectedAt: _connectedAt[platform],
    );
  }

  bool isConnected(ResultSource platform) =>
      stateOf(platform) == PlatformConnectionState.connected;

  /// Starts an authorization: returns the URL the rider has to open and
  /// approve. Throws [PlatformAuthException] with `notConfigured` when this
  /// build has no client id for the platform.
  PendingAuthorization beginConnect(ResultSource platform) {
    final pending = _oauth.beginAuthorization(credentialsFor(platform));
    _sessions.save(platform, pending);
    return pending;
  }

  /// Finishes whatever authorization this redirect answers, without the
  /// caller having to know which platform sent it.
  ///
  /// The platform is identified by the `state` the redirect carries, not by
  /// the shape of its URL: each platform builds its callback differently,
  /// and a redirect carrying a state nobody issued belongs to nobody.
  Future<ResultSource?> completeFromRedirect(Uri redirect) async {
    final state = redirect.queryParameters['state'];
    if (state == null || state.isEmpty) return null;
    final platform = _sessions.platformForState(state);
    if (platform == null) return null;
    await completeConnect(platform, redirect);
    return platform;
  }

  /// True when this redirect is one the app is waiting for. Lets a launch
  /// handler ignore ordinary URLs without starting a connection attempt.
  bool awaitsRedirect(Uri redirect) {
    final state = redirect.queryParameters['state'];
    if (state == null || state.isEmpty) return false;
    return _sessions.platformForState(state) != null;
  }

  /// Finishes the authorization the platform redirected back from. Wire this
  /// to the app's deep-link handler, or to the redirect URL the rider pastes
  /// back in.
  Future<void> completeConnect(ResultSource platform, Uri redirect) async {
    final pending = _sessions.peek(platform);
    if (pending == null) {
      throw const PlatformAuthException(
          PlatformAuthFailure.noPendingAuthorization);
    }

    final tokens = await _oauth.completeAuthorization(
      credentials: credentialsFor(platform),
      pending: pending,
      redirect: redirect,
    );

    _sessions.clear(platform);
    _tokens[platform] = tokens;
    _connectedAt[platform] = DateTime.now();
    notifyListeners();
  }

  /// Disconnecting one platform MUST NOT affect the others (spec 002,
  /// Requirement 9) - this only ever touches its own entries.
  void disconnect(ResultSource platform) {
    _tokens.remove(platform);
    _connectedAt.remove(platform);
    _sessions.clear(platform);
    notifyListeners();
  }

  /// A usable token for [platform], refreshed first if it has expired.
  ///
  /// Throws [PlatformApiException] with `unauthorized` when the platform is
  /// not connected or the session can no longer be renewed - callers surface
  /// that as "connect again", never as a silent no-op.
  Future<OAuthTokens> validTokensFor(ResultSource platform) async {
    final tokens = _tokens[platform];
    if (tokens == null) {
      throw const PlatformApiException(PlatformApiFailure.unauthorized);
    }
    if (!tokens.isExpired) return tokens;

    if (!tokens.canRefresh) {
      throw const PlatformApiException(PlatformApiFailure.unauthorized);
    }

    try {
      final refreshed = await _oauth.refresh(
        credentials: credentialsFor(platform),
        tokens: tokens,
      );
      _tokens[platform] = refreshed;
      notifyListeners();
      return refreshed;
    } on PlatformAuthException catch (e) {
      // A refresh that fails is a dead session, not a transient error: drop
      // it so the UI stops claiming the platform is connected.
      _tokens.remove(platform);
      _connectedAt.remove(platform);
      notifyListeners();
      throw PlatformApiException(PlatformApiFailure.unauthorized,
          detail: e.detail);
    }
  }

  /// Every platform the rider currently has connected, in listing order.
  List<ResultSource> get connectedPlatforms =>
      platforms.where(isConnected).toList(growable: false);
}
