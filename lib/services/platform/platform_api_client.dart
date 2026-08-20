import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/platform_integration.dart';
import '../../models/result_source.dart';
import 'oauth_tokens.dart';
import 'platform_credentials.dart';

/// Why a platform call did not produce what was asked for. Codes, not
/// sentences - the UI owns the wording.
enum PlatformApiFailure {
  /// The platform is not connected, or its token expired and could not be
  /// renewed. The rider has to authorize again.
  unauthorized,

  /// The platform has no documented endpoint for this operation. Not an
  /// error the rider can retry - the app falls back to the file handoff or
  /// to manual entry instead of inventing a call.
  notSupported,

  network,
  invalidResponse,
}

class PlatformApiException implements Exception {
  final PlatformApiFailure failure;
  final String? detail;

  const PlatformApiException(this.failure, {this.detail});

  @override
  String toString() => 'PlatformApiException(${failure.name}, $detail)';
}

/// How an export actually reached (or did not reach) the platform.
enum RouteExportOutcome {
  /// Pushed through the platform's own documented route endpoint.
  uploaded,

  /// The platform has no route-upload API, so the rider gets the GPX to put
  /// through the platform's own importer. Spec 002 calls this out explicitly
  /// as the compliant alternative to a scraped upload.
  fileHandoff,
}

class RouteExportResult {
  final ExportedRoute export;
  final RouteExportOutcome outcome;

  /// The generated file. Present either way: on a handoff it is what the
  /// rider imports, and on an upload it is what was sent.
  final String gpx;

  const RouteExportResult({
    required this.export,
    required this.outcome,
    required this.gpx,
  });
}

/// Talks to one connected platform's official API.
///
/// Every endpoint path below is PROVISIONAL, in the same sense as the OSRM
/// defaults in `routing_service.dart` and the generic HR bands in
/// `models/zone.dart`: they are the documented public shapes at the time of
/// writing, and DECISIONS_REQUIRED.md keeps "Platform API capabilities" open
/// pending per-platform verification. What is NOT provisional is the rule
/// they encode - when a platform has no documented endpoint for something,
/// this client reports `notSupported` rather than reaching for an
/// undocumented one.
class PlatformApiClient {
  final http.Client _client;
  final Duration timeout;

  PlatformApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// Sends a suggested route to the platform, or reports that it has to be
  /// handed off as a file. [routeId] and the returned [ExportedRoute] are
  /// what a later import matches the completed activity against
  /// (spec 002, Requirement 3).
  Future<RouteExportResult> exportRoute({
    required PlatformCredentials credentials,
    required OAuthTokens tokens,
    required String routeId,
    required String name,
    required String gpx,
    DateTime? now,
  }) async {
    final exportedAt = now ?? DateTime.now();
    final export = ExportedRoute(
      id: 'export-$routeId-${exportedAt.millisecondsSinceEpoch}',
      routeId: routeId,
      platform: credentials.platform,
      fileFormat: 'gpx',
      exportedAt: exportedAt,
    );

    if (!credentials.capabilities.routeUpload) {
      return RouteExportResult(
        export: export,
        outcome: RouteExportOutcome.fileHandoff,
        gpx: gpx,
      );
    }

    final base = credentials.apiBaseUrl;
    final uri = base.replace(path: '${base.path}/routes');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${tokens.accessToken}'
      ..fields['name'] = name
      ..files.add(http.MultipartFile.fromString(
        'file',
        gpx,
        filename: '${_slug(name)}.gpx',
      ));

    final response = await _send(() async =>
        http.Response.fromStream(await _client.send(request)).timeout(timeout));

    _throwForStatus(response);
    return RouteExportResult(
      export: export,
      outcome: RouteExportOutcome.uploaded,
      gpx: gpx,
    );
  }

  /// Reads back the rider's activities since [since], as candidates for the
  /// route that was exported.
  ///
  /// This is deliberately a narrow window around one export, not a history
  /// import: Constitution Article II and spec 002's scope both draw the line
  /// at the single matching activity.
  Future<List<ActivityCandidate>> activityCandidates({
    required PlatformCredentials credentials,
    required OAuthTokens tokens,
    required DateTime since,
    required double routeDistanceKm,
    DateTime? now,
  }) async {
    if (!credentials.capabilities.activityRead) {
      throw const PlatformApiException(PlatformApiFailure.notSupported);
    }

    final uri = _activitiesUri(credentials, since);
    final response = await _send(() => _client.get(uri, headers: {
          'Authorization': 'Bearer ${tokens.accessToken}',
          'Accept': 'application/json',
        }).timeout(timeout));

    _throwForStatus(response);

    final decoded = _decode(response.body);
    final entries = switch (decoded) {
      List list => list,
      // Wahoo wraps the collection; Strava returns a bare array.
      Map map when map['workouts'] is List => map['workouts'] as List,
      Map map when map['activities'] is List => map['activities'] as List,
      _ => throw const PlatformApiException(PlatformApiFailure.invalidResponse),
    };

    final received = now ?? DateTime.now();
    final candidates = <ActivityCandidate>[];
    for (final entry in entries) {
      if (entry is! Map) continue;
      final candidate = _toCandidate(
        entry.cast<String, dynamic>(),
        platform: credentials.platform,
        exportedAt: since,
        routeDistanceKm: routeDistanceKm,
        receivedAt: received,
      );
      if (candidate != null) candidates.add(candidate);
    }

    // Highest-confidence first, which is the order `ImportAttempt` documents
    // for its candidate list.
    candidates.sort((a, b) => b.confidencePct.compareTo(a.confidencePct));
    return candidates;
  }

  Uri _activitiesUri(PlatformCredentials credentials, DateTime since) {
    final base = credentials.apiBaseUrl;
    return switch (credentials.platform) {
      ResultSource.strava => base.replace(
          path: '${base.path}/athlete/activities',
          queryParameters: {
            'after': '${since.toUtc().millisecondsSinceEpoch ~/ 1000}',
            'per_page': '30',
          },
        ),
      _ => base.replace(
          path: '${base.path}/workouts',
          queryParameters: {'start_time': since.toUtc().toIso8601String()},
        ),
    };
  }

  ActivityCandidate? _toCandidate(
    Map<String, dynamic> json, {
    required ResultSource platform,
    required DateTime exportedAt,
    required double routeDistanceKm,
    required DateTime receivedAt,
  }) {
    final id = json['id'] ?? json['activity_id'];
    final startedRaw =
        json['start_date'] ?? json['starts'] ?? json['start_time'];
    if (id == null || startedRaw is! String) return null;

    final startedAt = DateTime.tryParse(startedRaw);
    if (startedAt == null) return null;

    // Strava reports metres; Wahoo's workout summary reports metres too.
    final distanceM = _toDouble(json['distance'] ??
        (json['workout_summary'] is Map
            ? (json['workout_summary'] as Map)['distance_accum']
            : null));
    final durationSec = _toDouble(json['moving_time'] ??
        json['duration'] ??
        (json['workout_summary'] is Map
            ? (json['workout_summary'] as Map)['duration_active_accum']
            : null));

    final distanceKm = (distanceM ?? 0) / 1000;
    return ActivityCandidate(
      id: '$id',
      source: platform,
      startedAt: startedAt,
      eventReceivedAt: receivedAt,
      distanceKm: distanceKm,
      durationMin: ((durationSec ?? 0) / 60).round(),
      confidencePct: matchConfidencePct(
        startedAt: startedAt,
        exportedAt: exportedAt,
        activityDistanceKm: distanceKm,
        routeDistanceKm: routeDistanceKm,
      ),
    );
  }

  /// How well an activity corresponds to the exported route.
  ///
  /// Spec 002 Requirement 7 is explicit that arrival time alone MUST NOT
  /// decide correctness, so this weighs two independent signals: how soon
  /// after the export the ride started, and how closely its distance matches
  /// the route's. Neither can carry the score on its own.
  static int matchConfidencePct({
    required DateTime startedAt,
    required DateTime exportedAt,
    required double activityDistanceKm,
    required double routeDistanceKm,
  }) {
    // A ride that started before the route was exported cannot be the ride
    // that route produced.
    final elapsed = startedAt.difference(exportedAt);
    if (elapsed.isNegative) return 0;

    // Full marks inside 6 hours, fading to nothing at 48.
    const prompt = Duration(hours: 6);
    const stale = Duration(hours: 48);
    final timeScore = elapsed <= prompt
        ? 1.0
        : elapsed >= stale
            ? 0.0
            : 1 -
                (elapsed - prompt).inMinutes /
                    (stale - prompt).inMinutes.toDouble();

    // Distance within 10% is a full match, fading to nothing at 100% off.
    final double distanceScore;
    if (routeDistanceKm <= 0 || activityDistanceKm <= 0) {
      // Unknown is not "close" - it simply contributes nothing, rather than
      // being scored as agreement.
      distanceScore = 0;
    } else {
      final deviation =
          (activityDistanceKm - routeDistanceKm).abs() / routeDistanceKm;
      distanceScore = deviation <= 0.10
          ? 1.0
          : deviation >= 1.0
              ? 0.0
              : 1 - (deviation - 0.10) / 0.90;
    }

    return ((timeScore * 0.5 + distanceScore * 0.5) * 100)
        .round()
        .clamp(0, 100);
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on PlatformApiException {
      rethrow;
    } catch (e) {
      throw PlatformApiException(PlatformApiFailure.network,
          detail: e.toString());
    }
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw PlatformApiException(PlatformApiFailure.unauthorized,
          detail: 'HTTP ${response.statusCode}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlatformApiException(
        PlatformApiFailure.network,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      throw PlatformApiException(PlatformApiFailure.invalidResponse,
          detail: e.toString());
    }
  }

  static double? _toDouble(Object? value) => switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
