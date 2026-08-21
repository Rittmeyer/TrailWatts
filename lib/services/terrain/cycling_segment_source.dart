import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_suggestion.dart';
import '../../models/terrain_target.dart';

/// A stretch of road or path, as the data source knows it: an ordered
/// polyline plus what the tags say about riding it. Elevation is filled in
/// later, by an elevation source - OSM almost never carries it.
class CyclingWay {
  /// Stable across fetches, so the cache and the index can agree on
  /// identity: OSM's own way id.
  final String id;
  final String? name;
  final List<LatLng> points;
  final SurfaceType surface;
  final TrafficLevel traffic;
  final CyclingSafetyLevel safety;

  /// Elevation per point, once known. Null until an elevation source has
  /// filled it - and a null must stay visible, because a gradient invented
  /// from missing elevation is the one input the matcher cannot check.
  final List<double>? elevationM;

  const CyclingWay({
    required this.id,
    required this.points,
    this.name,
    this.surface = SurfaceType.asphalt,
    this.traffic = TrafficLevel.unknown,
    this.safety = CyclingSafetyLevel.unknown,
    this.elevationM,
  });

  CyclingWay withElevation(List<double> values) => CyclingWay(
        id: id,
        name: name,
        points: points,
        surface: surface,
        traffic: traffic,
        safety: safety,
        elevationM: values,
      );

  bool get hasElevation =>
      elevationM != null && elevationM!.length == points.length;
}

enum SegmentFetchFailure { network, invalidResponse, rateLimited, timeout }

/// Ways found, or the reason none were. Same rule as the geocoder: "no
/// cycling roads here" and "the query did not run" are different answers
/// and the rider is told which.
class SegmentFetch {
  final List<CyclingWay> ways;
  final SegmentFetchFailure? failure;

  const SegmentFetch(this.ways) : failure = null;
  const SegmentFetch.failed(this.failure) : ways = const [];

  bool get ok => failure == null;
}

/// Where rideable ground comes from.
///
/// Behind an interface because the source is still the open P0 decision in
/// DECISIONS_REQUIRED.md, and because the cache and the index in front of
/// it must not care which one is behind.
abstract class CyclingSegmentSource {
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM);
}

/// OpenStreetMap through Overpass.
///
/// OSM is cycling-specific data in the sense that matters here: cycleways,
/// bicycle designation, surface and smoothness are first-class tags, and
/// bicycle route relations are mapped. It is ODbL, so a build that ships
/// derived data owes attribution and share-alike - recorded in
/// DECISIONS_REQUIRED.md along with the endpoint choice.
///
/// The public endpoint is rate-limited and meant for development. A release
/// points [baseUrl] at its own instance.
class OverpassSegmentSource implements CyclingSegmentSource {
  static const defaultBaseUrl = String.fromEnvironment(
    'TRAILWATT_OVERPASS_URL',
    defaultValue: 'https://overpass-api.de/api/interpreter',
  );

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  OverpassSegmentSource({
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(seconds: 25),
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Highway values worth riding a structured workout on. Motorways and
  /// their links are absent on purpose, and so is anything the tags say
  /// bicycles may not use - a suggestion the rider is not allowed to ride
  /// is worse than no suggestion.
  static const _rideable = 'cycleway|residential|living_street|unclassified|'
      'tertiary|tertiary_link|secondary|secondary_link|primary|primary_link|'
      'track|path|road';

  String queryFor(LatLng centre, double radiusM) {
    final r = radiusM.round();
    final lat = centre.latitude;
    final lon = centre.longitude;
    // `out geom` returns the node coordinates inline, which turns what would
    // be a way lookup plus a node lookup into one round trip.
    return '[out:json][timeout:${timeout.inSeconds}];'
        '('
        'way["highway"~"^($_rideable)\$"]'
        '["bicycle"!~"^(no|dismount)\$"]'
        '["access"!~"^(private|no)\$"]'
        '(around:$r,$lat,$lon);'
        ');'
        'out geom tags;';
  }

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async {
    try {
      final response = await _client.post(Uri.parse(baseUrl),
          body: {'data': queryFor(centre, radiusM)},
          headers: {'Accept': 'application/json'}).timeout(timeout);

      if (response.statusCode == 429 || response.statusCode == 504) {
        // Overpass answers 429 when over quota and 504 when the query ran
        // out of time; both mean "come back later", not "nothing here".
        return const SegmentFetch.failed(SegmentFetchFailure.rateLimited);
      }
      if (response.statusCode != 200) {
        return const SegmentFetch.failed(SegmentFetchFailure.network);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const SegmentFetch.failed(SegmentFetchFailure.invalidResponse);
      }
      final elements = decoded['elements'];
      if (elements is! List) {
        return const SegmentFetch.failed(SegmentFetchFailure.invalidResponse);
      }

      final ways = <CyclingWay>[];
      for (final element in elements) {
        final way = _readWay(element);
        if (way != null) ways.add(way);
      }
      return SegmentFetch(ways);
    } on FormatException {
      return const SegmentFetch.failed(SegmentFetchFailure.invalidResponse);
    } catch (_) {
      return const SegmentFetch.failed(SegmentFetchFailure.network);
    }
  }

  CyclingWay? _readWay(Object? element) {
    if (element is! Map<String, dynamic>) return null;
    if (element['type'] != 'way') return null;

    final geometry = element['geometry'];
    if (geometry is! List || geometry.length < 2) return null;

    final points = <LatLng>[];
    for (final node in geometry) {
      if (node is! Map) continue;
      final lat = (node['lat'] as num?)?.toDouble();
      final lon = (node['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      points.add(LatLng(lat, lon));
    }
    if (points.length < 2) return null;

    final tags = element['tags'] is Map
        ? (element['tags'] as Map).cast<String, Object?>()
        : const <String, Object?>{};

    return CyclingWay(
      id: 'way/${element['id']}',
      name: (tags['name'] as String?)?.trim(),
      points: points,
      surface: surfaceFrom(tags),
      traffic: trafficFrom(tags),
      safety: safetyFrom(tags),
    );
  }

  /// OSM's `surface` vocabulary is long; this maps it onto the three the
  /// power model distinguishes. Anything unrecognised stays asphalt only
  /// when the road class implies it - a `track` with no surface tag is not
  /// asphalt, and guessing so would flatter it.
  static SurfaceType surfaceFrom(Map<String, Object?> tags) {
    final surface = '${tags['surface'] ?? ''}'.toLowerCase();
    if (surface.isNotEmpty) {
      const paved = {
        'asphalt',
        'paved',
        'concrete',
        'concrete:plates',
        'paving_stones',
        'chipseal',
      };
      const loose = {
        'gravel',
        'fine_gravel',
        'compacted',
        'pebblestone',
        'unpaved',
        'cobblestone',
        'sett',
      };
      if (paved.contains(surface)) return SurfaceType.asphalt;
      if (loose.contains(surface)) return SurfaceType.gravel;
      return SurfaceType.dirt;
    }
    final highway = '${tags['highway'] ?? ''}'.toLowerCase();
    if (highway == 'track' || highway == 'path') return SurfaceType.dirt;
    return SurfaceType.asphalt;
  }

  /// A road class is a coarse proxy for traffic, and it is the only one OSM
  /// gives without a live feed. It is reported as such: nothing here claims
  /// to have measured traffic, and feature 010 is where real data lands.
  static TrafficLevel trafficFrom(Map<String, Object?> tags) {
    final highway = '${tags['highway'] ?? ''}'.toLowerCase();
    return switch (highway) {
      'cycleway' || 'path' || 'track' || 'living_street' => TrafficLevel.low,
      'residential' ||
      'unclassified' ||
      'tertiary' ||
      'tertiary_link' =>
        TrafficLevel.low,
      'secondary' || 'secondary_link' => TrafficLevel.medium,
      'primary' || 'primary_link' => TrafficLevel.high,
      _ => TrafficLevel.unknown,
    };
  }

  static CyclingSafetyLevel safetyFrom(Map<String, Object?> tags) {
    final highway = '${tags['highway'] ?? ''}'.toLowerCase();
    final bicycle = '${tags['bicycle'] ?? ''}'.toLowerCase();
    final lane = '${tags['cycleway'] ?? ''}'.toLowerCase();
    if (highway == 'cycleway' || bicycle == 'designated') {
      return CyclingSafetyLevel.lowRisk;
    }
    if (lane.isNotEmpty && lane != 'no') return CyclingSafetyLevel.lowRisk;
    return switch (highway) {
      'residential' || 'living_street' || 'track' => CyclingSafetyLevel.lowRisk,
      'tertiary' || 'unclassified' || 'path' => CyclingSafetyLevel.moderate,
      'secondary' || 'secondary_link' => CyclingSafetyLevel.moderate,
      'primary' || 'primary_link' => CyclingSafetyLevel.highRisk,
      _ => CyclingSafetyLevel.unknown,
    };
  }
}
