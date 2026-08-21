import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../engine/geo_distance.dart';
import 'cycling_segment_source.dart';
import 'terrain_database.dart';

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

  /// One box per way, so a lookup can reject most of them without measuring
  /// a distance to any of their points.
  final Map<String, _Box> _boxes = {};
  final Set<String> _fetched = {};
  final List<String> _cellOrder = [];

  /// Elevation already known for a rounded position, so the same ground is
  /// never asked for twice. Rounded to ~1 m of latitude: finer than any DEM
  /// this feeds on, coarse enough to actually hit.
  final Map<String, double> _elevation = {};

  /// Where the index is kept between runs. Always a cache: it may be empty,
  /// refused or stale, and the index has to work when it is.
  final TerrainDatabase database;

  TerrainIndex({
    this.cellDegrees = 0.01,
    this.maxWays = 20000,
    TerrainDatabase? database,
  }) : database = database ?? const NoTerrainDatabase();

  bool _loaded = false;

  /// Brings back what a previous run learned. Cheap to call more than once.
  ///
  /// Only the cell list and the heights are read up front: the cell list is
  /// what decides whether a search has to hit the network at all, and the
  /// heights are the expensive half - a thousand API calls a day, against
  /// geometry Overpass will hand back in one query. Ways are read per
  /// search, for the cells that search touches.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await database.open();
    _fetched.addAll(await database.fetchedCells());
    _elevation.addAll(await database.elevations());
  }

  /// Cells whose stored ways are already in memory, so the database is not
  /// read for them twice.
  final Set<String> _loadedCells = {};

  /// True when every cell of this area has already been read from the
  /// database in this run.
  bool hasLoadedArea(LatLng centre, double radiusM) {
    if (!_loaded) return false;
    for (final key in cellsFor(centre, radiusM)) {
      if (!_loadedCells.contains(key)) return false;
    }
    return covers(centre, radiusM);
  }

  /// Pulls the stored ways for an area into memory.
  Future<void> loadArea(LatLng centre, double radiusM) async {
    await load();
    _loadedCells.addAll(cellsFor(centre, radiusM));
    final stored = await database.waysIn(cellsFor(centre, radiusM));
    for (final way in stored) {
      // Straight into the maps: re-adding through add() would write them
      // back to the database they just came from.
      _ways[way.id] = way;
      final keys = _cellsOf(way).toSet();
      _wayCells[way.id] = keys;
      for (final key in keys) {
        _cells.putIfAbsent(key, () {
          _cellOrder.add(key);
          return <String>{};
        }).add(way.id);
      }
    }
  }

  /// Writes still in flight. The search does not wait for them - what it
  /// learned is already in memory, and the database is only for the next
  /// run - but a test has to be able to.
  final List<Future<void>> _writes = [];

  /// Waits for every write this index has started.
  @visibleForTesting
  Future<void> settle() async {
    while (_writes.isNotEmpty) {
      final pending = List<Future<void>>.from(_writes);
      _writes.clear();
      await Future.wait(pending);
    }
  }

  /// Records a write without putting it on anybody's critical path.
  void _write(Future<void> Function() action) {
    late final Future<void> future;
    future = action().whenComplete(() => _writes.remove(future));
    _writes.add(future);
  }

  /// Writes through what this search learned.
  void persist(Iterable<CyclingWay> ways, Iterable<String> cells) {
    if (ways.isNotEmpty) {
      _write(() => database.putWays(ways, (way) => _cellsOf(way).toSet()));
    }
    if (cells.isNotEmpty) _write(() => database.markCells(cells));
  }

  /// Heights learned since the last write.
  final Map<String, double> _unsavedElevation = {};

  void persistElevation() {
    if (_unsavedElevation.isEmpty) return;
    final batch = Map<String, double>.from(_unsavedElevation);
    _unsavedElevation.clear();
    _write(() => database.putElevations(batch));
  }

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
    _boxes[way.id] = _Box.of(way.points);
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
    final seen = <String>{};
    final out = <CyclingWay>[];
    for (final key in cellsFor(centre, radiusM)) {
      for (final id in _cells[key] ?? const <String>{}) {
        if (!seen.add(id)) continue;
        final way = _ways[id];
        if (way == null) continue;
        // A box test first: it rejects most ways without measuring a single
        // point, and only what survives pays for real distances.
        final box = _boxes[id];
        if (box != null && !box.mayReach(centre, radiusM)) continue;
        final touches =
            way.points.any((p) => approxMetresBetween(centre, p) <= radiusM);
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
    final key = _pointKey(point);
    _elevation[key] = metres;
    _unsavedElevation[key] = metres;
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

  /// Fetches already on their way, by area.
  ///
  /// Without this, a prefetch and the search it was meant to help both hit
  /// the network for the same ground - the guess costing a query instead of
  /// saving one. A second request for an area already in flight waits for
  /// that one.
  final Map<String, Future<SegmentFetch>> _inFlight = {};

  static String _areaKey(LatLng centre, double radiusM) =>
      '${centre.latitude.toStringAsFixed(3)},'
      '${centre.longitude.toStringAsFixed(3)},${radiusM.round()}';

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) {
    final key = _areaKey(centre, radiusM);
    final running = _inFlight[key];
    if (running != null) return running;

    final future = _fetch(centre, radiusM);
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  Future<SegmentFetch> _fetch(LatLng centre, double radiusM) async {
    // Memory first. Reading the database on a search whose ground is
    // already in hand was pure cost - a decode of every stored way in the
    // area, on every repeat search, for rows the index was already holding.
    if (index.hasLoadedArea(centre, radiusM)) {
      return SegmentFetch(index.near(centre, radiusM));
    }

    // Otherwise, what a previous run downloaded for this area.
    await index.loadArea(centre, radiusM);

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
    // Not awaited: thousands of rows for a city-sized area, and the search
    // already holds everything it needs. Making the rider wait for a write
    // that only helps their next search is the wrong trade.
    index.persist(fetched.ways, index.cellsFor(centre, radiusM));
    return SegmentFetch(index.near(centre, radiusM));
  }
}

/// The rectangle a way lives in.
class _Box {
  final double minLat, maxLat, minLon, maxLon;
  const _Box(this.minLat, this.maxLat, this.minLon, this.maxLon);

  factory _Box.of(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = minLat;
    var minLon = points.first.longitude, maxLon = minLon;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return _Box(minLat, maxLat, minLon, maxLon);
  }

  /// Generous on purpose: it may say yes to a way that turns out to be just
  /// outside, and must never say no to one that is inside.
  bool mayReach(LatLng centre, double radiusM) {
    final latPad = radiusM / 110000;
    final lonPad = radiusM /
        (110000 * math.max(math.cos(centre.latitude * math.pi / 180), 0.01));
    return centre.latitude >= minLat - latPad &&
        centre.latitude <= maxLat + latPad &&
        centre.longitude >= minLon - lonPad &&
        centre.longitude <= maxLon + lonPad;
  }
}
