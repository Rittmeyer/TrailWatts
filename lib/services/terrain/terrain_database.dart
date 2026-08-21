import 'package:latlong2/latlong.dart';

import '../../models/route_suggestion.dart';
import '../../models/terrain_target.dart';
import 'cycling_segment_source.dart';

import 'terrain_database_io.dart'
    if (dart.library.html) 'terrain_database_web.dart' as impl;

/// Ground kept between runs of the app.
///
/// The in-memory index already stops a second search re-fetching an area,
/// but it dies with the process: open the app tomorrow and the same city is
/// downloaded again. Roads and their heights are the most static data this
/// app touches, and the most expensive to get - the elevation API allows a
/// thousand calls a day - so they are exactly what belongs on disk.
///
/// Everything here is a cache, never a source of truth: it may be empty,
/// stale or refused by the browser, and the app has to work when it is.
abstract class TerrainDatabase {
  Future<void> open();

  Future<List<CyclingWay>> waysIn(Iterable<String> cellKeys);

  /// [cellsOf] gives every grid cell a way passes through - a long road is
  /// stored once and listed in each of them.
  Future<void> putWays(
      Iterable<CyclingWay> ways, Iterable<String> Function(CyclingWay) cellsOf);

  Future<Set<String>> fetchedCells();
  Future<void> markCells(Iterable<String> cellKeys);

  Future<Map<String, double>> elevations();
  Future<void> putElevations(Map<String, double> values);

  Future<void> clear();

  /// The best database this platform has: IndexedDB on the web, and nothing
  /// yet on native - see the note in the README.
  factory TerrainDatabase.forPlatform() => impl.createTerrainDatabase();
}

/// Keeps nothing. What the app does today, and the honest answer wherever
/// no store is wired up.
class NoTerrainDatabase implements TerrainDatabase {
  const NoTerrainDatabase();

  @override
  Future<void> open() async {}

  @override
  Future<List<CyclingWay>> waysIn(Iterable<String> cellKeys) async => const [];

  @override
  Future<void> putWays(Iterable<CyclingWay> ways,
      Iterable<String> Function(CyclingWay) cellsOf) async {}

  @override
  Future<Set<String>> fetchedCells() async => const {};

  @override
  Future<void> markCells(Iterable<String> cellKeys) async {}

  @override
  Future<Map<String, double>> elevations() async => const {};

  @override
  Future<void> putElevations(Map<String, double> values) async {}

  @override
  Future<void> clear() async {}
}

/// Shared encoding, so a row written by one implementation reads back in
/// another and a stored way survives a change of backing store.
Map<String, Object?> encodeWay(CyclingWay way) => {
      'id': way.id,
      'name': way.name,
      'lat': [for (final p in way.points) p.latitude],
      'lon': [for (final p in way.points) p.longitude],
      'ele': way.elevationM,
      'surface': way.surface.name,
      'traffic': way.traffic.name,
      'safety': way.safety.name,
    };

CyclingWay? decodeWay(Object? row) {
  if (row is! Map) return null;
  final lat = (row['lat'] as List?)?.cast<num>();
  final lon = (row['lon'] as List?)?.cast<num>();
  final id = row['id'] as String?;
  if (id == null || lat == null || lon == null || lat.length != lon.length) {
    return null;
  }
  if (lat.length < 2) return null;

  final ele = (row['ele'] as List?)?.cast<num>();
  return CyclingWay(
    id: id,
    name: row['name'] as String?,
    points: [
      for (var i = 0; i < lat.length; i++)
        LatLng(lat[i].toDouble(), lon[i].toDouble()),
    ],
    // A stored elevation list that no longer matches the geometry is
    // dropped rather than lined up by index against the wrong points.
    elevationM: ele != null && ele.length == lat.length
        ? [for (final e in ele) e.toDouble()]
        : null,
    surface: _byName(SurfaceType.values, row['surface'], SurfaceType.asphalt),
    traffic: _byName(TrafficLevel.values, row['traffic'], TrafficLevel.unknown),
    safety: _byName(
        CyclingSafetyLevel.values, row['safety'], CyclingSafetyLevel.unknown),
  );
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
