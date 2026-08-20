import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/services/platform/gpx_export.dart';

void main() {
  const a = LatLng(-23.5566, -46.6414);
  const b = LatLng(-23.5505, -46.6355);

  test('produces a GPX 1.1 track with the route name and points', () {
    final gpx = buildRouteGpx(
      name: 'Subida da Serra',
      points: const [GpxRoutePoint(a), GpxRoutePoint(b)],
      createdAt: DateTime.utc(2026, 8, 20, 7, 14, 30),
    );

    expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(gpx, contains('version="1.1"'));
    expect(gpx, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
    expect(gpx, contains('<name>Subida da Serra</name>'));
    expect(gpx, contains('<time>2026-08-20T07:14:30Z</time>'));
    expect(gpx, contains('lat="-23.5566000"'));
    expect(gpx, contains('lon="-46.6355000"'));
    expect(gpx, contains('</gpx>'));
    // One point in, one trkpt out - no interpolation behind the rider's back.
    expect('<trkpt'.allMatches(gpx), hasLength(2));
  });

  test('elevation is written only where it is actually known', () {
    final gpx = buildRouteGpx(
      name: 'Serra',
      points: const [
        GpxRoutePoint(a, elevationM: 812.4),
        GpxRoutePoint(b),
      ],
    );

    expect(gpx, contains('<ele>812.4</ele>'));
    // A GPX reader takes <ele>0</ele> as sea level, not as "unknown", so the
    // point with no elevation carries no <ele> at all.
    expect('<ele>'.allMatches(gpx), hasLength(1));
    expect(gpx, isNot(contains('<ele>0.0</ele>')));
  });

  test('names that would break the XML are escaped', () {
    final gpx = buildRouteGpx(
      name: 'Serra & "Curva" <fast>',
      points: const [GpxRoutePoint(a)],
    );

    expect(gpx, contains('Serra &amp; &quot;Curva&quot; &lt;fast&gt;'));
    expect(gpx, isNot(contains('<fast>')));
  });

  test('a track with no points is refused rather than written empty', () {
    expect(() => buildRouteGpx(name: 'Nowhere', points: const []),
        throwsA(isA<ArgumentError>()));
  });
}
