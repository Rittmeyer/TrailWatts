import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/models/search_context.dart';
import 'package:trailwatt/models/workout_block.dart';
import 'package:trailwatt/models/zone.dart';
import 'package:trailwatt/screens/route_map_screen.dart';
import 'package:trailwatt/screens/workout_builder_screen.dart';
import 'package:trailwatt/services/route_suggestion_store.dart';
import 'package:trailwatt/services/terrain/cycling_segment_source.dart';
import 'package:trailwatt/services/workout_plan_store.dart';
import 'package:trailwatt/widgets/zone_pill.dart';

import 'l10n_harness.dart';

class _Ground implements CyclingSegmentSource {
  final List<CyclingWay> ways;
  const _Ground(this.ways);

  @override
  Future<SegmentFetch> waysAround(LatLng centre, double radiusM) async =>
      SegmentFetch(ways);
}

/// Ways meeting end to end, climbing then descending, so the matcher has
/// somewhere to put work and somewhere to put recovery.
List<CyclingWay> ground() {
  final out = <CyclingWay>[];
  var lat = -23.55;
  var base = 700.0;
  for (var w = 0; w < 8; w++) {
    final up = w.isEven;
    final points = <LatLng>[];
    final ele = <double>[];
    for (var i = 0; i < 20; i++) {
      points.add(LatLng(lat + i * (100 / 111320), -46.63));
      ele.add(base + i * (up ? 6 : -6));
    }
    out.add(CyclingWay(
        id: 'w$w', name: 'Trecho $w', points: points, elevationM: ele));
    lat = points.last.latitude;
    base = ele.last;
  }
  return out;
}

WorkoutBlockGroup stimulus(
        WorkoutBlockRole role, int minutes, int zone, int minW, int maxW) =>
    WorkoutBlockGroup(stimuli: [
      WorkoutBlock(
        zone: TrainingZone(
            metric: ZoneMetric.power, scale: ZoneScale.five, index: zone),
        durationMin: minutes,
        role: role,
        target: WorkoutTarget(
            metric: ZoneMetric.power, minValue: minW, maxValue: maxW),
      ),
    ]);

const searchArea = RouteSearchContext(
  start: RouteStart(
      lat: -23.55, lng: -46.63, source: RouteStartSource.mapSelection),
  area: SearchArea(centerLat: -23.55, centerLng: -46.63, radiusM: 8000),
);

Future<void> searchFor(List<WorkoutBlockGroup> plan) async {
  RouteSuggestionStore.instance.useSource(_Ground(ground()));
  await RouteSuggestionStore.instance.search(context: searchArea, plan: plan);
}

void main() {
  final t = stringsFor(const Locale('pt'));

  group('the map follows the workout', () {
    testWidgets('the drawn route is the route that was found', (tester) async {
      await searchFor([stimulus(WorkoutBlockRole.work, 5, 4, 220, 245)]);

      await tester.pumpWidget(localized(const RouteMapScreen()));
      await tester.pump();

      final polyline = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      final drawn = polyline.polylines.single.points;
      final found = RouteSuggestionStore.instance.selected!.suggestion.path;

      expect(drawn, hasLength(found.length),
          reason: 'the map used to draw three fixed points in one street '
              'whatever the engine had found');
      expect(drawn.first.latitude, closeTo(found.first.lat, 1e-9));
    });

    testWidgets('the zone shown is the zone the session asked for',
        (tester) async {
      await searchFor([stimulus(WorkoutBlockRole.work, 5, 4, 220, 245)]);
      await tester.pumpWidget(localized(const RouteMapScreen()));
      await tester.pump();
      final z4 = tester.widget<ZonePill>(find.byType(ZonePill)).zone.index;

      await searchFor([stimulus(WorkoutBlockRole.work, 5, 2, 120, 150)]);
      await tester.pumpWidget(localized(const RouteMapScreen()));
      await tester.pump();
      final z2 = tester.widget<ZonePill>(find.byType(ZonePill)).zone.index;

      expect(z4, 4);
      expect(z2, 2,
          reason: 'the zone was a fixed 180 w demo value, so it never moved');
    });
  });

  group('saving does not go through the map', () {
    testWidgets('a workout can be saved from the builder alone',
        (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      WorkoutPlanStore.instance.removePlanned(today);

      await tester.pumpWidget(localized(
        const WorkoutBuilderScreen(),
        routes: {'/home': (_) => const Scaffold(body: Text('home'))},
      ));
      await tester.pumpAndSettle();

      final save = find.text(t.builderSaveOnly);
      expect(save, findsOneWidget,
          reason: 'the only way to keep a workout was to go find a route');

      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(WorkoutPlanStore.instance.hasWorkout(today), isTrue);
      expect(find.text('home'), findsOneWidget,
          reason: 'saving finishes the job and returns to the app');
    });
  });
}
