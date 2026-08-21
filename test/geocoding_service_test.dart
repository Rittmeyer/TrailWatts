import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/services/geocoding_service.dart';

/// Same shape Nominatim returns for a place search.
String bodyFor(List<Map<String, Object?>> entries) => jsonEncode(entries);

NominatimGeocodingService serviceReturning(
  http.Response Function(http.Request) handler, {
  Duration interval = Duration.zero,
}) =>
    NominatimGeocodingService(
      client: MockClient((request) async => handler(request)),
      baseUrl: 'https://geocoder.test',
      minInterval: interval,
    );

void main() {
  group('reading results', () {
    test('a place becomes a point the map can use', () async {
      final service = serviceReturning((_) => http.Response(
            bodyFor([
              {
                'name': 'Parque Ibirapuera',
                'display_name': 'Parque Ibirapuera, São Paulo, Brasil',
                'lat': '-23.5874',
                'lon': '-46.6576',
              }
            ]),
            200,
          ));

      final result = await service.search('ibirapuera');

      expect(result.ok, isTrue);
      expect(result.places.single.name, 'Parque Ibirapuera');
      expect(result.places.single.point.latitude, closeTo(-23.5874, 1e-6));
      expect(result.places.single.point.longitude, closeTo(-46.6576, 1e-6));
    });

    test('an entry without usable coordinates is dropped, not guessed',
        () async {
      final service = serviceReturning((_) => http.Response(
            bodyFor([
              {'display_name': 'Sem coordenada', 'lat': 'x', 'lon': 'y'},
              {
                'display_name': 'Boa, São Paulo',
                'lat': '-23.55',
                'lon': '-46.63',
              },
            ]),
            200,
          ));

      final result = await service.search('qualquer');
      expect(result.places, hasLength(1));
      expect(result.places.single.address, 'Boa, São Paulo');
    });

    test('a place with no short name falls back to the address', () async {
      final service = serviceReturning((_) => http.Response(
            bodyFor([
              {
                'display_name': 'Rua Augusta, São Paulo',
                'lat': '-23.55',
                'lon': '-46.66',
              }
            ]),
            200,
          ));
      final result = await service.search('augusta');
      expect(result.places.single.name, 'Rua Augusta');
    });
  });

  group('nothing found is not the same as it did not run', () {
    test('an empty list is a result, not a failure', () async {
      final service = serviceReturning((_) => http.Response('[]', 200));
      final result = await service.search('lugar que nao existe');
      expect(result.ok, isTrue);
      expect(result.isEmpty, isTrue);
    });

    test('a server error is a failure', () async {
      final service = serviceReturning((_) => http.Response('', 500));
      final result = await service.search('centro');
      expect(result.ok, isFalse);
      expect(result.failure, GeocodingFailure.network);
    });

    test('being rate limited says so, rather than looking like no results',
        () async {
      final service = serviceReturning((_) => http.Response('', 429));
      final result = await service.search('centro');
      expect(result.failure, GeocodingFailure.rateLimited);
    });

    test('a body that is not a list is an invalid response', () async {
      final service =
          serviceReturning((_) => http.Response('{"error":"nope"}', 200));
      final result = await service.search('centro');
      expect(result.failure, GeocodingFailure.invalidResponse);
    });

    test('a body that is not JSON at all does not throw', () async {
      final service =
          serviceReturning((_) => http.Response('<html>502</html>', 200));
      final result = await service.search('centro');
      expect(result.failure, GeocodingFailure.invalidResponse);
    });
  });

  group('the request itself', () {
    test('it identifies the app, which Nominatim requires', () async {
      String? agent;
      final service = serviceReturning((request) {
        agent = request.headers['User-Agent'];
        return http.Response('[]', 200);
      });
      await service.search('centro');
      expect(agent, isNotNull);
      expect(agent, contains('Trailwatt'));
    });

    test('it biases towards where the rider is looking', () async {
      Uri? asked;
      final service = serviceReturning((request) {
        asked = request.url;
        return http.Response('[]', 200);
      });
      await service.search('centro', near: const LatLng(-23.55, -46.63));
      expect(asked!.queryParameters['lat'], '-23.55');
      expect(asked!.queryParameters['lon'], '-46.63');
    });

    test('an empty query never reaches the network', () async {
      var called = false;
      final service = serviceReturning((_) {
        called = true;
        return http.Response('[]', 200);
      });
      final result = await service.search('   ');
      expect(called, isFalse);
      expect(result.ok, isTrue);
    });

    test('it keeps one second between requests, as the policy requires',
        () async {
      final service = serviceReturning((_) => http.Response('[]', 200),
          interval: const Duration(milliseconds: 200));

      final watch = Stopwatch()..start();
      await service.search('um');
      await service.search('dois');
      watch.stop();

      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(180),
          reason: 'the second call went out too soon after the first');
    });
  });
}
