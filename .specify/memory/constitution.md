<!--
Sync Impact Report:
- Version change: 1.2.0 -> 2.0.0 (MAJOR: Article VII no longer mandates a
  single five-zone taxonomy; power and heart rate are now separate zone
  tables, each selectable as Z1-Z5 or Z1-Z7)
- Rationale: power and heart rate are not interchangeable scales. Power zones
  conventionally use the seven-zone Coggan model anchored on FTP; heart-rate
  zones conventionally use five zones anchored on threshold or maximum HR.
  Forcing both through one five-zone list mislabeled real training intensity.
- Breaking for: any spec, plan or code that assumed exactly five zones, a
  single shared zone list, or a zone reference without a metric.
- Templates/specs updated: specs/004-rider-profile (HR zone taxonomy and
  anchor), specs/008-calendar-history (zone taxonomy reference),
  DECISIONS_REQUIRED.md (HR boundary review, zone-scale default).
- Follow-up: the heart-rate percentage bands ship as generic defaults and
  still need coach/physiology review before release; /speckit.analyze should
  check that no surface renders a hardcoded zone list.

Previous entry (1.1.0 -> 1.2.0):
- Clarified: route matching is a first-class engine capability and not an
  undefined dependency
- Follow-up: /speckit.analyze and code review should check modularity,
  readability, and avoidance of known vulnerability classes on every
  future plan, alongside the existing Articles
-->

# Trailwatt Constitution

## Mission

Translate a rider's training target — power in watts, or a heart-rate zone —
into real-world route recommendations, using on-device physics to determine
the terrain (gradient, distance) needed to produce that stimulus. Cyclists
first, runners later. Beginner to professional, from the same engine.

## Articles

### Article I — Local-First Computation

The physics engine (power ↔ gradient ↔ speed ↔ distance translation) MUST run
entirely on-device. No network call is required to compute today's terrain
target. This is non-negotiable: it is what lets the app work with no signal
on a trail or in a basement gym. Any feature that would make the core
calculation depend on a network round-trip violates this article and MUST be
redesigned before it can be planned.

### Article II — Manual Data Entry Only at Onboarding

The app MUST NOT import data from third-party platforms (Strava, Garmin,
TrainingPeaks, or similar) during onboarding or profile setup. All profile
data — weight, FTP, heart-rate zones, power curve — is entered manually by
the rider.

Rationale: avoids the restrictions most third-party API terms of service
place on caching, storing, or redistributing their data, and keeps the rider
in full control of what enters their account.

Exception: optional import of power-curve data points (e.g. 5s/1min/5min
peaks) MAY be offered through a read-scoped OAuth connection as a
convenience, but MUST NOT be required to use the app.

### Article III — No In-App Workout Recording

The app MUST NOT record live workout telemetry (GPS track, power, heart
rate) during a ride or run. Its responsibility ends at suggesting and
exporting a route. Actual recording happens in the platform the rider
already uses. Completed-activity data is retrieved afterward through that
platform's official API, with manual entry as the documented fallback when
no API connection exists.

### Article IV — Export Is Never Gated

Every route the app suggests MUST be exportable as GPX. TCX/FIT MAY be
supported where the destination platform accepts them. Upload or handoff MUST
use the platform's documented official integration when one exists; where a
platform does not expose an applicable upload endpoint, the app MUST provide
the official file-import handoff instead. Export capability MUST be included
in every pricing tier without restriction.

### Article V — Sync Only Finalized Records

Data reaches AWS only after it is complete and confirmed on-device — a saved
profile, a completed workout. Intermediate or draft state MUST stay
device-local. The mobile app is offline-first: on-device storage is the
source of truth while offline, and AWS is the durable, cross-device copy
that gets written to once, deliberately, after the fact — never on every
keystroke.

### Article VI — One Formula, Personalized Constants

Personalization MUST NOT branch the physics formula. The engine uses one
power/gradient equation for every rider; only the constants — CdA, Crr,
rider mass — change per person, calibrated over time from the delta between
predicted and actual results on completed rides. This keeps the MVP
shippable on a generic model on day one, refined automatically as real data
accrues, and never requires a rewrite to "add personalization" later.

### Article VII — Shared Zone Nomenclature

Training intensity is expressed through **zone tables**. There is one table
per metric — power and heart rate — and they are independent: the same effort
does not sit at the same zone number in both, so a zone reference is
meaningless without the metric it belongs to.

Each table MUST declare its own:

- **metric** — power (anchored on FTP) or heart rate (anchored on the rider's
  threshold HR, or on maximum HR when threshold is unknown);
- **scale** — five zones (Z1–Z5) or seven zones (Z1–Z7), chosen per table.
  A rider may run seven power zones alongside five heart-rate zones; this is
  the default pairing.

Colors follow a single fixed progression by zone number (Z1 recovery → Z7
neuromuscular), so a color means the same relative intensity on either scale.
Every surface that displays intensity (route map, calendar, workout builder,
history) MUST render whichever table the workout is prescribed against,
rather than a hardcoded zone list or its own labels and colors.

A stored zone MUST carry its metric and scale. A workout block prescribed in
watts MUST reference a power zone; one prescribed in heart rate MUST
reference a heart-rate zone.

Percentage boundaries are configuration, not physics: the power bands follow
the established Coggan model, the heart-rate bands ship as clearly-labeled
generic defaults pending physiological review, and riders MAY override
boundaries manually (Article II).

### Article VIII — The Engine Is the Product

The physics-and-route-matching engine is the primary asset, licensable
independently of the consumer app through a versioned B2B API
(`terrain-target`, `route-match`, `export`). The consumer app is a reference
implementation and the primary source of calibration data — not the only
route this technology reaches the market.

### Article IX — Cross-Platform From One Codebase

The mobile client MUST ship to iOS and Android from a single Flutter/Dart
codebase rather than maintaining separate native implementations. This is the
chosen implementation for the current repository and prototype.

### Article X — Code Quality & Security Baseline

This article applies to every codebase in the project — mobile client,
backend services, infrastructure scripts — regardless of language.

**Good practice over local invention.** Code MUST follow the established,
idiomatic conventions of whatever language and framework it's written in
(standard linting, standard formatting, standard project layout) rather
than inventing project-specific conventions where a language-standard one
already exists. When in doubt, default to the ecosystem's own style guide.

**Modular and simple.** Code MUST be organized as small, single-responsibility
functions, classes, and files rather than large ones that do many
unrelated things. As a practical guideline rather than a hard wall: a
function SHOULD be short enough to read without scrolling, a file SHOULD
cover one concern, and a line SHOULD stay within a reasonable column width
(a common default is 80–100 columns) so diffs and reviews read cleanly.
These are defaults to reach for, not values to satisfy mechanically —
breaking a function apart in a way that makes it harder to follow defeats
the purpose. Readability is the goal; the numbers are just a proxy for it.

**Security is not optional.** Code MUST follow the general security
practices of its language and framework, and MUST avoid vulnerability
classes that are already well-documented and repeatedly reported (e.g.
the OWASP Top 10: injection, broken authentication, sensitive-data
exposure, insecure deserialization, use of components with known
vulnerabilities). This is a floor, not a feature — it applies regardless
of how small or internal a piece of code seems.

Rationale: Articles I–IX define what this product does and where its
boundaries sit; this article defines the baseline for how the code
implementing all of it gets written, so that quality doesn't depend on
which contributor or which language touched a given part of the system.

Every `/speckit.plan` for a feature touching rider data, authentication,
or billing MUST include a short security review against this article,
consistent with how Articles II and V already constrain how sensitive
rider data is allowed to move.

## Explicit Non-Goals

These are out of boundary until a future amendment says otherwise:

- Automatic bulk import of historical training data from any third-party
  platform.
- Turn-by-turn navigation guidance during a ride.
- Prescribing training plans or making coaching decisions — the engine
  translates a target the rider already has into terrain, it does not decide
  what that target should be.
- Storing raw third-party platform data beyond what a single export/import
  round-trip requires.

## Governance

This constitution supersedes informal practice. Any plan or spec that
conflicts with an article here must either be revised to comply or must
amend this document first, with the conflict and rationale stated
explicitly.

Amending an article requires: stating which article changes and why,
identifying every existing spec or plan that assumed the old boundary, and
updating them before the amendment merges.

**Version**: 1.2.0
**Amendment note**: 1.2.0 clarifies Article I to include speed in the
physics domain and resolves the Article II manual-entry/optional-power-curve
exception. The route-matching engine is now treated as a first-class product
capability rather than an undefined dependency.
**Ratified**: 2026-08-08
**Last Amended**: 2026-08-10
