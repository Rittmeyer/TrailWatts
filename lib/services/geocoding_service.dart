import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A place the rider can start from, as returned by a search.
class GeocodedPlace {
  /// Short label - "Ibirapuera" - for the list row.
  final String name;

  /// Full address, for telling two places with the same name apart.
  final String address;

  final LatLng point;

  const GeocodedPlace({
    required this.name,
    required this.address,
    required this.point,
  });
}

enum GeocodingFailure { network, invalidResponse, rateLimited, notConfigured }

/// Outcome of a search. Empty results and a failed search are different
/// things and the rider is told which: "nothing there" is an answer,
/// "the search did not run" is not.
class GeocodingResult {
  final List<GeocodedPlace> places;
  final GeocodingFailure? failure;

  const GeocodingResult(this.places) : failure = null;
  const GeocodingResult.failed(this.failure) : places = const [];

  bool get ok => failure == null;
  bool get isEmpty => ok && places.isEmpty;
}

/// Turning typed text into a place on the map.
///
/// Behind an interface for the same reason as [RoutingService]: which
/// geocoder is used is still an open P0 decision, and swapping it must not
/// reach the screens.
abstract class GeocodingService {
  /// [near] biases results towards where the rider is looking, so "centro"
  /// finds the one in their city rather than the largest one on earth.
  Future<GeocodingResult> search(String query, {LatLng? near});
}

/// Nominatim, OpenStreetMap's own geocoder.
///
/// Its usage policy is part of the contract, not a footnote: one request a
/// second at most, a User-Agent that identifies the application, and no
/// bulk use. Both are enforced here rather than left to callers - a screen
/// that forgets would get the whole app blocked, not just itself.
///
/// The public instance is for development. A production build points
/// [baseUrl] at its own instance; it is the same "candidate map/road data
/// source" P0 decision as the OSRM endpoint.
class NominatimGeocodingService implements GeocodingService {
  static const _defaultBase = String.fromEnvironment('TRAILWATT_NOMINATIM_URL',
      defaultValue: 'https://nominatim.openstreetmap.org');

  /// Nominatim rejects requests that do not identify the caller. Overridden
  /// at build time so a fork does not impersonate this app.
  static const _defaultAgent = String.fromEnvironment(
      'TRAILWATT_GEOCODER_AGENT',
      defaultValue: 'Trailwatt/0.1 (+https://github.com/Rittmeyer/TrailWatts)');

  final String baseUrl;
  final String userAgent;
  final http.Client client;

  /// The policy minimum. Kept as a field so tests do not have to wait it out.
  final Duration minInterval;

  DateTime? _lastRequest;

  NominatimGeocodingService({
    http.Client? client,
    this.baseUrl = _defaultBase,
    this.userAgent = _defaultAgent,
    this.minInterval = const Duration(seconds: 1),
  }) : client = client ?? http.Client();

  @override
  Future<GeocodingResult> search(String query, {LatLng? near}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const GeocodingResult([]);

    final since =
        _lastRequest == null ? null : DateTime.now().difference(_lastRequest!);
    if (since != null && since < minInterval) {
      // Waiting is the policy-respecting answer; failing would push callers
      // to retry, which is the opposite of what the limit is for.
      await Future<void>.delayed(minInterval - since);
    }
    _lastRequest = DateTime.now();

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '6',
      'addressdetails': '0',
      if (near != null) 'lat': '${near.latitude}',
      if (near != null) 'lon': '${near.longitude}',
    });

    try {
      final response = await client.get(uri, headers: {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      });

      if (response.statusCode == 429) {
        return const GeocodingResult.failed(GeocodingFailure.rateLimited);
      }
      if (response.statusCode != 200) {
        return const GeocodingResult.failed(GeocodingFailure.network);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const GeocodingResult.failed(GeocodingFailure.invalidResponse);
      }

      final places = <GeocodedPlace>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final lat = double.tryParse('${entry['lat']}');
        final lon = double.tryParse('${entry['lon']}');
        if (lat == null || lon == null) continue;
        final display = '${entry['display_name'] ?? ''}'.trim();
        if (display.isEmpty) continue;
        final name = '${entry['name'] ?? ''}'.trim();
        places.add(GeocodedPlace(
          name: name.isEmpty ? display.split(',').first.trim() : name,
          address: display,
          point: LatLng(lat, lon),
        ));
      }
      return GeocodingResult(places);
    } on FormatException {
      return const GeocodingResult.failed(GeocodingFailure.invalidResponse);
    } catch (_) {
      return const GeocodingResult.failed(GeocodingFailure.network);
    }
  }
}
