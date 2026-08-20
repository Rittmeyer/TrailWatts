import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/services/platform/oauth_tokens.dart';
import 'package:trailwatt/services/platform/platform_api_client.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';

const _tokens = OAuthTokens(accessToken: 'access-1');

PlatformCredentials _credentials({
  ResultSource platform = ResultSource.strava,
  bool routeUpload = false,
  bool activityRead = true,
}) =>
    PlatformCredentials(
      platform: platform,
      clientId: 'client-123',
      authorizationEndpoint: Uri.parse('https://example.test/oauth/authorize'),
      tokenEndpoint: Uri.parse('https://example.test/oauth/token'),
      apiBaseUrl: Uri.parse('https://example.test/api/v3'),
      scopes: const ['activity:read'],
      redirectUri: Uri.parse('trailwatt://oauth/x'),
      capabilities: PlatformCapabilities(
        routeUpload: routeUpload,
        activityRead: activityRead,
      ),
    );

PlatformApiClient _clientReturning(
  Object body, {
  int status = 200,
  void Function(http.BaseRequest request)? onRequest,
}) =>
    PlatformApiClient(
      client: MockClient((req) async {
        onRequest?.call(req);
        return http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'});
      }),
    );

void main() {
  group('exportRoute', () {
    test('uploads through the platform API when it documents one', () async {
      http.BaseRequest? sent;
      final client = _clientReturning({'id': 99}, onRequest: (r) => sent = r);

      final result = await client.exportRoute(
        credentials: _credentials(routeUpload: true),
        tokens: _tokens,
        routeId: 'demo-route-01',
        name: 'Subida da Serra',
        gpx: '<gpx/>',
      );

      expect(result.outcome, RouteExportOutcome.uploaded);
      expect(sent!.url.path, '/api/v3/routes');
      expect(sent!.method, 'POST');
      expect(sent!.headers['Authorization'], 'Bearer access-1');
      expect(result.export.routeId, 'demo-route-01');
      expect(result.export.fileFormat, 'gpx');
    });

    test('falls back to a file handoff when the platform has no route API',
        () async {
      var called = false;
      final client = _clientReturning({}, onRequest: (_) => called = true);

      final result = await client.exportRoute(
        credentials: _credentials(routeUpload: false),
        tokens: _tokens,
        routeId: 'demo-route-01',
        name: 'Subida da Serra',
        gpx: '<gpx/>',
      );

      expect(result.outcome, RouteExportOutcome.fileHandoff);
      expect(result.gpx, '<gpx/>');
      expect(called, isFalse,
          reason: 'no undocumented endpoint is reached for');
      // The export is still recorded, so a later import has something to
      // match the completed activity against.
      expect(result.export.platform, ResultSource.strava);
    });
  });

  group('activityCandidates', () {
    final exportedAt = DateTime.utc(2026, 8, 20, 6);

    test('parses Strava activities and ranks them by correspondence', () async {
      Uri? requested;
      final client = _clientReturning(
        [
          {
            // Right afterwards, but half the distance.
            'id': 1,
            'start_date': '2026-08-20T07:00:00Z',
            'distance': 425.0,
            'moving_time': 300,
          },
          {
            // Right afterwards and the right distance - the best candidate.
            'id': 2,
            'start_date': '2026-08-20T07:14:00Z',
            'distance': 860.0,
            'moving_time': 180,
          },
        ],
        onRequest: (r) => requested = r.url,
      );

      final candidates = await client.activityCandidates(
        credentials: _credentials(),
        tokens: _tokens,
        since: exportedAt,
        routeDistanceKm: 0.85,
      );

      expect(requested!.path, '/api/v3/athlete/activities');
      expect(requested!.queryParameters['after'],
          '${exportedAt.millisecondsSinceEpoch ~/ 1000}');

      expect(candidates.map((c) => c.id), ['2', '1']);
      expect(candidates.first.source, ResultSource.strava);
      expect(candidates.first.distanceKm, closeTo(0.86, 1e-9));
      expect(candidates.first.durationMin, 3);
      expect(candidates.first.confidencePct,
          greaterThan(candidates.last.confidencePct));
    });

    test('reads a wrapped collection as well as a bare array', () async {
      final client = _clientReturning({
        'workouts': [
          {
            'id': 7,
            'starts': '2026-08-20T07:00:00Z',
            'workout_summary': {
              'distance_accum': 850.0,
              'duration_active_accum': 240,
            },
          },
        ],
      });

      final candidates = await client.activityCandidates(
        credentials: _credentials(platform: ResultSource.wahoo),
        tokens: _tokens,
        since: exportedAt,
        routeDistanceKm: 0.85,
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.id, '7');
      expect(candidates.single.durationMin, 4);
    });

    test('a platform with no read API says so instead of guessing', () async {
      await expectLater(
        _clientReturning([]).activityCandidates(
          credentials: _credentials(activityRead: false),
          tokens: _tokens,
          since: exportedAt,
          routeDistanceKm: 0.85,
        ),
        throwsA(isA<PlatformApiException>().having(
            (e) => e.failure, 'failure', PlatformApiFailure.notSupported)),
      );
    });

    test('a rejected token reads as unauthorized, not as an empty result',
        () async {
      await expectLater(
        _clientReturning({'message': 'Authorization Error'}, status: 401)
            .activityCandidates(
          credentials: _credentials(),
          tokens: _tokens,
          since: exportedAt,
          routeDistanceKm: 0.85,
        ),
        throwsA(isA<PlatformApiException>().having(
            (e) => e.failure, 'failure', PlatformApiFailure.unauthorized)),
      );
    });
  });

  group('match confidence', () {
    final exportedAt = DateTime.utc(2026, 8, 20, 6);

    int confidence({
      required Duration after,
      required double distanceKm,
      double routeKm = 10,
    }) =>
        PlatformApiClient.matchConfidencePct(
          startedAt: exportedAt.add(after),
          exportedAt: exportedAt,
          activityDistanceKm: distanceKm,
          routeDistanceKm: routeKm,
        );

    test('a prompt ride at the right distance is a full match', () {
      expect(confidence(after: const Duration(hours: 1), distanceKm: 10), 100);
    });

    test('a ride that started before the export cannot be the one', () {
      expect(confidence(after: const Duration(hours: -1), distanceKm: 10), 0);
    });

    test('arrival time alone never carries the score', () {
      // Immediately after the export, but nothing like the route's distance -
      // spec 002 Requirement 7 forbids letting timing decide on its own.
      expect(confidence(after: const Duration(minutes: 5), distanceKm: 90),
          lessThan(60));
    });

    test('distance alone never carries it either', () {
      expect(confidence(after: const Duration(days: 5), distanceKm: 10),
          lessThan(60));
    });

    test('an unknown distance contributes nothing rather than agreeing', () {
      expect(confidence(after: const Duration(hours: 1), distanceKm: 0), 50);
    });
  });
}
