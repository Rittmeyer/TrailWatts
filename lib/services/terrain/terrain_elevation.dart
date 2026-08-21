import 'package:latlong2/latlong.dart';

import 'elevation_service.dart';
import 'terrain_index.dart';

/// Heights for the points a route actually uses.
///
/// Deliberately not "heights for the area": the elevation API allows a
/// hundred points per call and one call a second, so asking for every node
/// of every road within the search radius costs minutes per search and eats
/// a day's quota in one go. A candidate route is a few hundred points; an
/// urban 8 km radius is tens of thousands.
///
/// What is already known is never asked for again - the memo lives in the
/// index, so it outlives any one search.
class TerrainElevation {
  final ElevationService service;
  final TerrainIndex index;

  const TerrainElevation({required this.service, required this.index});

  /// Fetches whatever is missing and remembers it.
  Future<void> prefetch(List<LatLng> points) async {
    final wanted = <LatLng>[];
    final seen = <String>{};
    for (final point in points) {
      if (index.elevationAt(point) != null) continue;
      // The same node appears in several ways, and a chain doubles back on
      // itself, so a route asks for the same point many times over.
      if (!seen.add('${point.latitude},${point.longitude}')) continue;
      wanted.add(point);
    }
    if (wanted.isEmpty) return;

    final values = await service.elevationsFor(wanted);
    for (var i = 0; i < wanted.length && i < values.length; i++) {
      final value = values[i];
      if (value != null) index.rememberElevation(wanted[i], value);
    }
  }

  double? at(LatLng point) => index.elevationAt(point);
}
