import '../models/route_suggestion.dart';

/// Centralized route-score calculation. Keeping this pure makes it reusable
/// by the mobile app and future API implementation without UI dependencies.
class RouteScoreCalculator {
  const RouteScoreCalculator();

  int calculate(RouteScoreBreakdown score) => score.weightedScorePct;
}
