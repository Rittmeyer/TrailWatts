import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Where a rider-placed point actually landed once matched against the road
/// network. [requested] is what the finger dragged to, [point] is the nearest
/// routable position. When [onRoad] is false nothing could be matched and
/// [point] falls back to [requested] - the UI must say so rather than pretend
/// the point sits on a road.
class SnappedPoint {
  final LatLng requested;
  final LatLng point;
  final double offsetM;
  final bool onRoad;

  const SnappedPoint({
    required this.requested,
    required this.point,
    required this.offsetM,
    required this.onRoad,
  });

  const SnappedPoint.unmatched(this.requested)
      : point = requested,
        offsetM = 0,
        onRoad = false;
}

/// A path through [waypoints]. When [followsRoads] is true the [polyline] is
/// the real road geometry returned by the routing engine and [distanceM] /
/// [movingTime] come from it. When it is false the polyline is a straight
/// line between the waypoints, [movingTime] is null, and [degradedReason]
/// explains why - the rider is never shown a road-accurate number that was
/// actually a guess (see AUDIT_RESULT.md, "never hide uncertainty").
class RoutedPath {
  final List<LatLng> polyline;
  final List<LatLng> waypoints;
  final double distanceM;
  final Duration? movingTime;
  final bool followsRoads;
  final String? degradedReason;

  const RoutedPath({
    required this.polyline,
    required this.waypoints,
    required this.distanceM,
    required this.followsRoads,
    this.movingTime,
    this.degradedReason,
  });

  double get distanceKm => distanceM / 1000;
}

/// Road-network access: snapping a point onto a road, and connecting
/// waypoints along real roads.
///
/// Kept behind an interface because the map/road data source is still an open
/// P0 decision (see DECISIONS_REQUIRED.md) - swapping OSRM for Valhalla,
/// GraphHopper or a commercial provider must not touch the screens.
abstract class RoutingService {
  Future<SnappedPoint> snapToRoad(LatLng point);

  Future<RoutedPath> routeThrough(List<LatLng> waypoints);
}

/// Talks to any OSRM-compatible server.
///
/// [baseUrl] defaults to the public OSRM demo, which is rate-limited and only
/// serves the **driving** profile. A cycling app must point this at its own
/// instance built with the bicycle profile before release - that is the
/// "candidate map/road data source" decision in DECISIONS_REQUIRED.md, and it
/// is also where the OSM licensing review applies.
class OsrmRoutingService implements RoutingService {
  /// Override at build time:
  /// `flutter run --dart-define=TRAILWATT_OSRM_URL=https://osrm.internal`
  static const defaultBaseUrl = String.fromEnvironment(
    'TRAILWATT_OSRM_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  /// `driving` is all the public demo serves; a self-hosted instance built
  /// with the bicycle profile should be pointed at with
  /// `--dart-define=TRAILWATT_OSRM_PROFILE=cycling`.
  static const defaultProfile = String.fromEnvironment(
    'TRAILWATT_OSRM_PROFILE',
    defaultValue: 'driving',
  );

  final String baseUrl;
  final String profile;
  final Duration timeout;
  final http.Client _client;

  OsrmRoutingService({
    this.baseUrl = defaultBaseUrl,
    this.profile = defaultProfile,
    this.timeout = const Duration(seconds: 8),
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _distance = Distance();

  @override
  Future<SnappedPoint> snapToRoad(LatLng point) async {
    try {
      final uri = Uri.parse('$baseUrl/nearest/v1/$profile/'
          '${point.longitude},${point.latitude}?number=1');
      final body = await _getJson(uri);
      final waypoints = body['waypoints'] as List?;
      if (body['code'] != 'Ok' || waypoints == null || waypoints.isEmpty) {
        return SnappedPoint.unmatched(point);
      }
      final w = waypoints.first as Map<String, dynamic>;
      final loc = (w['location'] as List).cast<num>();
      final snapped = LatLng(loc[1].toDouble(), loc[0].toDouble());
      return SnappedPoint(
        requested: point,
        point: snapped,
        offsetM: (w['distance'] as num?)?.toDouble() ??
            _distance.as(LengthUnit.Meter, point, snapped).toDouble(),
        onRoad: true,
      );
    } catch (_) {
      return SnappedPoint.unmatched(point);
    }
  }

  @override
  Future<RoutedPath> routeThrough(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return RoutedPath(
        polyline: List.of(waypoints),
        waypoints: List.of(waypoints),
        distanceM: 0,
        followsRoads: false,
        degradedReason: 'Marque pelo menos dois pontos para tracar a rota.',
      );
    }
    try {
      final coords =
          waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse('$baseUrl/route/v1/$profile/$coords'
          '?overview=full&geometries=geojson');
      final body = await _getJson(uri);
      final routes = body['routes'] as List?;
      if (body['code'] != 'Ok' || routes == null || routes.isEmpty) {
        return straightLine(waypoints,
            reason: 'Nenhuma rota encontrada na malha viaria entre estes '
                'pontos.');
      }
      final route = routes.first as Map<String, dynamic>;
      final line = (route['geometry']['coordinates'] as List)
          .cast<List>()
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList(growable: false);
      return RoutedPath(
        polyline: line,
        waypoints: List.of(waypoints),
        distanceM: (route['distance'] as num).toDouble(),
        movingTime: Duration(seconds: (route['duration'] as num).round()),
        followsRoads: true,
      );
    } catch (_) {
      return straightLine(waypoints,
          reason: 'Servico de rotas indisponivel - distancia em linha reta.');
    }
  }

  /// Straight-line fallback, explicitly flagged as not road-matched.
  static RoutedPath straightLine(List<LatLng> waypoints, {String? reason}) {
    var total = 0.0;
    for (var i = 1; i < waypoints.length; i++) {
      total += _distance.as(LengthUnit.Meter, waypoints[i - 1], waypoints[i]);
    }
    return RoutedPath(
      polyline: List.of(waypoints),
      waypoints: List.of(waypoints),
      distanceM: total,
      followsRoads: false,
      degradedReason: reason,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await _client.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', uri);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
