import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/rider_profile.dart';
import '../models/search_context.dart';
import '../models/workout_block.dart';
import 'calibration_store.dart';
import 'rider_profile_store.dart';
import 'terrain/cycling_segment_source.dart';
import 'terrain/elevation_service.dart';
import 'terrain/route_finder.dart';
import 'terrain/terrain_database.dart';
import 'terrain/terrain_elevation.dart';
import 'terrain/terrain_index.dart';

enum RouteSearchState { idle, searching, ready, failed }

/// The result of the last route search, shared by the screens that show it.
///
/// A store rather than a call inside a screen because two screens read the
/// same answer - the day's workout shows the pick, the map shows it in full -
/// and searching twice would mean two sets of network calls for one question.
///
/// The terrain index lives here too, so it outlives any one screen. That is
/// the whole point of it: a rider who searches, goes back, changes a block
/// and searches again pays for the ground once.
class RouteSuggestionStore extends ChangeNotifier {
  RouteSuggestionStore({
    CyclingSegmentSource? source,
    ElevationService? elevation,
    TerrainIndex? index,
    RiderProfile Function()? rider,
  })  : _index = index ?? TerrainIndex(database: TerrainDatabase.forPlatform()),
        _riderOf = rider ??
            (() => CalibrationStore.instance
                .effective(RiderProfileStore.instance.profile)) {
    _source = CachedSegmentSource(
      source: source ?? OverpassSegmentSource(),
      index: _index,
    );
    _elevation = TerrainElevation(
      service: elevation ?? OpenTopoElevationService(),
      index: _index,
    );
  }

  static final RouteSuggestionStore instance = RouteSuggestionStore();

  final TerrainIndex _index;
  final RiderProfile Function() _riderOf;
  late CachedSegmentSource _source;
  TerrainElevation? _elevation;

  RouteSearchState _state = RouteSearchState.idle;
  List<RankedSuggestion> _suggestions = const [];
  RouteSearchFailure? _failure;
  int _selected = 0;

  RouteSearchState get state => _state;
  List<RankedSuggestion> get suggestions => _suggestions;
  RouteSearchFailure? get failure => _failure;

  /// How many round trips the terrain cache has saved, for the diagnostics
  /// the README talks about rather than for the rider.
  int get sourceFetches => _source.fetches;
  int get knownWays => _index.wayCount;

  RankedSuggestion? get selected => _suggestions.isEmpty
      ? null
      : _suggestions[_selected.clamp(0, _suggestions.length - 1)];

  void select(int i) {
    if (i < 0 || i >= _suggestions.length) return;
    _selected = i;
    notifyListeners();
  }

  /// Reads back what earlier runs learned: which areas are already known,
  /// and the heights bought for them. Doing it at startup means the first
  /// search of the day does not wait for it.
  Future<void> warmUp() => _index.load();

  /// Ground the rider is probably about to ask for.
  ///
  /// The cold search is mostly waiting for Overpass, and by the time the
  /// pin has settled the app knows where they want to start and roughly how
  /// much ground the session needs. Fetching then, while they are still
  /// setting the radius or reading the map, is time the rider does not
  /// spend staring at a spinner. The cache means the real search finds it
  /// already there.
  ///
  /// Deliberately silent: nothing is notified, nothing fails visibly. A
  /// guess that does not pay off must cost the rider nothing.
  void prefetchAround(LatLng centre, double radiusM) {
    final key = '${centre.latitude.toStringAsFixed(3)},'
        '${centre.longitude.toStringAsFixed(3)},${radiusM.round()}';
    if (!_prefetched.add(key)) return;
    unawaited(_source.waysAround(centre, radiusM).catchError(
        (_) => const SegmentFetch.failed(SegmentFetchFailure.network)));
  }

  final Set<String> _prefetched = {};

  Future<void> search({
    required RouteSearchContext context,
    required List<WorkoutBlockGroup> plan,
  }) async {
    _state = RouteSearchState.searching;
    _failure = null;
    notifyListeners();

    final finder = RouteFinder(
      source: _source,
      rider: _riderOf(),
      elevation: _elevation,
    );
    final result = await finder.suggestionsFor(context: context, plan: plan);

    _suggestions = result.suggestions;
    _failure = result.failure;
    _selected = 0;
    _state = result.ok ? RouteSearchState.ready : RouteSearchState.failed;
    notifyListeners();
  }

  /// Test seam: point the store at ground a test controls, keeping the real
  /// search path - cache, finder, matcher - rather than seeding fake
  /// results past it.
  @visibleForTesting
  void useSource(CyclingSegmentSource source, {ElevationService? elevation}) {
    _source = CachedSegmentSource(source: source, index: _index);
    if (elevation != null) {
      _elevation = TerrainElevation(service: elevation, index: _index);
    }
  }

  /// Test seam: drop everything, including the cached ground.
  @visibleForTesting
  void reset() {
    _state = RouteSearchState.idle;
    _suggestions = const [];
    _failure = null;
    _selected = 0;
    notifyListeners();
  }
}
