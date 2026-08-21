// This file is only ever imported behind `if (dart.library.html)`, so the
// web-only import cannot reach an Android, iOS or desktop build. The lint
// cannot see the conditional import that guards it.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../models/result_source.dart';
import 'auth_session_store.dart';
import 'platform_oauth_service.dart';

/// Session storage, because the OAuth redirect reloads the page and takes
/// the app's memory with it.
///
/// Session storage rather than local storage on purpose: it dies with the
/// tab, which is the longest a half-finished authorization should ever live.
class WebAuthSessionStore implements AuthSessionStore {
  static const _prefix = 'trailwatt.oauth.';

  html.Storage get _storage => html.window.sessionStorage;

  String _key(ResultSource platform) => '$_prefix${platform.name}';

  @override
  void save(ResultSource platform, PendingAuthorization pending) {
    try {
      _storage[_key(platform)] = encodePending(pending);
    } catch (_) {
      // A browser with site data blocked still authorizes fine as long as
      // the tab is not reloaded; failing the whole connect here would be
      // worse than losing the fallback.
    }
  }

  @override
  PendingAuthorization? take(ResultSource platform) {
    final pending = peek(platform);
    clear(platform);
    return pending;
  }

  @override
  PendingAuthorization? peek(ResultSource platform) {
    try {
      return decodePending(_storage[_key(platform)]);
    } catch (_) {
      return null;
    }
  }

  @override
  void clear(ResultSource platform) {
    try {
      _storage.remove(_key(platform));
    } catch (_) {}
  }

  @override
  ResultSource? platformForState(String state) {
    for (final platform in ResultSource.values) {
      if (peek(platform)?.state == state) return platform;
    }
    return null;
  }
}

AuthSessionStore createAuthSessionStore() => WebAuthSessionStore();
