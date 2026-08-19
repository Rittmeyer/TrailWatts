# Trailwatt — Audit V3 Corrections

- Removed invalid `TerrainTargetResult.distanceM`.
- Added `RouteStart` and explicit route start source.
- Added elevation to `RouteSegment`.
- Added source/freshness metadata for enriched route data.
- Added calibration models and separated model state from confidence.
- Added platform integration models matching Feature 002.
- Centralized route score calculation and made `matchPct` derived.
- Added timeline step IDs and interval IDs.
- Replaced string zone references with the shared `Zone` enum.
- Replaced ambiguous HR-zone map with a typed `HeartRateZones` model.
- Added drivetrain efficiency to `RiderProfile`.
- Distinguished unknown safety from an actual safety warning.
- Removed silent 15-minute auto-confirmation of imported activities because
  it weakens user trust; candidate activities require explicit confirmation.
- Added Flutter tests covering score derivation, workout timeline expansion,
  and terrain-option distance ownership.
