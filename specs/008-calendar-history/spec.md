# Feature 008: Training Calendar & History

## Purpose
Show planned and completed sessions and expose prediction-vs-actual data for
later calibration.

## Requirements
1. Calendar entries have exactly one state: planned or completed.
2. Completed sessions use normalized `HistoryEntry` data.
3. Show target vs realized watts AND target vs realized duration where available.
4. Show source: Strava, Garmin, Wahoo, or Manual.
5. "Precision" MUST be renamed in the domain to `predictionAccuracy` and
   its formula is owned by Feature 009. The UI may show a simple percentage.
6. Week/month views share the same day-detail component.
7. Zone taxonomy is always Feature 007's shared taxonomy.

## Open decisions
- Exact predictionAccuracy formula belongs to Feature 009.
- Whether manually seeded history is allowed in MVP: recommended yes.
