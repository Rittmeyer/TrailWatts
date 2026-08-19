# Feature 002: Platform Integration — Strava, Garmin & Wahoo (Export + Result Import)

## Why

Trailwatt's primary goal is recommending the best place to work out — not
tracking the workout itself. Native GPS/power/HR recording is a large,
separate engineering effort with its own device-integration and
battery-life problems, and it duplicates what Garmin and Strava already do
well. For the initial release, the app closes the loop by integrating with
the platforms riders already use: export the suggested route to them, pull
the completed result back from them. Native tracking becomes an explicit
future option, not a v1 requirement — this feature is what makes that
deferral workable rather than a gap.

## User Story

As a rider who already records rides on Garmin or Strava, I want Trailwatt
to send my suggested route to whichever platform I use and automatically
pick up the result afterward, so that I get route recommendations without
switching away from the recording app I already trust.

## Scope

### In scope

- Export the suggested route as GPX to Strava, Garmin, and Wahoo. TCX/FIT are
  optional formats where the destination supports them. Use each platform's
  documented official integration when available; otherwise provide the
  platform's official file-import handoff. This MUST be available on every
  pricing tier (Constitution Article IV).
- After the rider completes the activity on their platform of choice,
  retrieve the matching completed activity through that platform's official
  read API (average power, average heart rate, duration) — scoped to the
  single activity that matches the exported route and time window, not a
  bulk historical import. This keeps the feature inside the Article II
  boundary: a single-activity round-trip, not a data import.
- Event-driven matching is preferred where the platform officially supports
webhooks/events for the required scope. The implementation MUST NOT assume
that Strava, Garmin, and Wahoo expose equivalent event capabilities. If a
platform lacks a compliant event mechanism, its fallback MUST be defined in
the implementation plan; the product MUST NOT invent scraping or undocumented
polling to preserve symmetry.
- Manual entry as the documented fallback when no platform connection
  exists or the automatic match fails, split into single-stimulus and
  interval-block entry — matching the workout's actual structure rather
  than forcing one average number onto a multi-block session.
- Connection management: connect or disconnect Strava, Garmin, and Wahoo
  independently from the rider's profile.

### Out of scope (this feature)

- Native in-app workout recording (GPS track, live power/HR capture) —
  Constitution Article III places this out of boundary entirely.
- Bulk or historical import of past activities from any connected
  platform.
- Live coaching or in-ride guidance.

### Explicitly deferred

- Optional native tracking, for riders who don't already use a connected
  platform. Recorded here so it isn't forgotten, but it stays out of scope
  until a dedicated amendment and its own spec make the case for it —
  this feature assumes platform integration is sufficient for v1.

## Functional Requirements

1. The system MUST generate a valid GPX file from a route suggestion.
   TCX/FIT MAY be added where supported without changing the GPX requirement.
2. The system MUST upload the generated file to the rider's connected
   platform(s) using each platform's official route/workout upload
   endpoint — never by simulating a browser session or scraping.
3. The system MUST record the export timestamp and route identifier so a
   later import can match the correct completed activity.
4. Where an official activity event/webhook exists and the required scope
   permits it, the system SHOULD subscribe to it. For platforms without
   such an official mechanism, the plan MUST define a compliant fallback
   rather than assuming polling or scraping is available.
5. **Event processing.** Where events are supported, the system MUST process
   an incoming activity-created event within 1 minute of receipt: check whether the
   event's activity corresponds to a recent `ExportedRoute` for that
   rider (by time window and route correspondence) and, if so, create or
   update the matching `ImportAttempt`.
6. **Match confirmation.** A candidate activity MUST NOT be silently saved as
   the rider's completed result. After a match is found, the UI SHOULD present
   the candidate with platform, start time, route correspondence and available
   metrics, allowing one-tap confirmation. A stale candidate MAY expire from
   the active confirmation queue after a bounded period, but it remains
   recoverable from the integration/history view.
7. **Multiple connected platforms.** More than one platform MAY produce a
   candidate for the same export. Candidates MUST be represented explicitly
   and matched by time window and route correspondence; arrival time alone
   MUST NOT determine correctness. The UI MAY suggest the highest-confidence
   candidate while retaining alternatives.
8. The system MUST present the manual-entry fallback — split by workout
   structure, one field for a continuous single-stimulus session, one
   field per block for an interval session — when no automatic match has
   been found through Requirements 4–7, available to the rider at any
   time as an alternative to waiting.
9. The system MUST let the rider connect or disconnect each platform
   independently; disconnecting one MUST NOT affect the others.
10. The system MUST NOT request OAuth scopes broader than exporting a
    route and reading a single matching activity requires.

## Key Entities

- **PlatformConnection** — `platform` (strava | garmin | wahoo),
  `riderId`, `connected`, `scopes`
- **ExportedRoute** — `routeId`, `platform`, `exportedAt`, `fileFormat`
- **ActivityCandidate** — `platform`, `activityId`, `eventReceivedAt` —
  one entry per matching activity-created event received across all
  connected platforms, ordered by when the event arrived.
- **ImportAttempt** — `exportedRouteId`, `status`
  (matched | no_match | manual), `candidates: List<ActivityCandidate>`
  (highest-confidence candidate first), `confirmedActivityId?`

## Success Criteria

- A rider with a connected Strava account exports a suggested route and,
  after completing and saving the activity in Strava, sees the result in
  Trailwatt with no manual entry.
- A rider with no connected platform still completes a workout and records
  the result manually, correctly split between single-stimulus and
  interval entry.
- No platform connection requests read access beyond a single matching
  activity — verifiable by inspecting the OAuth scope requested at
  connect time.
- An incoming activity-created event is processed — matched or ruled out
  against a recent `ExportedRoute` — within 1 minute of receipt,
  verifiable with a test that measures elapsed time from a simulated
  webhook call to the resulting `ImportAttempt` update.
- A match found by an integration is presented for explicit rider confirmation
  and is never silently written as a completed result.
- With two platforms connected and both sending a matching event, the
  first-arriving candidate is offered as the one-tap primary match, and
  the second appears as an extra-activity alternative rather than being
  discarded.

## Open Questions

- Strava, Garmin, and Wahoo don't necessarily offer equivalent webhook/
  event APIs — does `/speckit.plan` need a per-platform fallback (e.g. a
  platform without reliable events falls back to manual entry only,
  rather than this feature inventing a polling path just for that one
  platform)?
- What confirmation timeout best balances trust and convenience for an
  unconfirmed candidate?
- Extra-activity candidates (Requirement 7) that the rider never acts
  on — do they expire with the `ImportAttempt`, or remain selectable
  indefinitely from history?
