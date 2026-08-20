import 'package:latlong2/latlong.dart';

/// Builds the GPX that Feature 002 Requirement 1 asks for: a valid file the
/// rider's platform can import, generated from a route suggestion.
///
/// A track (`<trk>`) rather than a route (`<rte>`) because that is what the
/// cycling platforms' course importers read most consistently - a `<rte>` is
/// a list of turn cues, while the suggested stretch is a traced line.
///
/// Elevation is written only where it is actually known. A GPX consumer reads
/// `<ele>0</ele>` as "sea level", not as "unknown", so emitting a placeholder
/// would put a number in the rider's platform that Trailwatt never measured.
class GpxRoutePoint {
  final LatLng position;
  final double? elevationM;

  const GpxRoutePoint(this.position, {this.elevationM});
}

String buildRouteGpx({
  required String name,
  required List<GpxRoutePoint> points,
  DateTime? createdAt,
  String creator = 'Trailwatt',
}) {
  if (points.isEmpty) {
    throw ArgumentError('A GPX track needs at least one point.');
  }

  final timestamp = (createdAt ?? DateTime.now().toUtc()).toUtc();
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="${_escape(creator)}"')
    ..writeln('     xmlns="http://www.topografix.com/GPX/1/1"')
    ..writeln('     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
    ..writeln('     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">')
    ..writeln('  <metadata>')
    ..writeln('    <name>${_escape(name)}</name>')
    ..writeln('    <time>${_iso8601(timestamp)}</time>')
    ..writeln('  </metadata>')
    ..writeln('  <trk>')
    ..writeln('    <name>${_escape(name)}</name>')
    ..writeln('    <trkseg>');

  for (final point in points) {
    final lat = point.position.latitude.toStringAsFixed(7);
    final lon = point.position.longitude.toStringAsFixed(7);
    final elevation = point.elevationM;
    if (elevation == null) {
      buffer.writeln('      <trkpt lat="$lat" lon="$lon"/>');
    } else {
      buffer
        ..writeln('      <trkpt lat="$lat" lon="$lon">')
        ..writeln('        <ele>${elevation.toStringAsFixed(1)}</ele>')
        ..writeln('      </trkpt>');
    }
  }

  buffer
    ..writeln('    </trkseg>')
    ..writeln('  </trk>')
    ..writeln('</gpx>');

  return buffer.toString();
}

/// `DateTime.toIso8601String()` renders UTC with a trailing `Z` already, but
/// also with microseconds, which some importers reject.
String _iso8601(DateTime utc) => '${utc.year.toString().padLeft(4, '0')}-'
    '${utc.month.toString().padLeft(2, '0')}-'
    '${utc.day.toString().padLeft(2, '0')}T'
    '${utc.hour.toString().padLeft(2, '0')}:'
    '${utc.minute.toString().padLeft(2, '0')}:'
    '${utc.second.toString().padLeft(2, '0')}Z';

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
