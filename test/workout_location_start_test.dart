import 'package:flutter/material.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailwatt/screens/workout_location_screen.dart';
import 'package:trailwatt/services/geocoding_service.dart';

import 'l10n_harness.dart';

/// A geocoder that answers from a list, so the screen can be driven without
/// a network and without waiting out Nominatim's rate limit.
class FakeGeocoder implements GeocodingService {
  final GeocodingResult result;
  final List<String> queries = [];
  LatLng? lastNear;

  FakeGeocoder(this.result);

  @override
  Future<GeocodingResult> search(String query, {LatLng? near}) async {
    queries.add(query);
    lastNear = near;
    return result;
  }
}

const _places = GeocodingResult([
  GeocodedPlace(
      name: 'Parque Ibirapuera',
      address: 'Parque Ibirapuera, São Paulo',
      point: LatLng(-23.5874, -46.6576)),
  GeocodedPlace(
      name: 'Parque Villa-Lobos',
      address: 'Parque Villa-Lobos, São Paulo',
      point: LatLng(-23.5455, -46.7229)),
]);

void main() {
  final t = stringsFor(const Locale('pt'));

  Future<FakeGeocoder> pumpScreen(WidgetTester tester,
      [GeocodingResult? result]) async {
    final geocoder = FakeGeocoder(result ?? _places);
    await tester
        .pumpWidget(localized(WorkoutLocationScreen(geocoder: geocoder)));
    await tester.pump();
    return geocoder;
  }

  group('typing where you want to start', () {
    testWidgets('a short query is not searched', (tester) async {
      final geocoder = await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'ib');
      await tester.pump(const Duration(milliseconds: 600));
      expect(geocoder.queries, isEmpty,
          reason: 'two letters would search every prefix typed on the way');
    });

    testWidgets('typing shows the places found', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'ibirapuera');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Parque Ibirapuera'), findsOneWidget);
      expect(find.text('Parque Villa-Lobos'), findsOneWidget);
    });

    testWidgets('the search is biased to where the rider is looking',
        (tester) async {
      final geocoder = await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'centro');
      await tester.pump(const Duration(milliseconds: 600));
      expect(geocoder.lastNear, isNotNull);
    });

    testWidgets('choosing a place names it as the start', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'ibirapuera');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      await tester.tap(find.text('Parque Ibirapuera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(t.locationStartAt('Parque Ibirapuera')), findsOneWidget);
      // The list closes once a choice is made.
      expect(find.text('Parque Villa-Lobos'), findsNothing);
    });

    testWidgets('nothing found says so', (tester) async {
      await pumpScreen(tester, const GeocodingResult([]));
      await tester.enterText(find.byType(TextField).first, 'lugar nenhum');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text(t.locationSearchEmpty), findsOneWidget);
    });

    testWidgets(
        'a search that did not run reads differently from one that '
        'found nothing', (tester) async {
      await pumpScreen(
          tester, const GeocodingResult.failed(GeocodingFailure.network));
      await tester.enterText(find.byType(TextField).first, 'centro');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text(t.locationSearchFailed), findsOneWidget);
      expect(find.text(t.locationSearchEmpty), findsNothing);
    });
  });

  group('dragging the pin', () {
    testWidgets('the start pin is draggable, not a fixed marker',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(DragMarkers), findsOneWidget,
          reason: 'a plain Marker cannot be dragged');

      final markers = tester.widget<DragMarkers>(find.byType(DragMarkers));
      expect(markers.markers, hasLength(1));
      expect(markers.markers.single.onDragEnd, isNotNull,
          reason: 'dropping the pin has to move the search');
    });

    testWidgets('moving the pin clears a place chosen by name', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField).first, 'ibirapuera');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.tap(find.text('Parque Ibirapuera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(t.locationStartAt('Parque Ibirapuera')), findsOneWidget);

      // Drop the pin somewhere else: the label would now be a lie.
      final marker =
          tester.widget<DragMarkers>(find.byType(DragMarkers)).markers.single;
      marker.onDragEnd!(DragEndDetails(), const LatLng(-23.50, -46.60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(t.locationStartAt('Parque Ibirapuera')), findsNothing);
      expect(find.text(t.locationHint(8)), findsOneWidget);
    });
  });
}
