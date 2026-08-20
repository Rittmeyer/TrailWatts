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
- heart-rate zone scale (Z1–Z5 or Z1–Z7) and its anchor
  (threshold HR, or maximum HR when threshold is unknown);
- personal HR zone boundaries, overriding the generic table;
- power zone scale (Z1–Z5 or Z1–Z7), anchored on FTP;
- CdA;
- Crr.

`systemMassKg = rider weight + bike weight` for v1. Bottles, clothing and
other equipment are not separately modeled in v1.

The profile MUST store whether its physics constants are generic, calibrated or
stale. Calibration state and prediction confidence are separate concepts.
Changing a major physics input MUST follow Feature 009's stale-calibration
policy; it MUST NOT silently present an old calibration as current.

The power curve (5s/1min/5min peaks) is out of scope: nothing in the engine
consumed it, so collecting it only added onboarding friction. With it goes
the platform import offered on this screen - profile setup is now entirely
manual, with no third-party connection at all.

## UX principles
- Required onboarding fields should be completable quickly.
- Advanced physics constants should be hidden behind an advanced section.
- Generic defaults MUST be visibly labeled as estimates.
- Power and HR zones are configured separately: they are different
  tables, each with its own zone count, and HR additionally needs its
  own anchor (Constitution Article VII).
- The resulting table MUST be shown in absolute watts/bpm, not only as
  percentages, so the rider can check it against what they know.
- Without an HR anchor the app MUST NOT display HR zones at all rather
  than deriving them from an assumed value.
- The user must be able to continue without HR data if the workout uses watts.

## Open decisions
- Whether user may edit CdA/Crr manually (recommended: advanced setting only).
- Generic CdA/Crr defaults.
- Generic HR zone boundaries (both anchors) pending physiology review.
- Default zone scale per metric (currently 7 power / 5 HR).
- Whether changing FTP should invalidate learned calibration.
