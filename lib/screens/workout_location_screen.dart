import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../engine/workout_demand.dart';
import '../models/search_context.dart';
import '../models/workout_block.dart';
import '../services/geocoding_service.dart';
import '../services/rider_profile_store.dart';
import '../services/route_suggestion_store.dart';
import '../services/routing_service.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/layout.dart';
import '../theme/app_text_styles.dart';
import '../widgets/page_header.dart';
import '../widgets/map_layers.dart';
import '../widgets/trailwatt_button.dart';
import '../widgets/trailwatt_field.dart';

/// Port of screen 02b(3/3) - "Onde treinar". One map for the whole
/// workout, whatever the number of blocks above. The radius is
/// rider-editable, 8 km by default per DECISIONS_REQUIRED.md.
///
/// Three ways to say where to start, because on a map they are not
/// interchangeable: drag the pin when the right spot is in view, tap when
/// it is further off, and type when the rider knows the name of the place
/// but not where it sits on the map. Whichever is used, the point settles
/// onto the nearest road, so the search is always centred somewhere
/// rideable.
class WorkoutLocationScreen extends StatefulWidget {
  final GeocodingService? geocoder;

  const WorkoutLocationScreen({super.key, this.geocoder});

  @override
  State<WorkoutLocationScreen> createState() => _WorkoutLocationScreenState();
}

class _WorkoutLocationScreenState extends State<WorkoutLocationScreen> {
  LatLng _center = const LatLng(-23.5505, -46.6333);
  double _radiusKm = 8;

  final _routing = OsrmRoutingService();
  late final GeocodingService _geocoder =
      widget.geocoder ?? NominatimGeocodingService();

  final _searchController = TextEditingController();
  final _mapController = MapController();

  /// The workout this search is for, handed over by the builder. Without
  /// it there is nothing to match ground against.
  List<WorkoutBlockGroup> _plan = const [];

  bool _snapping = false;
  bool _generating = false;
  bool _searching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is List<WorkoutBlockGroup>) {
      _plan = argument;
      // The rider arrived with a workout and a pin already on the map, so
      // the guess about what they will ask for is already a good one.
      _warmGround();
    }
  }

  /// Runs the real search and only then opens the map. Navigating first and
  /// searching there would show an empty map that fills in later, which
  /// reads as a broken screen rather than as a search in progress.
  Future<void> _generate() async {
    setState(() => _generating = true);
    await RouteSuggestionStore.instance.search(
      context: RouteSearchContext(
        start: RouteStart(
          lat: _center.latitude,
          lng: _center.longitude,
          source: _chosenPlace == null
              ? RouteStartSource.mapSelection
              : RouteStartSource.savedLocation,
        ),
        area: SearchArea(
          centerLat: _center.latitude,
          centerLng: _center.longitude,
          radiusM: _radiusKm * 1000,
        ),
      ),
      plan: _plan,
    );
    if (!mounted) return;
    setState(() => _generating = false);
    Navigator.of(context).pushNamed('/route-map');
  }

  Timer? _debounce;
  List<GeocodedPlace> _results = const [];
  GeocodingFailure? _searchFailure;

  /// The place the rider chose by name, kept so the field can say where the
  /// pin is rather than leaving them to read coordinates. Cleared as soon as
  /// they move the pin themselves, because it would then be a lie.
  String? _chosenPlace;

  @override
  void dispose() {
    _prefetch?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Typing runs the search, but not on every keystroke: Nominatim's policy
  /// is one request a second, and a request per letter would burn it on
  /// prefixes nobody meant to search for.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _results = const [];
        _searchFailure = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce =
        Timer(const Duration(milliseconds: 450), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final result = await _geocoder.search(query, near: _center);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = result.places;
      _searchFailure = result.failure;
    });
  }

  Future<void> _choosePlace(GeocodedPlace place) async {
    setState(() {
      _results = const [];
      _chosenPlace = place.name;
      _searchController.text = place.name;
    });
    await _moveTo(place.point, keepPlaceName: true);
    _mapController.move(_center, 13);
  }

  /// Put the pin somewhere and settle it onto the nearest road, so the
  /// search starts from somewhere the rider can actually ride. Shared by
  /// all three ways of choosing a start.
  Future<void> _moveTo(LatLng point, {bool keepPlaceName = false}) async {
    setState(() {
      _center = point;
      _snapping = true;
      if (!keepPlaceName) {
        // The pin no longer stands where the named place was.
        _chosenPlace = null;
        _searchController.clear();
        _results = const [];
        _searchFailure = null;
      }
    });
    final snapped = await _routing.snapToRoad(point);
    if (!mounted) return;
    setState(() {
      _center = snapped.point;
      _snapping = false;
    });
    _warmGround();
  }

  /// Starts fetching the ground around the pin while the rider is still
  /// looking at the map. Debounced, because a rider dragging the pin across
  /// a city would otherwise fire a query per stop.
  void _warmGround() {
    if (_plan.isEmpty) return;
    _prefetch?.cancel();
    _prefetch = Timer(const Duration(milliseconds: 1200), () {
      final demand =
          WorkoutDemand.of(_plan, RiderProfileStore.instance.profile);
      RouteSuggestionStore.instance.prefetchAround(
        _center,
        math.max(
            _radiusKm * 1000, demand.searchRadiusM(RepetitionShape.outAndBack)),
      );
    });
  }

  Timer? _prefetch;

  /// What the field says under itself. A search that found nothing and a
  /// search that did not run are different messages: the first is an
  /// answer, the second is not.
  String? _searchHelper(AppLocalizations t) {
    if (_searching) return t.locationSearchBusy;
    if (_searchFailure != null) return t.locationSearchFailed;
    if (_searchController.text.trim().length >= 3 && _results.isEmpty) {
      return t.locationSearchEmpty;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      body: ContentWidth(
          maxWidth: ContentWidth.wide,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: t.locationTitle,
                    subtitle: t.locationSubtitle,
                    backTo: t.builderTitle,
                  ),
                  const SizedBox(height: 12),
                  Text(t.locationWhere,
                      style: AppTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TrailwattField(
                    label: t.locationSearchLabel,
                    hint: t.locationSearchHint,
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    helperText: _searchHelper(t),
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 168),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, i) {
                          final place = _results[i];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(place.name,
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(place.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTextStyles.label.copyWith(fontSize: 10)),
                            onTap: () => _choosePlace(place),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _center,
                              initialZoom: 12,
                              onTap: (tapPosition, point) => _moveTo(point),
                            ),
                            children: [
                              trailwattTileLayer(),
                              CircleLayer(circles: [
                                CircleMarker(
                                  point: _center,
                                  radius: _radiusKm * 1000,
                                  useRadiusInMeter: true,
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderColor: AppColors.accent,
                                  borderStrokeWidth: 1.5,
                                ),
                              ]),
                              // Draggable rather than a plain marker: the
                              // same handle the route editor uses for
                              // waypoints, so dragging a point on a map
                              // behaves the same way everywhere in the app.
                              DragMarkers(markers: [
                                DragMarker(
                                  key: const ValueKey('start-pin'),
                                  point: _center,
                                  size: const Size(44, 44),
                                  onDragEnd: (_, point) => _moveTo(point),
                                  builder: (context, point, isDragging) => Icon(
                                    Icons.location_on,
                                    color: isDragging
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    size: isDragging ? 40 : 34,
                                  ),
                                ),
                              ]),
                              trailwattAttribution(context),
                            ],
                          ),
                          if (_snapping)
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              ),
                            ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _chosenPlace == null
                                    ? t.locationHint(_radiusKm.round())
                                    : t.locationStartAt(_chosenPlace!),
                                style:
                                    AppTextStyles.label.copyWith(fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 3,
                    max: 20,
                    divisions: 17,
                    activeColor: AppColors.accent,
                    label: '${_radiusKm.round()} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                  const SizedBox(height: 8),
                  TrailwattButton(
                    label: _generating ? t.routeSearching : t.locationGenerate,
                    onPressed: _generating ? null : _generate,
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
