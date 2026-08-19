import 'route_suggestion.dart';

enum RoutePreference {
  balanced,
  safest,
  bestWorkoutMatch,
  fastest,
  mostClimbing,
}

enum RouteStartSource { currentLocation, savedLocation, mapSelection }

class RouteStart {
  final double lat;
  final double lng;
  final RouteStartSource source;

  const RouteStart({
    required this.lat,
    required this.lng,
    required this.source,
  });
}

class SearchArea {
  final double centerLat;
  final double centerLng;
  final double radiusM;

  const SearchArea({
    required this.centerLat,
    required this.centerLng,
    required this.radiusM,
  }) : assert(radiusM > 0);
}

class RouteSearchContext {
  final RouteStart start;
  final SearchArea area;
  final RoutePreference preference;
  final RouteTypePreference routeTypePreference;

  const RouteSearchContext({
    required this.start,
    required this.area,
    this.preference = RoutePreference.bestWorkoutMatch,
    this.routeTypePreference = RouteTypePreference.loop,
  });
}

enum RouteTypePreference { any, loop, outAndBack, pointToPoint }
