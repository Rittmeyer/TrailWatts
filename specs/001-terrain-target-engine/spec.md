# Feature 001: Local Terrain-Target Engine

## User outcome
The rider asks for a prescribed training stimulus and receives physically
plausible terrain/speed alternatives with transparent assumptions. The engine
must never imply that a mathematical estimate is a guaranteed physiological
response.

## Physics
The engine uses one cycling power model for all riders. Personalization changes
constants, never the formula. At minimum the model includes rolling resistance,
gravity, aerodynamic drag, drivetrain efficiency, and system mass. Wind is an
optional environmental input; if absent, zero wind is assumed and the result
is labeled as an estimate.

## Reverse direction: target → terrain options
Input:
- target watts OR HR target/zone;
- duration;
- rider system mass;
- FTP;
- CdA;
- Crr;
- drivetrain efficiency;
- optional wind.

Output:
- multiple `TerrainOption`s, including a near-flat/speed-led option and a
  climb-led option when physically feasible;
- each option MUST include gradient, speed, duration, distance, predicted watts,
  feasibility and model confidence;
- HR targets MUST expose the estimated equivalent power used for calculation.

Distance belongs to each option because it is derived from that option's speed
and duration. `TerrainTargetResult` MUST NOT contain a standalone distance.

## Forward direction: segment → predicted effort
Input:
- gradient;
- surface;
- achievable speed;
- rider profile;
- optional wind.

Output:
- predicted power;
- optional predicted HR zone;
- model state and confidence.

The engine MUST NOT fetch network data. Achievable speed is supplied by the
route system, with a static road-class/rider-ceiling proxy fallback.

## HR
If personal HR zone boundaries exist, use them. Otherwise use the documented
generic HR→%FTP approximation. The UI MUST call this an estimate, not an exact
physiological equivalence. HR response lag and cardiac drift MUST be documented
as limitations.

## Surface
Crr varies by `SurfaceType`. Exact defaults are implementation inputs and must
be documented before production release.

## Model state vs confidence
`ModelState` answers whether the rider constants are generic or calibrated.
`ModelConfidence` answers how trustworthy the current estimate is. They MUST
remain separate concepts.

## Calibration
Feature 009 owns calibration. Feature 001 consumes calibrated constants when
available and reports the model state used for each prediction.

## Tests
Must cover:
- flat vs climb solutions for the same power;
- positive/negative gradient;
- surface-dependent Crr;
- zero-wind and wind cases;
- HR fallback vs personal zones;
- impossible target/speed combinations;
- distance = speed × duration per option;
- generic vs calibrated state;
- no network dependency.
