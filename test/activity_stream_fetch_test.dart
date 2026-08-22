import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/services/platform/oauth_tokens.dart';
import 'package:trailwatt/services/platform/platform_api_client.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';

final tokens = OAuthTokens(
  accessToken: 'at',
  refreshToken: 'rt',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
  scopes: const ['activity:read'],
);

PlatformCredentials credentialsFor(ResultSource platform) {
  final real = PlatformCredentials.of(platform);
  return PlatformCredentials(
    platform: real.platform,
    clientId: 'id',
    authorizationEndpoint: real.authorizationEndpoint,
    tokenEndpoint: real.tokenEndpoint,
    apiBaseUrl: Uri.parse('https://api.test/v3'),
    scopes: real.scopes,
    redirectUri: real.redirectUri,
    capabilities: real.capabilities,
    extraAuthorizationParams: real.extraAuthorizationParams,
  );
}

/// The shape Strava returns with key_by_type=true.
String streamBody({
  List<num>? time,
  List<num>? distance,
  List<num?>? altitude,
  List<num?>? watts,
}) =>
    jsonEncode({
      if (time != null) 'time': {'data': time},
      if (distance != null) 'distance': {'data': distance},
      if (altitude != null) 'altitude': {'data': altitude},
      if (watts != null) 'watts': {'data': watts},
    });

void main() {
  group('reading a ride back from the platform', () {
    test('the four series line up by sample', () async {
      Uri? asked;
      final client = PlatformApiClient(
        client: MockClient((request) async {
          asked = request.url;
          return http.Response(
              streamBody(
                time: [0, 1, 2],
                distance: [0, 8, 16],
                altitude: [500, 500.4, 500.8],
                watts: [210, 215, 205],
              ),
              200);
        }),
      );

      final stream = await client.activityStream(
        credentials: credentialsFor(ResultSource.strava),
        tokens: tokens,
        activityId: '12345',
      );

      expect(asked!.path, contains('/activities/12345/streams'));
      expect(asked!.queryParameters['keys'], contains('watts'));
      expect(asked!.queryParameters['key_by_type'], 'true');

      expect(stream.length, 3);
      expect(stream.distanceM, [0, 8, 16]);
      expect(stream.powerW, [210, 215, 205]);
      expect(stream.canCalibrate, isTrue);
    });

    test('a ride with no power meter comes back saying so', () async {
      final client = PlatformApiClient(
        client: MockClient((_) async => http.Response(
            streamBody(
                time: [0, 1, 2],
                distance: [0, 8, 16],
                altitude: [500, 500.4, 500.8]),
            200)),
      );

      final stream = await client.activityStream(
        credentials: credentialsFor(ResultSource.strava),
        tokens: tokens,
        activityId: '1',
      );

      expect(stream.powerW.every((p) => p == null), isTrue);
      expect(stream.canCalibrate, isFalse,
          reason: 'no power is no calibration, not zero watts');
    });

    test('a gap in a series stays a gap', () async {
      final client = PlatformApiClient(
        client: MockClient((_) async => http.Response(
            streamBody(
                time: [0, 1, 2],
                distance: [0, 8, 16],
                altitude: [500, null, 500.8],
                watts: [210, null, 205]),
            200)),
      );

      final stream = await client.activityStream(
        credentials: credentialsFor(ResultSource.strava),
        tokens: tokens,
        activityId: '1',
      );

      expect(stream.powerW[1], isNull);
      expect(stream.altitudeM[1], isNull);
    });

    test('a stream with no distance is refused, not patched', () async {
      final client = PlatformApiClient(
        client: MockClient(
            (_) async => http.Response(streamBody(time: [0, 1, 2]), 200)),
      );

      expect(
          () => client.activityStream(
                credentials: credentialsFor(ResultSource.strava),
                tokens: tokens,
                activityId: '1',
              ),
          throwsA(isA<PlatformApiException>().having((e) => e.failure,
              'failure', PlatformApiFailure.invalidResponse)));
    });
  });

  group('platforms whose stream endpoint is not documented here', () {
    for (final platform in [ResultSource.garmin, ResultSource.wahoo]) {
      test('${platform.name} reports unsupported rather than guessing',
          () async {
        var called = false;
        final client = PlatformApiClient(
          client: MockClient((_) async {
            called = true;
            return http.Response('{}', 200);
          }),
        );

        await expectLater(
            () => client.activityStream(
                  credentials: credentialsFor(platform),
                  tokens: tokens,
                  activityId: '1',
                ),
            throwsA(isA<PlatformApiException>().having(
                (e) => e.failure, 'failure', PlatformApiFailure.notSupported)));
        expect(called, isFalse,
            reason: 'an endpoint nobody read the documentation for must not '
                'be called on the chance that it works');
      });
    }
  });
}
