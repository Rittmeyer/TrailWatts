# Feature 005: Workout Builder

## Purpose
Capture the rider's prescribed training stimulus as an ordered workout timeline
that Feature 006 can match against real terrain.

## Functional requirements
1. A workout MUST contain one or more blocks.
2. Each work block MUST define: zone, duration, repetitions, target metric
   (watts or heart rate), and the corresponding target range.
3. Repeated work MUST define recovery duration; recovery is part of the
   workout, not an implicit gap.
4. The system MUST expand blocks into an ordered `WorkoutTimelineStep` list:
   work → recovery → work → recovery, preserving order and duration.
5. A single non-repeated block MUST be valid with no recovery.
6. The builder MUST use exactly one search-area map. The map selects a
   center/radius, not a route.
7. Before route generation, the rider MUST be able to choose a route
   preference: best workout match, safest, fastest, most climbing, or balanced.
8. The rider MUST choose or accept a route-type preference: any, loop,
   out-and-back, or point-to-point.
9. The builder MUST pass the complete timeline, rider profile, and
   `RouteSearchContext` to Feature 006.

## Matching implications
The route engine MUST match the sequence of work and recovery steps, not only
the aggregate number of watts or total duration. A 3×10 min Z4 workout is not
equivalent to 30 continuous minutes of Z3/Z4.

## Key entities
- `WorkoutBlock`
- `WorkoutTimelineStep`
- `SearchArea`
- `RouteSearchContext`

## Open decisions
- Maximum block count: recommended warning at 12, hard maximum TBD.
- Default search radius: prototype uses 8 km; user confirmation required.
- Whether warm-up/cool-down should be explicit blocks (recommended: yes).
