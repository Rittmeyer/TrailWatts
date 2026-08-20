import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'oauth_tokens.dart';
import 'platform_credentials.dart';

/// Why an authorization did not complete. A code, not a sentence: this
/// service is engine-side, so the wording belongs to the UI - the same split
/// `RouteDegradation` uses in `routing_service.dart`.
enum PlatformAuthFailure {
  /// This build has no client id for the platform, so it genuinely cannot
  /// connect. Not an error to retry - a build configuration to supply.
  notConfigured,

  /// The rider declined on the platform's consent screen.
  denied,

  /// The redirect's `state` did not match the one we sent. Either a stale
  /// redirect or a forged one; either way the code is not exchanged.
  stateMismatch,

  /// No in-flight authorization matches this redirect.
  noPendingAuthorization,

  /// The redirect carried no authorization code.
  missingCode,

  /// The token endpoint could not be reached, or refused.
  network,

  /// The token endpoint answered with something that was not a token.
  invalidResponse,
}

class PlatformAuthException implements Exception {
  final PlatformAuthFailure failure;

  /// The platform's own error text, when it sent one. Diagnostic only - never
  /// shown to the rider as-is, since it is neither localized nor ours.
  final String? detail;

  const PlatformAuthException(this.failure, {this.detail});

  @override
  String toString() => 'PlatformAuthException(${failure.name}, $detail)';
}

/// One in-flight authorization: the PKCE verifier and the `state` we sent,
/// held until the rider comes back from the platform's consent screen.
class PendingAuthorization {
  final Uri authorizationUrl;
  final String codeVerifier;
  final String state;

  const PendingAuthorization({
    required this.authorizationUrl,
    required this.codeVerifier,
    required this.state,
  });
}

/// Authorization Code flow with PKCE (RFC 7636), which is what a mobile app
/// is supposed to use: the app proves it started the flow by presenting the
/// verifier, so no client secret has to ship inside the binary.
class PlatformOAuthService {
  final http.Client _client;
  final Duration timeout;
  final Random _random;

  PlatformOAuthService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    Random? random,
  })  : _client = client ?? http.Client(),
        // Random.secure() for the real verifier/state; tests inject a seeded
        // Random so an assertion can name the exact value.
        _random = random ?? Random.secure();

  /// Builds the URL the rider opens to approve the connection, along with the
  /// PKCE verifier that must be kept until they come back.
  PendingAuthorization beginAuthorization(PlatformCredentials credentials) {
    if (!credentials.isConfigured) {
      throw const PlatformAuthException(PlatformAuthFailure.notConfigured);
    }

    final verifier = _randomToken(64);
    final state = _randomToken(24);
    final challenge = codeChallengeFor(verifier);

    final url = credentials.authorizationEndpoint.replace(queryParameters: {
      ...credentials.authorizationEndpoint.queryParameters,
      ...credentials.extraAuthorizationParams,
      'client_id': credentials.clientId,
      'redirect_uri': credentials.redirectUri.toString(),
      'response_type': 'code',
      'scope': credentials.scopes.join(' '),
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    return PendingAuthorization(
      authorizationUrl: url,
      codeVerifier: verifier,
      state: state,
    );
  }

  /// Completes the flow from the URL the platform redirected back to.
  ///
  /// [pending] is the authorization this redirect is supposed to answer;
  /// a mismatched `state` is refused rather than exchanged.
  Future<OAuthTokens> completeAuthorization({
    required PlatformCredentials credentials,
    required PendingAuthorization pending,
    required Uri redirect,
  }) async {
    final params = {
      ...redirect.queryParameters,
      // Some providers return the parameters in the fragment instead.
      if (redirect.fragment.isNotEmpty)
        ...Uri.splitQueryString(redirect.fragment),
    };

    final error = params['error'];
    if (error != null) {
      throw PlatformAuthException(
        error == 'access_denied'
            ? PlatformAuthFailure.denied
            : PlatformAuthFailure.invalidResponse,
        detail: params['error_description'] ?? error,
      );
    }

    if (params['state'] != pending.state) {
      throw const PlatformAuthException(PlatformAuthFailure.stateMismatch);
    }

    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw const PlatformAuthException(PlatformAuthFailure.missingCode);
    }

    return _postToken(credentials, {
      'client_id': credentials.clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': credentials.redirectUri.toString(),
      'code_verifier': pending.codeVerifier,
    });
  }

  /// Renews an expired token. Never invents a session: without a refresh
  /// token this throws, and the rider is asked to authorize again.
  Future<OAuthTokens> refresh({
    required PlatformCredentials credentials,
    required OAuthTokens tokens,
  }) async {
    if (!tokens.canRefresh) {
      throw const PlatformAuthException(PlatformAuthFailure.missingCode);
    }
    final refreshed = await _postToken(credentials, {
      'client_id': credentials.clientId,
      'grant_type': 'refresh_token',
      'refresh_token': tokens.refreshToken!,
    });
    return tokens.mergedWith(refreshed);
  }

  Future<OAuthTokens> _postToken(
    PlatformCredentials credentials,
    Map<String, String> body,
  ) async {
    http.Response response;
    try {
      response = await _client
          .post(
            credentials.tokenEndpoint,
            headers: const {'Accept': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      throw PlatformAuthException(PlatformAuthFailure.network,
          detail: e.toString());
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlatformAuthException(
        PlatformAuthFailure.network,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Token response was not an object.');
      }
      return OAuthTokens.fromJson(decoded);
    } on PlatformAuthException {
      rethrow;
    } catch (e) {
      throw PlatformAuthException(PlatformAuthFailure.invalidResponse,
          detail: e.toString());
    }
  }

  /// S256: base64url(sha256(verifier)), unpadded, per RFC 7636 §4.2.
  static String codeChallengeFor(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');

  /// PKCE verifiers are drawn from the unreserved set in RFC 7636 §4.1, so
  /// the value survives being put in a query string untouched.
  static const _unreserved =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  String _randomToken(int length) => String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => _unreserved.codeUnitAt(_random.nextInt(_unreserved.length)),
        ),
      );
}
