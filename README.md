# Trailwatt

Translates a rider's training target — power in watts, or a heart-rate zone —
into real-world route recommendations, using on-device physics to work out
the terrain (gradient, distance) needed to produce that stimulus.

See `.specify/memory/constitution.md` for the product principles every
screen and model below follows, and `specs/` for the per-feature specs this
app was built from.

## Status

All 15 screens in `lib/routes/screen_inventory.dart` are implemented:
account/auth, rider profile, workout builder (block editor + location map),
today's workout, route map, route editing, result import (auto + two manual
fallbacks), history, and calendar (week and month). The physics/route-score
engine (`lib/engine/`), domain models (`lib/models/`) and design tokens
(`lib/theme/`) are the same ones the audited spec package shipped with.

Demo data is used in place of the backend/API integrations described in
`specs/002-platform-integration` and `specs/006-route-recommendation` —
those still need the geospatial/matching engine described in `SETUP.md`'s
"Implementation gate" before they're production-ready.

## Running it

```bash
flutter pub get
flutter run -d chrome   # or an attached device/emulator
```

This repo ships `lib/`, `test/` and a hand-built `web/` platform folder, but
not the generated native platform folders (`android/`, `ios/`, `macos/`,
`windows/`, `linux/`) - those are machine- and SDK-version-specific and
should be generated locally rather than hand-written:

```bash
flutter create . --platforms=android,ios
```

This only adds the missing platform folders; it does not touch `lib/`.

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Structure

```
lib/
  models/    domain types (rider profile, workout, route, calibration, ...)
  engine/    pure route-score calculation, shared by app and future API
  theme/     colors, text styles, ThemeData - single source of design tokens
  widgets/   shared building blocks (buttons, fields, zone pill, bottom nav)
  screens/   one file per screen, wired together in lib/main.dart
  routes/    screen_inventory.dart - route table cross-referenced with specs
prototype/   original HTML flow prototype these screens were ported from
ui/          web-flow and mobile-flow HTML references
spec-reference/  contractual UI reference (does not override specs/)
specs/       per-feature specs (Spec Kit format)
```
