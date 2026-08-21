# Feature 011: Route Search Decomposition

## Why this exists

Feature 006 defines what a good route match *is*. It does not say how to
find one, and the first implementation searched the wrong way: it walked a
greedy chain through everything inside a fixed radius and then matched the
whole timeline against it.

Two consequences, both measured rather than argued:

- **The repetition was thrown away before the search began.** The finder
  called `expandWorkout(flattenBlockGroups(plan))`, so `4x5min Z4` became
  four independent steps and the search hunted four separate pieces of
  terrain. A rider does four efforts on the same hill.
- **A long route was silently truncated.** Asked for 200 km, the search
  returned 79.6 km - the greedy walk hit a fixed hop cap - and reported it
  as a normal result.

The cost of searching also grew with the *area*, which is the wrong
variable: a 200 km ride does not need every road within 100 km, and a
4x5min session does not need more terrain than one 5-minute effort.

## The decomposition

Cost MUST scale with the number of **distinct stimuli**, not with the area
searched and not with the number of repetitions.

### 0. Estimate the distance from the workout, before any map

Each stimulus has a target and a duration. The power model already turns a
target into a speed on given terrain, so it turns a stimulus into a
distance:

`distance ~= solveSpeed(target, expected gradient) * duration`

This estimate sizes the search. It replaces the fixed radius and the
nominal 24 km/h the first implementation used. It is explicitly an
estimate: the real speed per stretch comes from the matcher.

### 1. Distinct stimuli, not steps

`4x(5min Z4 + 3min Z1)` is **two** distinct stimuli, not eight steps.
Stimuli are distinct by (metric, zone, target range, duration). Terrain is
searched once per distinct stimulus.

### 2. Candidates anchored at junctions

Junctions are the mesh's natural anchor points - where a rider can turn,
start an effort, or end one. Candidate stretches for a stimulus are found
between junctions, not at arbitrary offsets along a polyline.

### 3. Repetition is reuse, not a new search

A stimulus repeated N times reuses its stretch. The engine MUST evaluate
the shapes a repetition can take and score them:

- **out-and-back** on the same stretch, where the return doubles as the
  recovery between efforts (Feature 006 already treats a descent as valid
  recovery terrain);
- **a short loop** that re-enters the stretch each lap;
- **distinct stretches** per repetition, where the terrain offers them.

The engine picks the best-scoring shape **and says which it picked**. The
rider can choose another: a shape is a preference about how a session feels
to ride, and the engine has no way to know that preference. It MUST NOT be
decided silently.

Cost of a repetition is O(1) in N.

### 4. Transitions are connections, not searches

Between two different stimuli the rider has to get from one kind of terrain
to another - off the climb and onto the flat. That is a shortest path
between two anchor points in the junction graph, over a handful of anchors,
not another area scan.

### 5. Fetch along a corridor, not a radius

A radius query cannot serve a long route: an 8 km radius is already about
a megabyte of Overpass, and area grows with the square of the radius. Ground
is fetched as the plan extends - a corridor for a continuous ride, one local
area for an interval session.

## What the rider is told

A search that cannot deliver what was asked MUST say so rather than
returning a shorter route as if it were the answer. At minimum:

- requested distance versus what the terrain allowed;
- which repetition shape was chosen, and that it can be changed;
- how many distinct stimuli found terrain, and how many did not.

## Non-goals

- Turn-by-turn navigation.
- Perfect distance prediction. The estimate is for sizing the search; the
  matcher's per-stretch model is what the score is built on.
