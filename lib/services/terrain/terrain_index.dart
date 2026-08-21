import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'cycling_segment_source.dart';

/// A local store of rideable ground, indexed by position.
///
/// Two costs it exists to remove. Finding the ways near a point is a grid
/// lookup instead of a scan over everything ever fetched, which is what
/// keeps candidate building cheap as the store grows. And an area already
/// fetched is never fetched again - the network call is the expensive part
/// by orders of magnitude, and terrain does not change between rides.
///
/// The store is per-session. Keeping it across launches needs a storage
/// dependency this project has not taken yet - the same open decision as
/// persisting platform tokens, and recorded next to it.
class TerrainIndex {
  /// Grid step in degrees. 0.01 deg is roughly 1.1 km of latitude, so a
  /// typical 8 km search touches a couple of hundred cells - small enough
  /// to enumerate, large enough that cells hold useful numbers of ways.
  final double cellDegrees;

  /// Ways kept before the least recently used cells are dropped. A cap
  /// rather than unbounded growth: a rider panning across a country would
  /// otherwise accumulate a city's worth of geometry per pan.
  final int maxWays;

  final Map<String, CyclingWay> _ways = {};
  final Map<String, Set<String>> _cells = {};

  /// Which cells hold each way. Without it, evicting a cell has to scan
  /// every other cell to learn whether a way is still referenced, which
  /// turns a cleanup into a quadratic one exactly when the store is large.
  final Map<String, Set<String>> _wayCells = {};
  final Set<String> _fetched = {};
  final List<String> _cellOrder = [];

  /// Elevation already known for a rounded position, so the same ground is
  /// never asked for twice. Rounded to ~1 m of latitude: finer than any DEM
  /// this feeds on, coarse enough to actually hit.
  final Map<String, double> _elevation = {};

  TerrainIndex({this.cellDegrees = 0.01, this.maxWays = 20000});

  int get wayCount => _ways.length;
  int get cellCount => _cells.length;
  int get knownElevationPoints => _elevation.length;

  static String cellKey(double lat, double lon, double step) =>
      '${(lat / step).floor()}:${(lon / step).floor()}';

  static String _pointKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';

  /// Every cell the way passes through, so a long way is found from any
  /// point along it rather than only from where it starts.
  Iterable<String> _cellsOf(CyclingWay way) {
    final keys = <String>{};
    for (final point in way.points) {
      keys.add(cellKey(point.latitude, point.longitude, cellDegrees));
    }
    return keys;
  }

  void add(CyclingWay way) {
    _ways[way.id] = way;
    final keys = _cellsOf(way).toSet();
    _wayCells[way.id] = keys;
    for (final key in keys) {
      _cells.putIfAbsent(key, () {
        _cellOrder.add(key);
        return <String>{};
      }).add(way.id);
    }
    _evictIfNeeded();
  }

  void addAll(Iterable<CyclingWay> ways) {
    for (final way in ways) {
      add(way);
    }
  }

  void _evictIfNeeded() {
    while (_ways.length > maxWays && _cellOrder.isNotEmpty) {
      final oldest = _cellOrder.removeAt(0);
      final ids = _cells.remove(oldest) ?? const <String>{};
      _fetched.remove(oldest);
      for (final id in ids) {
        // Only drop a way once no remaining cell references it.
        final stillReferenced = _cells.values.any((cell) => cell.contains(id));
        if (!stillReferenced) _ways.remove(id);
      }
    }
  }

  /// The cells a circular search touches.
  List<String> cellsFor(LatLng centre, double radiusM) {
    // Longitude degrees shrink with latitude; using the latitude figure for
    // both would under-cover the east-west extent away from the equator.
    final latSpan = radiusM / 111320;
    final lonSpan = radiusM /
        (111320 * math.max(math.cos(centre.latitude * math.pi / 180), 0.01));

    final keys = <String>[];
    for (var lat = centre.latitude - latSpan;
        lat <= centre.latitude + latSpan + cellDegrees;
        lat += cellDegrees) {
      for (var lon = centre.longitude - lonSpan;
          lon <= centre.longitude + lonSpan + cellDegrees;
          lon += cellDegrees) {
        keys.add(cellKey(lat, lon, cellDegrees));
      }
    }
    return keys;
  }

  /// Ways with at least one point inside the circle.
  List<CyclingWay> near(LatLng centre, double radiusM) {
    const distance = Distance();
    final seen = <String>{};
    final out = <CyclingWay>[];
    for (final key in cellsFor(centre, radiusM)) {
      for (final id in _cells[key] ?? const <String>{}) {
        if (!seen.add(id)) continue;
        final way = _ways[id];
        if (way == null) continue;
        final touches = way.points
            .any((p) => distance.as(LengthUnit.Meter, centre, p) <= radiusM);
        if (touches) out.add(way);
      }
    }
    return out;
  }

  /// Cells of this search that have never been fetched.
  List<String> missingCells(LatLng centre, double radiusM) => [
        for (final key in cellsFor(centre, radiusM))
          if (!_fetched.contains(key)) key
      ];

  bool covers(LatLng centre, double radiusM) =>
      missingCells(centre, radiusM).isEmpty;

  void markFetched(LatLng centre, double radiusM) {
    for (final key in cellsFor(centre, radiusM)) {
      if (_cells.putIfAbsent(key, () {
        _cellOrder.add(key);
        return <String>{};
      }).isEmpty) {
        // An empty cell is a real answer - there is no rideable road there -
        // and recording it stops the same empty area being asked for again.
      }
      _fetched.add(key);
    }
  }

  double? elevationAt(LatLng point) => _elevation[_pointKey(point)];

  void rememberElevation(LatLng point, double metres) {
    _elevation[_pointKey(point)] = metres;
  }

  /// Fills in what is already known and reports what is still missing, so
  /// the caller asks the network only for points nothing has seen.
  ({List<double?> known, List<LatLng> missing}) elevationFor(
      List<LatLng> points) {
    final known = <double?>[];
    final missing = <LatLng>[];
    for (final point in points) {
      final value = elevationAt(point);
      known.add(value);
      if (value == null) missing.add(point);
    }
    return (known: known, missing: missing);
  }
}

/// A source that answers from the index whenever it can.
///
/// The wrapped source is only reached for ground nobody has looked at yet,
/// which is what makes repeated searches around the same start - the normal
/// case, since riders leave from the same few places - cost nothing.
class CachedSegmentSource implements CyclingSegmentSource {
  final CyclingSegmentSource source;
  final TerrainIndex index;

  CachedSegmentSource({required this.source, required this.index});

  /// Round trips made to the wrapped source. Read by tests, and the number
  /// the cache exists to keep at zero.
  int fetches = 0;

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async {
    if (index.covers(centre, radiusM)) {
      return SegmentFetch(index.near(centre, radiusM));
    }

    fetches++;
    final fetched = await source.waysAround(centre, radiusM);
    if (!fetched.ok) {
      // A failed fetch must not mark the area covered, or the failure would
      // be cached as "there is nothing here".
      final have = index.near(centre, radiusM);
      return have.isEmpty ? fetched : SegmentFetch(have);
    }

    index.addAll(fetched.ways);
    index.markFetched(centre, radiusM);
    return SegmentFetch(index.near(centre, radiusM));
  }
}
