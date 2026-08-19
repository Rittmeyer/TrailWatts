# Trailwatt — Final Domain Audit

## Status
**READY FOR CORE IMPLEMENTATION, with external decisions listed in
`DECISIONS_REQUIRED.md`.**

The second audit found several domain gaps and they have now been corrected.
The current model set is aligned with the Constitution and the core user
journey:

`prescribed workout → expanded timeline → physics estimate → route matching →
explanation → user edit → re-score → export → confirmed result → calibration`

## Corrections in this pass

1. Removed standalone distance from `TerrainTargetResult`.
2. Added explicit route start point/source.
3. Added elevation to route segments.
4. Added external source/freshness metadata to enriched segments.
5. Added `CalibrationObservation` and `CalibrationProfile`.
6. Added platform integration domain entities.
7. Made `matchPct` derived from `RouteScoreBreakdown`.
8. Added explicit interval IDs to timeline and route segments.
9. Replaced free-form matched zone strings with the shared `Zone` enum.
10. Replaced ambiguous HR-zone maps with `HeartRateZones`.
11. Added drivetrain efficiency to the rider physics constants.
12. Separated model state from model confidence.
13. Distinguished missing safety data from an actual safety warning.
14. Made the platform activity match require explicit rider confirmation.
15. Added executable Dart tests for the highest-risk model behavior.

## User-centered principle
The app must never hide uncertainty behind a single attractive percentage.
The rider should understand what was matched, what was estimated, what is
unknown, and what changed after an edit.

## Remaining limitation
The repository environment used for this audit does not contain the Dart or
Flutter SDK, so `dart analyze` and `flutter test` cannot be executed here.
The test suite is included and a structural/static validation was run locally
against the source files. The first machine with Flutter installed MUST run:

`flutter pub get`
`dart format --output=none --set-exit-if-changed lib test`
`flutter analyze`
`flutter test`

No domain blocker was found in the static validation after the corrections in
this pass.
