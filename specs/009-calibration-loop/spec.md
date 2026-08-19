# Feature 009: Calibration Loop

## Purpose
Learn per-rider CdA/Crr from the difference between route predictions and
completed-activity observations, without changing the core physics formula.
Calibration is a refinement mechanism, not a coaching system.

## User outcome
The rider should gradually receive better estimates without losing trust in
what changed. The app must be able to say whether a prediction used the
Generic or Calibrated model and how confident that calibration is.

## Inputs
- predicted power;
- actual power;
- predicted gradient/speed;
- observed speed;
- rider/system mass;
- surface;
- route segment;
- optional wind;
- completed activity source and quality metadata.

## Requirements
1. Calibration MUST be conservative and require sufficient high-quality data.
2. It MUST reject or down-weight rides with poor sensor coverage, implausible
   data, or major environmental uncertainty.
3. It MUST never modify the universal physics equation.
4. It MUST update rider constants only after confidence criteria are met.
5. Calibration MUST be versioned.
6. Historical predictions MUST retain the calibration version/state used.
7. Changing rider mass, FTP, equipment assumptions, or major model inputs MUST
   mark calibration stale until the stale-calibration policy is satisfied.
8. `predictionAccuracyPct` MUST be stored separately from calibrated constants.
9. The user MUST be able to see that calibration is generic, calibrated, or
   stale; the UI must not silently change the meaning of historical results.
10. Calibration MUST never invent a result when the imported activity lacks
    sufficient data.

## Data model
`CalibrationObservation` stores one quality-scored observation.
`CalibrationProfile` stores the current version, state, constants, observation
count, quality and prediction accuracy.

## Not in MVP unless explicitly approved
- automatic FTP estimation;
- automatic training prescription;
- full aerodynamic position inference.

## Open decisions
- minimum number of high-quality observations;
- residual/error threshold;
- regression/optimization method;
- wind handling;
- indoor ride handling;
- power-meter bias handling;
- stale-calibration rules.
