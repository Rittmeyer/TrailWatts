# Feature 005: Workout Builder

## Purpose
Capture the rider's prescribed training stimulus as an ordered workout timeline
that Feature 006 can match against real terrain.

## Functional requirements
1. A workout MUST be an ordered list of one or more blocks, and that order
   IS the timeline.
2. Each block MUST define: role, zone, duration, target metric (watts or
   heart rate), and the corresponding target range.
3. Recovery MUST be a block of its own, not a field on a work block. A
   3×10 min Z4 workout with 5 min recovery is written Z4, Z1, Z4, Z1, Z4.
   Recovery is part of the workout, not an implicit gap, and counts towards
   its duration.
4. Blocks MUST carry a role - warm-up, work, recovery or cool-down - so the
   timeline still distinguishes work from recovery without inferring it from
   the zone. This settles the warm-up/cool-down open decision below.
5. The system MUST expand blocks into an ordered `WorkoutTimelineStep` list,
   one step per block, preserving order and duration. Only work steps carry
   an `intervalId`; nothing is matched to a recovery by interval.
6. A block MAY hold two or more stimuli (e.g. a work stimulus and its own
   recovery stimulus) authored and repeated together as one unit - a repeat
   group. A group still expands to the same physically real, ordered
   sequence of blocks as if every repeat had been typed out by hand (its
   stimuli, `repeatCount` times, in order): the repeat count is authoring
   convenience, not a new field the timeline has to interpret. See
   `WorkoutBlockGroup` in `lib/models/workout_block.dart`.
7. The builder MUST use exactly one search-area map. The map selects a
   center/radius, not a route.
8. Before route generation, the rider MUST be able to choose a route
   preference: best workout match, safest, fastest, most climbing, or balanced.
9. The rider MUST choose or accept a route-type preference: any, loop,
   out-and-back, or point-to-point.
10. The builder MUST pass the complete timeline, rider profile, and
   `RouteSearchContext` to Feature 006.

## Matching implications
The route engine MUST match the sequence of work and recovery steps, not only
the aggregate number of watts or total duration. A 3×10 min Z4 workout is not
equivalent to 30 continuous minutes of Z3/Z4.

## Key entities
- `WorkoutBlock`
- `WorkoutBlockRole`
- `WorkoutBlockGroup`
- `WorkoutTimelineStep`
- `SearchArea`
- `RouteSearchContext`

## Open decisions
- Maximum block count: recommended warning at 12, hard maximum TBD. Writing
  recovery out as blocks makes lists longer, so revisit this number - now
  counted in repeat groups, since a 4×(Z4+Z1) group is one authored block.
- Default search radius: prototype uses 8 km; user confirmation required.

## Resolved decisions
- Repeat group (e.g. 4× over a Z4+Z1 pair), so long interval sessions do not
  need every block typed out: added as `WorkoutBlockGroup` (Requirement 6).
  The per-block "duplicate" action remains, for duplicating a whole group.
