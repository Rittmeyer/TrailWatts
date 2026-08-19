# Feature 006: Route Recommendation & Map Display

## User outcome
A rider should be able to look at a recommended route and understand, in
plain language, why it can execute the prescribed workout. A high score MUST
represent training usefulness, not just geometric similarity.

## Route matching engine
Route matching is a first-class engine capability. It consumes the expanded
`WorkoutTimelineStep` sequence, rider profile, route search context and
candidate road data. It MUST evaluate:
1. intensity match;
2. work-duration match;
3. sequence/order match;
4. recovery feasibility;
5. terrain continuity;
6. traffic;
7. cycling safety;
8. surface suitability;
9. route practicality;
10. requested route type and rider preference.

### Score formula
The default score is a weighted average of eight normalized components,
each from 0 to 100:

`score = round(0.25*intensity + 0.15*duration + 0.15*sequence +\
0.15*continuity + 0.10*safety + 0.05*traffic + 0.05*surface +\
0.10*practicality)`

The implementation MUST use the same formula as `RouteScoreBreakdown`.
`RouteSuggestion.matchPct` is derived from the breakdown and MUST NOT be
supplied independently by callers.

The weights are provisional until athlete/coach validation, but the formula
and component ranges are fixed for the MVP so results are reproducible.

### Component semantics
- **Intensity:** how closely predicted effort stays inside each step target.
- **Duration:** proportion of requested work/recovery duration that can be
  satisfied by suitable terrain.
- **Sequence:** whether the ordered timeline can be executed in the requested
  order.
- **Continuity:** quality of uninterrupted terrain for each relevant step.
- **Safety:** cycling suitability independent of traffic volume.
- **Traffic:** expected traffic-related interruption/speed penalty.
- **Surface:** suitability of the road surface for the rider/workout.
- **Practicality:** start proximity, route type fit, excessive detours,
  excessive interruptions and other usability costs.

A component MUST NOT be awarded 100 simply because data is missing. Missing
critical data should reduce confidence and may cap the component score.

## Segment feasibility
A segment used for a work interval SHOULD satisfy the interval for its
required continuous duration. The matcher MUST account for:
- gradient profile, not only average gradient;
- travel direction;
- continuous rideable duration;
- junctions and traffic lights;
- achievable speed;
- surface;
- traffic;
- safety.

A segment match MUST reference the specific `WorkoutTimelineStep` or
`intervalId` it satisfies. A shared zone label alone is insufficient.

Descents MAY be valid recovery terrain. They MUST NOT be treated as failed
terrain merely because they cannot sustain the work target.

## Route context
`RouteSearchContext` MUST contain:
- a start point and its source;
- search area/radius;
- route preference;
- route-type preference (`loop`, `outAndBack`, `pointToPoint`, or `any`).

For structured training, `loop` is the default MVP preference because it
usually offers more predictable interval placement and a return to the start.
The rider may change it.

## Alternatives
The system SHOULD return several ranked alternatives when enough candidates
exist. Suggested labels:
- best workout match;
- safest;
- fastest;
- most climbing;
- balanced.

No label may imply that the route is universally best.

## User-facing explanation
Every suggestion SHOULD expose:
- overall match;
- interval count matched;
- continuous terrain available for each interval;
- expected interruptions;
- traffic/safety caveats;
- surface;
- route distance/elevation/time;
- whether the model is generic or calibrated.

Example:
"3/3 intervals matched · 11.7 min continuous terrain · 2 interruptions ·
low traffic · generic model."

## Map
Display:
- route;
- zone coloring;
- elevation profile;
- interval markers;
- traffic/safety warnings;
- start/end;
- route distance, elevation gain, moving time.

Elevation points MUST be present in the route data when an elevation profile
is shown.

## Editing
After any manual route edit, the matcher MUST recalculate the score. If the
score falls materially (default warning: >10 percentage points), the rider
MUST see a clear warning before export. The edited route is never silently
presented as equivalent to the original recommendation.

## Threshold behavior
The MVP uses a provisional threshold of 75% for "acceptable with warning" and
85% for "preferred". These values require athlete/coach validation.

If no candidate reaches the acceptable threshold, the app MUST say that no
sufficiently matched route was found and offer:
- widen search area;
- change route preference/type;
- accept a lower match with an explicit warning.

It MUST NOT silently return a misleading "best route".

## Failure / uncertainty behavior
Unknown traffic or safety data MUST be shown as unknown, not converted into a
false low-risk score. The user may still choose the route, but the uncertainty
must be visible.

## Key entities
`RouteSuggestion`, `RouteSegment`, `RouteScoreBreakdown`,
`RouteSearchContext`.

## Open decisions
- Final weights and thresholds require empirical validation.
- Candidate route data provider requires technical/commercial input.
- Safety model requires domain validation.
- Exact interruption tolerance per workout type requires athlete testing.
