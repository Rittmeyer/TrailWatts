import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Ground height per point, or nothing.
///
/// Gradient is the matcher's main input and OSM carries almost no `ele`
/// tags, so this is a separate lookup rather than part of the way fetch.
/// It returns null per point rather than zero: sea level is a real height,
/// and a route "at 0 m" would be scored as flat instead of as unknown.
abstract class ElevationService {
  Future<List<double?>> elevationsFor(List<LatLng> points);
}

/// OpenTopoData, a documented public API over open DEMs.
///
/// Its free instance allows 100 locations per call and 1 call per second,
/// both enforced here rather than left to callers. [dataset] defaults to
/// SRTM 30 m, which covers most of the inhabited world; a build with its
/// own instance can point [baseUrl] at it and pick another.
class OpenTopoElevationService implements ElevationService {
  static const defaultBaseUrl = String.fromEnvironment(
    'TRAILWATT_ELEVATION_URL',
    defaultValue: 'https://api.opentopodata.org/v1',
  );

  static const defaultDataset = String.fromEnvironment(
    'TRAILWATT_ELEVATION_DATASET',
    defaultValue: 'srtm30m',
  );

  /// The documented per-call limit. A request over it is rejected whole, so
  /// batching is not an optimisation here, it is the contract.
  static const maxPerCall = 100;

  final String baseUrl;
  final String dataset;
  final Duration minInterval;
  final Duration timeout;
  final http.Client _client;

  DateTime? _lastCall;

  OpenTopoElevationService({
    this.baseUrl = defaultBaseUrl,
    this.dataset = defaultDataset,
    this.minInterval = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 15),
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<List<double?>> elevationsFor(List<LatLng> points) async {
    if (points.isEmpty) return const [];
    final out = List<double?>.filled(points.length, null);

    for (var start = 0; start < points.length; start += maxPerCall) {
      final end = (start + maxPerCall).clamp(0, points.length);
      final batch = points.sublist(start, end);
      final values = await _fetchBatch(batch);
      // A failed batch leaves nulls rather than aborting the rest: partial
      // elevation is still better terrain data than none, and the nulls
      // keep saying which parts are unknown.
      for (var i = 0; i < values.length && start + i < out.length; i++) {
        out[start + i] = values[i];
      }
    }
    return out;
  }

  Future<List<double?>> _fetchBatch(List<LatLng> batch) async {
    final since =
        _lastCall == null ? null : DateTime.now().difference(_lastCall!);
    if (since != null && since < minInterval) {
      await Future<void>.delayed(minInterval - since);
    }
    _lastCall = DateTime.now();

    final locations =
        batch.map((p) => '${p.latitude},${p.longitude}').join('|');
    final uri = Uri.parse('$baseUrl/$dataset').replace(queryParameters: {
      'locations': locations,
    });

    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        return List<double?>.filled(batch.length, null);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return List<double?>.filled(batch.length, null);
      }
      final results = decoded['results'];
      if (results is! List) return List<double?>.filled(batch.length, null);

      final values = List<double?>.filled(batch.length, null);
      for (var i = 0; i < results.length && i < values.length; i++) {
        final entry = results[i];
        if (entry is! Map) continue;
        // The API returns a null elevation for a point outside the dataset.
        // Carried through as null, not turned into zero.
        values[i] = (entry['elevation'] as num?)?.toDouble();
      }
      return values;
    } catch (_) {
      return List<double?>.filled(batch.length, null);
    }
  }
}
