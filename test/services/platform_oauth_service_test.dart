import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailwatt/models/result_source.dart';
import 'package:trailwatt/services/platform/oauth_tokens.dart';
import 'package:trailwatt/services/platform/platform_credentials.dart';
import 'package:trailwatt/services/platform/platform_oauth_service.dart';

PlatformCredentials _credentials({String clientId = 'client-123'}) =>
    PlatformCredentials(
      platform: ResultSource.strava,
      clientId: clientId,
      authorizationEndpoint: Uri.parse('https://example.test/oauth/authorize'),
      tokenEndpoint: Uri.parse('https://example.test/oauth/token'),
      apiBaseUrl: Uri.parse('https://example.test/api/v3'),
      scopes: const ['activity:read'],
      redirectUri: Uri.parse('trailwatt://oauth/strava'),
      extraAuthorizationParams: const {'approval_prompt': 'auto'},
    );

PlatformOAuthService _serviceReturning(
  Object body, {
  int status = 200,
  void Function(http.Request request)? onRequest,
}) =>
    PlatformOAuthService(
      client: MockClient((req) async {
        onRequest?.call(req);
        return http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'});
      }),
    );

void main() {
  group('PKCE', () {
    test('the challenge matches the RFC 7636 worked example', () {
      // Appendix B of RFC 7636 - if this ever drifts, every platform's
      // authorization breaks, so it is pinned to the spec's own vector.
      expect(
        PlatformOAuthService.codeChallengeFor(
            'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('the verifier is drawn from the unreserved set only', () {
      final pending = PlatformOAuthService().beginAuthorization(_credentials());
      expect(
          pending.codeVerifier, matches(RegExp(r'^[A-Za-z0-9\-._~]{43,128}$')));
    });
  });

  group('beginAuthorization', () {
    test('builds the authorize URL with PKCE and the platform extras', () {
      final pending = PlatformOAuthService().beginAuthorization(_credentials());
      final q = pending.authorizationUrl.queryParameters;

      expect(pending.authorizationUrl.host, 'example.test');
      expect(q['client_id'], 'client-123');
      expect(q['response_type'], 'code');
      expect(q['redirect_uri'], 'trailwatt://oauth/strava');
      expect(q['scope'], 'activity:read');
      expect(q['code_challenge_method'], 'S256');
      expect(q['code_challenge'],
          PlatformOAuthService.codeChallengeFor(pending.codeVerifier));
      expect(q['state'], pending.state);
      expect(q['approval_prompt'], 'auto');
      // A public client proves itself with PKCE; no secret ships in the app.
      expect(q.containsKey('client_secret'), isFalse);
    });

    test('a build with no client id cannot start a flow', () {
      expect(
        () => PlatformOAuthService()
            .beginAuthorization(_credentials(clientId: '')),
        throwsA(isA<PlatformAuthException>().having(
            (e) => e.failure, 'failure', PlatformAuthFailure.notConfigured)),
      );
    });
  });

  group('completeAuthorization', () {
    test('exchanges the code, sending the verifier and no secret', () async {
      http.Request? sent;
      final service = _serviceReturning(
        {
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'expires_in': 3600,
          'scope': 'activity:read',
        },
        onRequest: (req) => sent = req,
      );
      final pending = service.beginAuthorization(_credentials());

      final tokens = await service.completeAuthorization(
        credentials: _credentials(),
        pending: pending,
        redirect: Uri.parse(
            'trailwatt://oauth/strava?code=abc&state=${pending.state}'),
      );

      expect(tokens.accessToken, 'access-1');
      expect(tokens.refreshToken, 'refresh-1');
      expect(tokens.scopes, ['activity:read']);
      expect(tokens.isExpired, isFalse);

      final body = Uri.splitQueryString(sent!.body);
      expect(body['grant_type'], 'authorization_code');
      expect(body['code'], 'abc');
      expect(body['code_verifier'], pending.codeVerifier);
      expect(body.containsKey('client_secret'), isFalse);
    });

    test('a mismatched state is refused, not exchanged', () async {
      var exchanged = false;
      final service = _serviceReturning({'access_token': 'nope'},
          onRequest: (_) => exchanged = true);
      final pending = service.beginAuthorization(_credentials());

      await expectLater(
        service.completeAuthorization(
          credentials: _credentials(),
          pending: pending,
          redirect: Uri.parse(
              'trailwatt://oauth/strava?code=abc&state=someone-elses'),
        ),
        throwsA(isA<PlatformAuthException>().having(
            (e) => e.failure, 'failure', PlatformAuthFailure.stateMismatch)),
      );
      expect(exchanged, isFalse, reason: 'the code must never be sent');
    });

    test('a declined consent screen reads as denied, not as a network error',
        () async {
      final service = _serviceReturning({});
      final pending = service.beginAuthorization(_credentials());

      await expectLater(
        service.completeAuthorization(
          credentials: _credentials(),
          pending: pending,
          redirect: Uri.parse(
              'trailwatt://oauth/strava?error=access_denied&state=${pending.state}'),
        ),
        throwsA(isA<PlatformAuthException>()
            .having((e) => e.failure, 'failure', PlatformAuthFailure.denied)),
      );
    });

    test('a redirect with no code is reported rather than half-accepted',
        () async {
      final service = _serviceReturning({});
      final pending = service.beginAuthorization(_credentials());

      await expectLater(
        service.completeAuthorization(
          credentials: _credentials(),
          pending: pending,
          redirect:
              Uri.parse('trailwatt://oauth/strava?state=${pending.state}'),
        ),
        throwsA(isA<PlatformAuthException>().having(
            (e) => e.failure, 'failure', PlatformAuthFailure.missingCode)),
      );
    });

    test('a token endpoint that refuses is a network failure, not a token',
        () async {
      final service =
          _serviceReturning({'error': 'invalid_grant'}, status: 400);
      final pending = service.beginAuthorization(_credentials());

      await expectLater(
        service.completeAuthorization(
          credentials: _credentials(),
          pending: pending,
          redirect: Uri.parse(
              'trailwatt://oauth/strava?code=abc&state=${pending.state}'),
        ),
        throwsA(isA<PlatformAuthException>()
            .having((e) => e.failure, 'failure', PlatformAuthFailure.network)),
      );
    });
  });

  group('refresh', () {
    test('keeps the existing refresh token when the response omits one',
        () async {
      final service = _serviceReturning({
        'access_token': 'access-2',
        'expires_in': 3600,
      });

      final refreshed = await service.refresh(
        credentials: _credentials(),
        tokens: const OAuthTokens(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          scopes: ['activity:read'],
        ),
      );

      expect(refreshed.accessToken, 'access-2');
      expect(refreshed.refreshToken, 'refresh-1',
          reason: 'dropping it would strand the connection');
      expect(refreshed.scopes, ['activity:read']);
    });

    test('a session with no refresh token cannot be renewed', () async {
      await expectLater(
        PlatformOAuthService().refresh(
          credentials: _credentials(),
          tokens: const OAuthTokens(accessToken: 'access-1'),
        ),
        throwsA(isA<PlatformAuthException>()),
      );
    });
  });

  group('OAuthTokens', () {
    test('reads both expires_in and Strava-style absolute expires_at', () {
      final now = DateTime.utc(2026, 8, 20, 12);

      final relative = OAuthTokens.fromJson(
          {'access_token': 'a', 'expires_in': 60},
          now: now);
      expect(relative.expiresAt, now.add(const Duration(seconds: 60)));

      final absolute = OAuthTokens.fromJson({
        'access_token': 'a',
        'expires_at':
            now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      expect(absolute.expiresAt, now.add(const Duration(hours: 1)));
    });

    test('a token about to expire already counts as expired', () {
      final now = DateTime.utc(2026, 8, 20, 12);
      final tokens = OAuthTokens(
        accessToken: 'a',
        expiresAt: now.add(const Duration(seconds: 5)),
      );
      // A request started inside the skew window would arrive after expiry.
      expect(tokens.isExpiredAt(now), isTrue);
      expect(
        OAuthTokens(
                accessToken: 'a', expiresAt: now.add(const Duration(hours: 1)))
            .isExpiredAt(now),
        isFalse,
      );
    });

    test('a token with no expiry is valid until the platform refuses it', () {
      expect(const OAuthTokens(accessToken: 'a').isExpired, isFalse);
    });

    test('a response with no access token is not a token', () {
      expect(() => OAuthTokens.fromJson({'refresh_token': 'r'}),
          throwsA(isA<FormatException>()));
    });
  });
}
