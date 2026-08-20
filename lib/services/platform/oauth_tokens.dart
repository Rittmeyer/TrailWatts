/// An access token as the platform issued it.
///
/// [expiresAt] is stored as an absolute instant rather than the `expires_in`
/// seconds the endpoint returns, because a duration is only meaningful next
/// to the moment it was received - and that moment is gone by the time
/// anything asks whether the token is still good.
class OAuthTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> scopes;

  const OAuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.scopes = const [],
  });

  /// Treat a token that is about to expire as already expired: a request that
  /// starts inside this window can easily arrive after the real expiry.
  static const _clockSkew = Duration(seconds: 30);

  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    // No expiry advertised: valid until the platform refuses it.
    if (expiry == null) return false;
    return !expiry.isAfter(now.add(_clockSkew));
  }

  bool get isExpired => isExpiredAt(DateTime.now());

  /// A token with no refresh token cannot be renewed - the rider has to
  /// authorize again, and the UI needs to distinguish that from a renewable
  /// expiry rather than silently failing later.
  bool get canRefresh => (refreshToken ?? '').isNotEmpty;

  /// Parses a token endpoint response.
  ///
  /// Handles both spellings in the wild: the standard `expires_in` (seconds
  /// from now) and Strava's `expires_at` (absolute unix seconds).
  factory OAuthTokens.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final accessToken = json['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Token response carried no access_token.');
    }

    DateTime? expiresAt;
    final absolute = json['expires_at'];
    final relative = json['expires_in'];
    if (absolute is num) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(absolute.round() * 1000,
          isUtc: true);
    } else if (relative is num) {
      expiresAt =
          (now ?? DateTime.now()).add(Duration(seconds: relative.round()));
    }

    final scope = json['scope'];
    return OAuthTokens(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: expiresAt,
      scopes: switch (scope) {
        String s when s.isNotEmpty => s.split(RegExp(r'[ ,]+')),
        List l => l.map((e) => '$e').toList(),
        _ => const [],
      },
    );
  }

  OAuthTokens mergedWith(OAuthTokens refreshed) => OAuthTokens(
        accessToken: refreshed.accessToken,
        // A refresh response may omit the refresh token, meaning "keep using
        // the one you have"; dropping it would strand the connection.
        refreshToken: refreshed.refreshToken ?? refreshToken,
        expiresAt: refreshed.expiresAt,
        scopes: refreshed.scopes.isEmpty ? scopes : refreshed.scopes,
      );
}
