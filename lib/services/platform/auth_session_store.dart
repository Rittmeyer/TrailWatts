import 'dart:convert';

import '../../models/result_source.dart';
import 'platform_oauth_service.dart';

import 'auth_session_store_io.dart'
    if (dart.library.html) 'auth_session_store_web.dart' as impl;

/// Where a half-finished authorization waits while the rider is away on the
/// platform's consent page.
///
/// It has to outlive the app's own memory. On the web the redirect reloads
/// the page, and on a phone the app can be evicted while the browser is in
/// front - either way the PKCE verifier and the state token would be gone
/// by the time the answer arrives, and the connection would fail with
/// "nothing was pending" through no fault of the rider.
///
/// What is stored is short-lived by construction: a verifier is worthless
/// once redeemed, and worthless on its own without the authorization code.
/// Tokens are a different matter and are deliberately not kept here.
abstract class AuthSessionStore {
  void save(ResultSource platform, PendingAuthorization pending);

  /// Reads and forgets in one step: an authorization is good for exactly one
  /// redirect, so leaving it behind would let a replayed URL be accepted.
  PendingAuthorization? take(ResultSource platform);

  PendingAuthorization? peek(ResultSource platform);

  void clear(ResultSource platform);

  /// The platform whose pending authorization issued [state], or null.
  ///
  /// Matching on state rather than on the redirect's path means the handler
  /// does not have to know how each platform shapes its callback URL, and a
  /// redirect carrying someone else's state is not attributed to anybody.
  ResultSource? platformForState(String state);

  /// The best store for this platform: session storage on the web, memory
  /// everywhere else.
  factory AuthSessionStore.forPlatform() => impl.createAuthSessionStore();
}

/// Serialisation shared by every implementation, so a session written by one
/// is readable by another.
String encodePending(PendingAuthorization pending) => jsonEncode({
      'url': pending.authorizationUrl.toString(),
      'verifier': pending.codeVerifier,
      'state': pending.state,
    });

PendingAuthorization? decodePending(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw);
    if (map is! Map) return null;
    final url = Uri.tryParse('${map['url']}');
    final verifier = '${map['verifier']}';
    final state = '${map['state']}';
    if (url == null || verifier.isEmpty || state.isEmpty) return null;
    return PendingAuthorization(
      authorizationUrl: url,
      codeVerifier: verifier,
      state: state,
    );
  } catch (_) {
    return null;
  }
}

/// Kept for the whole app run and no longer. What the app did before this
/// existed, and still the right answer anywhere the process survives the
/// round trip.
class InMemoryAuthSessionStore implements AuthSessionStore {
  final Map<ResultSource, PendingAuthorization> _pending = {};

  @override
  void save(ResultSource platform, PendingAuthorization pending) =>
      _pending[platform] = pending;

  @override
  PendingAuthorization? take(ResultSource platform) =>
      _pending.remove(platform);

  @override
  PendingAuthorization? peek(ResultSource platform) => _pending[platform];

  @override
  void clear(ResultSource platform) => _pending.remove(platform);

  @override
  ResultSource? platformForState(String state) {
    for (final entry in _pending.entries) {
      if (entry.value.state == state) return entry.key;
    }
    return null;
  }
}
