import 'package:flutter_test/flutter_test.dart';
import 'package:trailwatt/models/route_suggestion.dart';

void main() {
  test('match percentage is derived from the weighted score', () {
    const score = RouteScoreBreakdown(
      intensityMatchPct: 100,
      durationMatchPct: 100,
      sequenceMatchPct: 100,
      continuityScorePct: 100,
      safetyScorePct: 100,
      trafficScorePct: 100,
      surfaceScorePct: 100,
      practicalityScorePct: 100,
    );

    const route = RouteSuggestion(
      id: 'r1',
      name: 'Test route',
      routeType: RouteType.loop,
      distanceM: 10000,
      elevationGainM: 500,
      estimatedMovingTimeMin: 30,
      score: score,
    );

    expect(route.matchPct, 100);
  });

  test('weighted score uses the documented default weights', () {
    const score = RouteScoreBreakdown(
      intensityMatchPct: 100,
      durationMatchPct: 80,
      sequenceMatchPct: 60,
      continuityScorePct: 40,
      safetyScorePct: 100,
      trafficScorePct: 80,
      surfaceScorePct: 100,
      practicalityScorePct: 60,
    );

    expect(score.weightedScorePct, 77);
  });

  test('unknown safety is not the same as a safety warning', () {
    const route = RouteSuggestion(
      id: 'r2',
      name: 'Unknown safety',
      routeType: RouteType.loop,
      distanceM: 1000,
      elevationGainM: 10,
      estimatedMovingTimeMin: 5,
      score: RouteScoreBreakdown(
        intensityMatchPct: 80,
        durationMatchPct: 80,
        sequenceMatchPct: 80,
        continuityScorePct: 80,
        safetyScorePct: 50,
        trafficScorePct: 80,
        surfaceScorePct: 80,
        practicalityScorePct: 80,
      ),
      path: [RouteSegment(id: 's1', lat: 0, lng: 0)],
    );

    expect(route.hasMissingSafetyData, isTrue);
    expect(route.hasSafetyWarning, isFalse);
  });
}
