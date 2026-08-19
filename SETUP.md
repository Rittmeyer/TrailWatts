# Trailwatt — Spec-Driven Development Setup

This repo is meant to be run with [GitHub Spec Kit](https://github.com/github/spec-kit),
the open-source toolkit for spec-driven development (Constitution → Specify →
Plan → Tasks → Implement). This document gets you from an empty GitHub repo
to your first implementable feature.

## 1. Install the Spec Kit CLI

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
specify --version
```

Requires [`uv`](https://docs.astral.sh/uv/). Any of the ~30 supported coding
agents work (Claude Code, GitHub Copilot, Cursor, Gemini CLI, Codex CLI...).

## 2. Initialize the repo

```bash
specify init trailwatt --ai claude
cd trailwatt
```

This scaffolds `.specify/` (templates, scripts, memory) and the agent-specific
prompt files that expose the slash commands below inside your coding agent.

## 3. Drop in the constitution

Copy `constitution.md` from this delivery into `.specify/memory/constitution.md`
(overwriting the placeholder Spec Kit generates), or open your coding agent
in the repo and run:

```
/speckit.constitution
```

pasting the contents of `constitution.md` when prompted. This is the source
of truth every future spec and plan gets checked against — do this before
anything else.

## 4. Draft your first feature spec

```
/speckit.specify
```

A reasonable first feature, given everything already decided for this
product: **"Local terrain-target calculation from a manually entered power
or heart-rate goal."** A starter spec for exactly this is included at
`specs/001-terrain-target-engine/spec.md` in this delivery — use it as-is,
or as a reference for the level of detail `/speckit.specify` should produce
before you move on.

## 5. Plan → Tasks → Implement

```
/speckit.plan
/speckit.tasks
/speckit.analyze
/speckit.implement
```

Run `/speckit.analyze` after `/speckit.tasks` and before `/speckit.implement`
— it's a read-only check that catches constitution violations and coverage
gaps before any code gets written.

## Suggested feature sequence

1. **Local terrain-target engine** — `specs/001-terrain-target-engine`
2. **Account & authentication** — `specs/003-account-auth`
3. **Rider profile setup** — `specs/004-rider-profile`
4. **Workout builder + timeline** — `specs/005-workout-builder`
5. **Route matching engine + route recommendation** — `specs/006-route-recommendation`
6. **Traffic, road suitability & safety enrichment** — `specs/010-traffic-aware-segments`
7. **Route editing + re-scoring** — `specs/007-route-editing`
8. **Platform integration** — `specs/002-platform-integration`
9. **Calendar & history** — `specs/008-calendar-history`
10. **Calibration loop** — `specs/009-calibration-loop`
11. **B2B API surface** — future spec for `terrain-target`, `route-match`, `export`

### Implementation gate

Do NOT implement the route UI as if matching were already solved. Before Feature
006 UI is wired to production data, the plan MUST define:
- geospatial candidate source;
- candidate segmentation;
- workout timeline matching;
- score formula and weights;
- continuity/interruption rules;
- traffic/safety integration;
- no-route fallback;
- route-type constraints;
- edit re-scoring.

This gate exists because route matching is the product's core capability, not a
placeholder dependency.
