import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// The distance calculation this app uses everywhere.
///
/// `const Distance()` defaults to **Vincenty**, an iterative geodesic
/// solution accurate to millimetres over thousands of kilometres. Nothing
/// here needs that: the longest single measurement is the gap between two
/// samples of a road. Measured over 200,000 calls, Vincenty costs 83 ms and
/// Haversine 21 ms for a difference no rider could see.
const geoDistance = Distance(calculator: Haversine());

double metresBetween(LatLng a, LatLng b) =>
    geoDistance.as(LengthUnit.Meter, a, b);

/// A flat-earth approximation, for deciding rather than reporting.
///
/// Fourteen times cheaper than Vincenty and about half a percent off at the
/// spacings a road is sampled at. That is fine for "is this way inside the
/// circle" and wrong for "how long is this route", so it is used only where
/// the answer steers a choice and never where it is shown to the rider.
double approxMetresBetween(LatLng a, LatLng b) {
  const earthRadiusM = 6371000.0;
  const toRad = math.pi / 180;
  final lat1 = a.latitude * toRad;
  final lat2 = b.latitude * toRad;
  final x = (b.longitude - a.longitude) * toRad * math.cos((lat1 + lat2) / 2);
  final y = lat2 - lat1;
  return math.sqrt(x * x + y * y) * earthRadiusM;
}
