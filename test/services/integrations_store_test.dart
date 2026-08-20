import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/platform_integration.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/services/integrations_store.dart';
import 'package:trailwatt/services/platform/platform_api_client.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';
import 'package:trailwatt/services/platform/platform_oauth_service.dart';

PlatformCredentials _credentials(ResultSource platform,
        {String clientId = 'client-123'}) =>
    PlatformCredentials(
      platform: platform,
      clientId: clientId,
      authorizationEndpoint: Uri.parse('https://example.test/oauth/authorize'),
      tokenEndpoint: Uri.parse('https://example.test/oauth/token'),
      apiBaseUrl: Uri.parse('https://example.test/api/v3'),
      scopes: const ['activity:read'],
      redirectUri: Uri.parse('trailwatt://oauth/${platform.name}'),
    );

/// A store over three platforms, with Wahoo deliberately left unconfigured
/// so the "this build cannot connect" path is covered too.
IntegrationsStore _store({
  Object tokenResponse = const {
    'access_token': 'access-1',
    'refresh_token': 'refresh-1',
    'expires_in': 3600,
    'scope': 'activity:read',
  },
  int status = 200,
  String wahooClientId = '',
}) {
  final client = MockClient((req) async => http.Response(
      jsonEncode(tokenResponse), status,
      headers: {'content-type': 'application/json'}));
  return IntegrationsStore(
    oauth: PlatformOAuthService(client: client),
    api: PlatformApiClient(client: client),
    credentials: {
      ResultSource.strava: _credentials(ResultSource.strava),
      ResultSource.garmin: _credentials(ResultSource.garmin),
      ResultSource.wahoo:
          _credentials(ResultSource.wahoo, clientId: wahooClientId),
    },
  );
}

Future<void> _connect(IntegrationsStore store, ResultSource platform) async {
  final pending = store.beginConnect(platform);
  await store.completeConnect(
    platform,
    Uri.parse('trailwatt://oauth/${platform.name}'
        '?code=abc&state=${pending.state}'),
  );
}

void main() {
  test('a platform starts disconnected and connects only with a real token',
      () async {
    final store = _store();
    expect(store.stateOf(ResultSource.strava),
        PlatformConnectionState.disconnected);
    expect(store.connectionFor(ResultSource.strava), isNull);

    await _connect(store, ResultSource.strava);

    expect(store.isConnected(ResultSource.strava), isTrue);
    final connection = store.connectionFor(ResultSource.strava)!;
    expect(connection.state, PlatformConnectionState.connected);
    expect(connection.scopes, ['activity:read']);
    expect(connection.connectedAt, isNotNull);
  });

  test('a build with no client id reads as not configured, not disconnected',
      () {
    final store = _store();
    // The distinction is what stops the UI offering a Connect button that
    // could only ever fail.
    expect(store.stateOf(ResultSource.wahoo),
        PlatformConnectionState.notConfigured);
    expect(
      () => store.beginConnect(ResultSource.wahoo),
      throwsA(isA<PlatformAuthException>().having(
          (e) => e.failure, 'failure', PlatformAuthFailure.notConfigured)),
    );
  });

  test('disconnecting one platform does not touch the others', () async {
    final store = _store();
    await _connect(store, ResultSource.strava);
    await _connect(store, ResultSource.garmin);
    expect(
        store.connectedPlatforms, [ResultSource.strava, ResultSource.garmin]);

    store.disconnect(ResultSource.strava);

    // Spec 002, Requirement 9.
    expect(store.isConnected(ResultSource.strava), isFalse);
    expect(store.isConnected(ResultSource.garmin), isTrue);
  });

  test('a redirect with no authorization in flight is refused', () async {
    final store = _store();
    await expectLater(
      store.completeConnect(
          ResultSource.strava, Uri.parse('trailwatt://oauth/strava?code=abc')),
      throwsA(isA<PlatformAuthException>().having((e) => e.failure, 'failure',
          PlatformAuthFailure.noPendingAuthorization)),
    );
    expect(store.isConnected(ResultSource.strava), isFalse);
  });

  test('asking for tokens on a platform that is not connected is unauthorized',
      () async {
    await expectLater(
      _store().validTokensFor(ResultSource.strava),
      throwsA(isA<PlatformApiException>().having(
          (e) => e.failure, 'failure', PlatformApiFailure.unauthorized)),
    );
  });

  test('an expired token is renewed on use', () async {
    final store = _store(tokenResponse: const {
      'access_token': 'access-1',
      'refresh_token': 'refresh-1',
      // Already expired the moment it arrives.
      'expires_in': 0,
    });
    await _connect(store, ResultSource.strava);

    final tokens = await store.validTokensFor(ResultSource.strava);

    expect(tokens.accessToken, 'access-1');
    expect(store.isConnected(ResultSource.strava), isTrue);
  });

  test(
      'a refresh the platform refuses drops the connection instead of '
      'leaving it claiming to be connected', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      // First call is the code exchange, second is the refresh.
      return calls == 1
          ? http.Response(
              jsonEncode(const {
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
                'expires_in': 0,
              }),
              200,
              headers: {'content-type': 'application/json'})
          : http.Response('{"error":"invalid_grant"}', 400,
              headers: {'content-type': 'application/json'});
    });
    final store = IntegrationsStore(
      oauth: PlatformOAuthService(client: client),
      api: PlatformApiClient(client: client),
      credentials: {ResultSource.strava: _credentials(ResultSource.strava)},
    );

    await _connect(store, ResultSource.strava);
    expect(store.isConnected(ResultSource.strava), isTrue);

    await expectLater(
      store.validTokensFor(ResultSource.strava),
      throwsA(isA<PlatformApiException>().having(
          (e) => e.failure, 'failure', PlatformApiFailure.unauthorized)),
    );
    expect(store.isConnected(ResultSource.strava), isFalse,
        reason: 'a dead session must stop reading as connected');
  });

  test('connecting notifies listeners so every screen sees the same state',
      () async {
    final store = _store();
    var notifications = 0;
    store.addListener(() => notifications++);

    await _connect(store, ResultSource.strava);
    expect(notifications, 1);

    store.disconnect(ResultSource.strava);
    expect(notifications, 2);
  });
}
