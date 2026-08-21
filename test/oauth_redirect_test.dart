import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/services/integrations_store.dart';
import 'package:trailwatt/services/platform/auth_session_store.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';
import 'package:trailwatt/services/platform/platform_oauth_service.dart';

/// A pending authorization has to survive the round trip to the platform's
/// consent page. On the web that trip reloads the app, so anything held in a
/// plain field is gone before the answer arrives.
void main() {
  /// The real credential shapes with a client id filled in, which is the
  /// one thing a build without registered apps is missing.
  Map<ResultSource, PlatformCredentials> configured() {
    final out = <ResultSource, PlatformCredentials>{};
    for (final p in PlatformCredentials.connectable) {
      final real = PlatformCredentials.of(p);
      out[p] = PlatformCredentials(
        platform: real.platform,
        clientId: 'id-${p.name}',
        authorizationEndpoint: real.authorizationEndpoint,
        tokenEndpoint: real.tokenEndpoint,
        apiBaseUrl: real.apiBaseUrl,
        scopes: real.scopes,
        redirectUri: real.redirectUri,
        capabilities: real.capabilities,
        extraAuthorizationParams: real.extraAuthorizationParams,
      );
    }
    return out;
  }

  /// A platform that hands back a token for any code.
  http.Client tokenGrantingClient() => MockClient((_) async => http.Response(
        jsonEncode({
          'access_token': 'at',
          'refresh_token': 'rt',
          'expires_in': 3600,
          'token_type': 'Bearer',
        }),
        200,
      ));

  group('a redirect finds its own platform', () {
    test('the platform is identified by the state it issued', () async {
      final sessions = InMemoryAuthSessionStore();
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );

      final pending = store.beginConnect(ResultSource.strava);
      final done = await store.completeFromRedirect(Uri.parse(
          'trailwatt://oauth/strava?code=abc&state=${pending.state}'));

      expect(done, ResultSource.strava);
      expect(store.isConnected(ResultSource.strava), isTrue);
    });

    test('two platforms waiting at once do not get confused', () async {
      final sessions = InMemoryAuthSessionStore();
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );

      store.beginConnect(ResultSource.strava);
      final wahoo = store.beginConnect(ResultSource.wahoo);

      final done = await store.completeFromRedirect(
          Uri.parse('trailwatt://oauth/x?code=abc&state=${wahoo.state}'));

      expect(done, ResultSource.wahoo);
      expect(store.isConnected(ResultSource.wahoo), isTrue);
      expect(store.isConnected(ResultSource.strava), isFalse);
    });

    test('a redirect carrying a state nobody issued belongs to nobody',
        () async {
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: InMemoryAuthSessionStore(),
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      store.beginConnect(ResultSource.strava);

      expect(
          store.awaitsRedirect(
              Uri.parse('trailwatt://oauth/strava?code=abc&state=elsewhere')),
          isFalse);
      expect(
          await store.completeFromRedirect(
              Uri.parse('trailwatt://oauth/strava?code=abc&state=elsewhere')),
          isNull);
    });

    test('an ordinary launch URL is not treated as a redirect', () {
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: InMemoryAuthSessionStore(),
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      store.beginConnect(ResultSource.strava);

      expect(store.awaitsRedirect(Uri.parse('https://trailwatt.app/#/home')),
          isFalse);
    });
  });

  group('surviving the reload the redirect causes', () {
    test('a session written before the trip is readable after it', () async {
      // The same storage, two app lifetimes: what a web redirect does.
      final sessions = InMemoryAuthSessionStore();

      final before = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      final pending = before.beginConnect(ResultSource.garmin);

      final after = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      final done = await after.completeFromRedirect(Uri.parse(
          'trailwatt://oauth/garmin?code=abc&state=${pending.state}'));

      expect(done, ResultSource.garmin,
          reason: 'without this the rider sees "nothing was pending" for '
              'doing exactly what they were asked to do');
      expect(after.isConnected(ResultSource.garmin), isTrue);
    });

    test('the same redirect cannot be redeemed twice', () async {
      final sessions = InMemoryAuthSessionStore();
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      final pending = store.beginConnect(ResultSource.strava);
      final redirect =
          Uri.parse('trailwatt://oauth/strava?code=abc&state=${pending.state}');

      await store.completeFromRedirect(redirect);
      expect(await store.completeFromRedirect(redirect), isNull,
          reason: 'a replayed authorization must not reconnect anything');
    });

    test('disconnecting clears a pending authorization too', () {
      final sessions = InMemoryAuthSessionStore();
      final store = IntegrationsStore(
        credentials: configured(),
        sessions: sessions,
        oauth: PlatformOAuthService(client: tokenGrantingClient()),
      );
      final pending = store.beginConnect(ResultSource.strava);
      store.disconnect(ResultSource.strava);

      expect(sessions.platformForState(pending.state), isNull);
    });
  });
}
