import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/services/routing_service.dart';

OsrmRoutingService _serviceReturning(
  Object body, {
  int status = 200,
  void Function(Uri uri)? onRequest,
}) {
  return OsrmRoutingService(
    client: MockClient((req) async {
      onRequest?.call(req.url);
      return http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});
    }),
  );
}

const _a = LatLng(-23.5566, -46.6414);
const _b = LatLng(-23.5505, -46.6355);

void main() {
  group('routeThrough', () {
    test('returns the road geometry, distance and duration from OSRM',
        () async {
      Uri? requested;
      final service = _serviceReturning(
        {
          'code': 'Ok',
          'routes': [
            {
              'geometry': {
                'coordinates': [
                  [-46.6414, -23.5566],
                  [-46.6390, -23.5540],
                  [-46.6355, -23.5505],
                ]
              },
              'distance': 1234.5,
              'duration': 300.0,
            }
          ],
        },
        onRequest: (uri) => requested = uri,
      );

      final path = await service.routeThrough([_a, _b]);

      expect(path.followsRoads, isTrue);
      expect(path.degradedReason, isNull);
      expect(path.distanceM, 1234.5);
      expect(path.movingTime, const Duration(minutes: 5));
      // Road geometry has more points than the two waypoints asked for.
      expect(path.polyline, hasLength(3));
      expect(path.polyline.first.latitude, closeTo(-23.5566, 1e-9));
      expect(path.polyline.first.longitude, closeTo(-46.6414, 1e-9));
      // OSRM takes lon,lat order - a swap here would silently route to sea.
      expect(requested!.path, contains('-46.6414,-23.5566'));
    });

    test('falls back to a flagged straight line when the service fails',
        () async {
      final service = _serviceReturning({'error': 'boom'}, status: 500);

      final path = await service.routeThrough([_a, _b]);

      expect(path.followsRoads, isFalse);
      expect(path.degradedReason, isNotNull);
      expect(path.polyline, [_a, _b]);
      expect(path.movingTime, isNull,
          reason: 'a guessed path must not advertise a moving time');
      expect(path.distanceM, greaterThan(0));
    });

    test('a routable-but-empty answer is degraded, not silently accepted',
        () async {
      final service = _serviceReturning({'code': 'NoRoute', 'routes': []});

      final path = await service.routeThrough([_a, _b]);

      expect(path.followsRoads, isFalse);
      expect(path.degradedReason, isNotNull);
    });

    test('a single waypoint cannot form a route', () async {
      final service = _serviceReturning({'code': 'Ok'});

      final path = await service.routeThrough([_a]);

      expect(path.followsRoads, isFalse);
      expect(path.distanceM, 0);
    });
  });

  group('snapToRoad', () {
    test('moves the point onto the road and reports the offset', () async {
      final service = _serviceReturning({
        'code': 'Ok',
        'waypoints': [
          {
            'location': [-46.6400, -23.5550],
            'distance': 12.5,
          }
        ],
      });

      final snapped = await service.snapToRoad(_a);

      expect(snapped.onRoad, isTrue);
      expect(snapped.requested, _a);
      expect(snapped.point.latitude, closeTo(-23.5550, 1e-9));
      expect(snapped.point.longitude, closeTo(-46.6400, 1e-9));
      expect(snapped.offsetM, 12.5);
    });

    test('keeps the requested point and says so when nothing matched',
        () async {
      final service = _serviceReturning({'code': 'NoSegment', 'waypoints': []});

      final snapped = await service.snapToRoad(_a);

      expect(snapped.onRoad, isFalse);
      expect(snapped.point, _a);
      expect(snapped.offsetM, 0);
    });
  });

  test('straight-line distance sums the legs', () {
    final path = OsrmRoutingService.straightLine([_a, _b]);

    const expected = Distance();
    expect(
      path.distanceM,
      closeTo(expected.as(LengthUnit.Meter, _a, _b).toDouble(), 0.5),
    );
    expect(path.followsRoads, isFalse);
  });
}
