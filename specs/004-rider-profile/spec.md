# Feature 004: Rider Profile Setup

## User outcome
The rider enters the minimum information required to produce a useful route
without being forced through an advanced configuration screen.

## Required
- weight kg;
- FTP watts.

## Optional
- bike weight;
- HR max;
- personal HR zone boundaries Z1–Z5;
- 5s/1min/5min power curve;
- CdA;
- Crr.

`systemMassKg = rider weight + bike weight` for v1. Bottles, clothing and
other equipment are not separately modeled in v1.

The profile MUST store whether its physics constants are generic, calibrated or
stale. Calibration state and prediction confidence are separate concepts.
Changing a major physics input MUST follow Feature 009's stale-calibration
policy; it MUST NOT silently present an old calibration as current.

The optional power-curve import is limited to power-curve points and never
blocks onboarding.

## UX principles
- Required onboarding fields should be completable quickly.
- Advanced physics constants should be hidden behind an advanced section.
- Generic defaults MUST be visibly labeled as estimates.
- HR zone configuration MUST use the shared five-zone taxonomy.
- The user must be able to continue without HR data if the workout uses watts.

## Open decisions
- Whether user may edit CdA/Crr manually (recommended: advanced setting only).
- Generic CdA/Crr defaults.
- Generic HR zone table.
- Whether changing FTP should invalidate learned calibration.
