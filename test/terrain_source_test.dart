import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/models/route_suggestion.dart';
import 'package:trailwatt/models/terrain_target.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/terrain/elevation_service.dart';

String overpassBody(List<Map<String, Object?>> elements) =>
    jsonEncode({'elements': elements});

Map<String, Object?> way(String id,
        {Map<String, Object?> tags = const {}, int points = 3}) =>
    {
      'type': 'way',
      'id': id,
      'geometry': [
        for (var i = 0; i < points; i++)
          {'lat': -23.55 + i * 0.001, 'lon': -46.63},
      ],
      'tags': tags,
    };

OverpassSegmentSource sourceReturning(
        http.Response Function(http.Request) handler) =>
    OverpassSegmentSource(
      baseUrl: 'https://overpass.test/api',
      client: MockClient((request) async => handler(request)),
    );

void main() {
  group('the Overpass query', () {
    test('asks only for ground a bicycle may use', () {
      final source = sourceReturning((_) => http.Response('{}', 200));
      final query = source.queryFor(const LatLng(-23.55, -46.63), 8000);

      expect(query, contains('around:8000,-23.55,-46.63'));
      expect(query, contains('cycleway'));
      expect(query, contains(r'"bicycle"!~"^(no|dismount)$"'),
          reason: 'a route the rider is barred from is worse than none');
      expect(query, contains(r'"access"!~"^(private|no)$"'));
      expect(query, isNot(contains('motorway')));
      expect(query, contains('out geom'),
          reason: 'inline geometry keeps this to one round trip');
    });
  });

  group('reading ways', () {
    test('a way becomes a polyline with its tags read', () async {
      final source = sourceReturning((_) => http.Response(
            overpassBody([
              way('12', tags: {
                'highway': 'cycleway',
                'name': 'Ciclovia Pinheiros',
                'surface': 'asphalt',
              })
            ]),
            200,
          ));

      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);

      expect(result.ok, isTrue);
      final only = result.ways.single;
      expect(only.id, 'way/12');
      expect(only.name, 'Ciclovia Pinheiros');
      expect(only.points, hasLength(3));
      expect(only.surface, SurfaceType.asphalt);
      expect(only.safety, CyclingSafetyLevel.lowRisk);
      expect(only.hasElevation, isFalse,
          reason: 'OSM does not carry it; a zero here would read as flat');
    });

    test('a way with fewer than two points is dropped', () async {
      final source = sourceReturning(
          (_) => http.Response(overpassBody([way('1', points: 1)]), 200));
      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);
      expect(result.ways, isEmpty);
    });

    test('an untagged track is not called asphalt', () {
      expect(OverpassSegmentSource.surfaceFrom({'highway': 'track'}),
          SurfaceType.dirt);
      expect(OverpassSegmentSource.surfaceFrom({'highway': 'residential'}),
          SurfaceType.asphalt);
      expect(
          OverpassSegmentSource.surfaceFrom(
              {'highway': 'track', 'surface': 'asphalt'}),
          SurfaceType.asphalt);
      expect(OverpassSegmentSource.surfaceFrom({'surface': 'gravel'}),
          SurfaceType.gravel);
    });

    test('road class stands in for traffic and safety, coarsely', () {
      expect(OverpassSegmentSource.trafficFrom({'highway': 'primary'}),
          TrafficLevel.high);
      expect(OverpassSegmentSource.trafficFrom({'highway': 'cycleway'}),
          TrafficLevel.low);
      expect(OverpassSegmentSource.safetyFrom({'highway': 'primary'}),
          CyclingSafetyLevel.highRisk);
      expect(
          OverpassSegmentSource.safetyFrom(
              {'highway': 'secondary', 'bicycle': 'designated'}),
          CyclingSafetyLevel.lowRisk);
      expect(OverpassSegmentSource.safetyFrom({'highway': 'motorway_link'}),
          CyclingSafetyLevel.unknown);
    });
  });

  group('failures stay distinguishable', () {
    test('over quota is not the same as nothing here', () async {
      final source = sourceReturning((_) => http.Response('', 429));
      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);
      expect(result.ok, isFalse);
      expect(result.failure, SegmentFetchFailure.rateLimited);
    });

    test('a timed-out query reads as come back later', () async {
      final source = sourceReturning((_) => http.Response('', 504));
      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);
      expect(result.failure, SegmentFetchFailure.rateLimited);
    });

    test('a body that is not JSON does not throw', () async {
      final source = sourceReturning((_) => http.Response('<html>', 200));
      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);
      expect(result.failure, SegmentFetchFailure.invalidResponse);
    });

    test('an empty area is a result, not a failure', () async {
      final source =
          sourceReturning((_) => http.Response(overpassBody([]), 200));
      final result = await source.waysAround(const LatLng(-23.55, -46.63), 800);
      expect(result.ok, isTrue);
      expect(result.ways, isEmpty);
    });
  });

  group('elevation', () {
    test('a point outside the dataset stays null rather than becoming zero',
        () async {
      final service = OpenTopoElevationService(
        baseUrl: 'https://elev.test/v1',
        minInterval: Duration.zero,
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'results': [
                  {'elevation': 812.5},
                  {'elevation': null},
                ]
              }),
              200,
            )),
      );

      final values = await service
          .elevationsFor([const LatLng(-23.55, -46.63), const LatLng(0, 0)]);
      expect(values, [812.5, null]);
    });

    test('more points than the API allows are split into batches', () async {
      var calls = 0;
      final service = OpenTopoElevationService(
        baseUrl: 'https://elev.test/v1',
        minInterval: Duration.zero,
        client: MockClient((request) async {
          calls++;
          final asked =
              request.url.queryParameters['locations']!.split('|').length;
          expect(asked, lessThanOrEqualTo(OpenTopoElevationService.maxPerCall));
          return http.Response(
              jsonEncode({
                'results': [
                  for (var i = 0; i < asked; i++) {'elevation': 700.0}
                ]
              }),
              200);
        }),
      );

      final points = [
        for (var i = 0; i < 250; i++) LatLng(-23.55 + i * 0.0001, -46.63),
      ];
      final values = await service.elevationsFor(points);

      expect(calls, 3);
      expect(values, hasLength(250));
      expect(values.every((v) => v == 700.0), isTrue);
    });

    test('a failed batch leaves nulls instead of losing the others', () async {
      var calls = 0;
      final service = OpenTopoElevationService(
        baseUrl: 'https://elev.test/v1',
        minInterval: Duration.zero,
        client: MockClient((request) async {
          calls++;
          if (calls == 1) return http.Response('', 500);
          final asked =
              request.url.queryParameters['locations']!.split('|').length;
          return http.Response(
              jsonEncode({
                'results': [
                  for (var i = 0; i < asked; i++) {'elevation': 700.0}
                ]
              }),
              200);
        }),
      );

      final points = [
        for (var i = 0; i < 150; i++) LatLng(-23.55 + i * 0.0001, -46.63),
      ];
      final values = await service.elevationsFor(points);

      expect(values.take(100).every((v) => v == null), isTrue);
      expect(values.skip(100).every((v) => v == 700.0), isTrue);
    });
  });
}
