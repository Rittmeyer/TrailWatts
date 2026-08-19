# Feature 007: Route Editing

## User outcome
A rider can make a practical route change without accidentally losing the
training intent. Every edit is re-evaluated before export.

## Requirements
1. Full route context MUST remain visible.
2. Editable segments are identified by the explicit `RouteSegment.isEditable`
   flag; list position MUST NOT be used as the identifier. `RouteSegmentRole`
   describes workout purpose (approach/work/recovery/return), not editability.
3. Save MUST replace only the editable section.
4. Cancel MUST restore the exact original suggestion.
5. Saving an edit MUST immediately re-run route scoring for the modified route.
6. If match falls by more than the configured warning threshold, the rider MUST
   see the impact before final save/export.
7. The saved route MUST propagate to the teaser and export representation.
8. Zone coloring for the edited section is provisional while editing and
   recalculated after confirmation.
9. The UI SHOULD explain what changed, e.g. "Z4 interval 2 now has 7.5 min
   continuous terrain instead of 10 min; match 91% → 82%".

## Open decisions
- Exact warning threshold for score degradation (10 percentage points is the
  provisional default).
- Whether edits can alter route type (recommended: no in v1).
