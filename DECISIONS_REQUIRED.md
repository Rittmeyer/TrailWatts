# Trailwatt — Inputs Still Required Before Production

The spec-kit is now internally consistent enough to implement the core
product. The remaining items below are external/product decisions rather than
known model contradictions. They are intentionally not invented as facts.

## P0 — required before production route matching

| Decision | Why it matters | Current safe default |
|---|---|---|
| Candidate map/road data source | Determines geometry, surfaces and road class | OSM + a routing engine, subject to licensing review |
| Cycling safety model | Traffic volume alone is not safety | Keep safety separate; start with road class + cycling infrastructure |
| Generic CdA | Strong effect on flat-road predictions | 0.32 provisional, labeled generic |
| Generic Crr by surface | Strong effect on rolling resistance | Document empirical defaults before release |
| Drivetrain efficiency | Affects predicted power | 0.975 provisional, configurable |
| Generic HR→%FTP mapping | HR is not an exact watt equivalent | Coach/physiology review required |
| Minimum acceptable match | Defines when to say "no suitable route" | 75% warning / 85% preferred, provisional |
| Score weights | Determines what "best" means | Current 25/15/15/15/10/5/5/10, validate with athletes |
| Search radius | Controls candidate availability and performance | 8 km prototype default, rider-editable |
| Route type default | Changes route geometry | Loop for structured training, rider-editable |
| Calibration threshold | Prevents noisy personalization | Multiple high-quality observations; exact rule TBD |
| Platform API capabilities | Determines export/import reality | Verify per platform before implementation freeze |

## P1 — needed before polished UX

- Maximum workout block count.
- Whether warm-up/cool-down are explicit blocks (recommended: yes).
- Exact interruption tolerance by workout type.
- Whether riders can exclude road classes, gravel or steep gradients.
- Definition of "fastest": moving time vs total elapsed time.
- Whether live traffic is available/affordable at MVP.
- Traffic cache TTL.
- Data retention policy for imported activity fields.
- Whether manual completed activities can seed calibration.
- Candidate expiration policy for unconfirmed imported activities.

## P2 — future refinement

- Tire model and tire pressure.
- Rider position/aero profile.
- Equipment/bottle mass.
- Surface quality beyond coarse type.
- Temperature/air density.
- Automatic FTP estimation.
- Advanced training-load metrics.

## Already decided in the current spec

- `matchPct` is derived from the documented weighted score.
- Terrain result does not own a single distance; distance belongs to each
  `TerrainOption`.
- Workout matching operates on an explicit timeline including recovery.
- Route matching references a specific timeline step/interval, not only a
  zone label.
- A route has an explicit start point and route-type preference.
- Traffic and cycling safety are distinct signals.
- Unknown safety is not treated as low risk.
- Manual route edits trigger a re-score and a warning if the score falls
  materially.
- Imported activity matches require rider confirmation; the app does not
  silently auto-confirm a completed result.
- Generic/calibrated/stale model state is distinct from confidence.
- Historical predictions must retain their calibration/model state.
