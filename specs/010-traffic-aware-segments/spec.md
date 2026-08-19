# Feature 010: Traffic, Road Suitability & Safety

## Purpose
Enrich candidate segments with external road/traffic information without
moving network access into the on-device physics engine.

## Distinct signals
The system MUST NOT equate traffic with safety. It produces:
- `TrafficLevel`: low/medium/high/unknown;
- `CyclingSafetyLevel`: lowRisk/moderate/highRisk/unknown;
- `achievableSpeedKmh`;
- source and freshness metadata.

A busy protected cycleway can be safer than a low-traffic rural road. Ranking
must preserve this distinction.

## Requirements
1. External data MAY provide road classification, traffic, road geometry,
   cycling infrastructure, and other relevant suitability data.
2. Derive achievable speed and traffic level per candidate segment.
3. Provide safety independently from traffic.
4. Feed achievable speed to Feature 001; the physics engine itself performs
   no network call.
5. Feed traffic and safety to Feature 006.
6. Cache data for a bounded period.
7. Fall back to static road-class/rider-ceiling proxies when unavailable.
8. Never block route generation because traffic data is unavailable.
9. Rider-facing warnings are informational, not silently suppressed.
10. Every enriched segment MUST expose source metadata and `fetchedAt` when
    external data was used. Static fallback segments MUST identify that the
    data is a fallback rather than pretending it is live.
