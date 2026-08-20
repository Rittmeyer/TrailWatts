import 'result_source.dart';

enum PlatformConnectionState {
  connected,
  expired,
  disconnected,

  /// This build carries no client id for the platform, so it cannot connect
  /// at all. Distinct from `disconnected`, which is a rider choice: telling
  /// the two apart is what stops the UI offering a Connect button that could
  /// only ever fail.
  notConfigured,
}

enum ImportAttemptStatus { matched, noMatch, manual }

class PlatformConnection {
  final ResultSource platform;
  final PlatformConnectionState state;
  final List<String> scopes;
  final DateTime? connectedAt;

  const PlatformConnection({
    required this.platform,
    required this.state,
    this.scopes = const [],
    this.connectedAt,
  });
}

class ExportedRoute {
  final String id;
  final String routeId;
  final ResultSource platform;
  final String fileFormat;
  final DateTime exportedAt;

  const ExportedRoute({
    required this.id,
    required this.routeId,
    required this.platform,
    required this.fileFormat,
    required this.exportedAt,
  });
}

class ActivityCandidate {
  final String id;
  final ResultSource source;
  final DateTime startedAt;
  final DateTime? eventReceivedAt;
  final double distanceKm;
  final int durationMin;
  final int confidencePct;

  const ActivityCandidate({
    required this.id,
    required this.source,
    required this.startedAt,
    required this.distanceKm,
    required this.durationMin,
    required this.confidencePct,
    this.eventReceivedAt,
  }) : assert(confidencePct >= 0 && confidencePct <= 100);
}

class ImportAttempt {
  final String id;
  final String exportedRouteId;
  final ImportAttemptStatus status;
  final List<ActivityCandidate> candidates;
  final String? confirmedActivityId;
  final DateTime createdAt;

  const ImportAttempt({
    required this.id,
    required this.exportedRouteId,
    required this.status,
    required this.candidates,
    required this.createdAt,
    this.confirmedActivityId,
  });
}
