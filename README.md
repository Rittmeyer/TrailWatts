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

Map screens resolve their geometry against a real road network (see
"Mapas e rotas" below). Demo data still stands in for the platform
integrations in `specs/002-platform-integration`, and the workout→terrain
matching engine in `specs/006-route-recommendation` remains subject to the
"Implementation gate" in `SETUP.md`: the routing layer added here covers the
"geospatial candidate source" and "route editing re-scoring" items, not the
timeline matching or the score formula.

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

## Mapas e rotas

As telas 02a2, 04 e 05 usam mapa real (tiles OSM via `flutter_map`) e resolvem
o traçado contra a malha viária através de `lib/services/routing_service.dart`:

- **04 Rota no mapa** — o trecho é desenhado seguindo as ruas, e a distância
  exibida vem da rota calculada, não de um valor fixo.
- **05 Editar rota** — cada ponto de controle é arrastável. Ao soltar, o ponto
  encaixa na via mais próxima (`/nearest`) e o trecho inteiro é refeito pelas
  ruas (`/route`); o painel de impacto mostra o desvio, o encaixe e o novo
  match antes de salvar.
- **02a2 Onde treinar** — o pino também assenta na via mais próxima, para a
  busca começar de um ponto pedalável.

Quando o serviço de rotas não responde, o app **não** finge: desenha linha
reta, marca o traçado como não verificado e mostra o aviso — nunca apresenta
uma distância de rua que na verdade foi estimada.

### Apontando para os seus servidores

Os endpoints são configuráveis em build-time. Os defaults servem para
desenvolvimento: a demo pública do OSRM é limitada e só serve o perfil
`driving`, e a política de uso de tiles do OSM não permite um app em produção
consumir `tile.openstreetmap.org`. Antes de publicar, aponte para infra
própria — é a decisão P0 "candidate map/road data source" de
`DECISIONS_REQUIRED.md`, junto da revisão de licença dos dados.

```bash
flutter run \
  --dart-define=TRAILWATT_OSRM_URL=https://osrm.suainfra \
  --dart-define=TRAILWATT_OSRM_PROFILE=cycling \
  --dart-define=TRAILWATT_TILE_URL=https://tiles.suainfra/{z}/{x}/{y}.png
```

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze   # sem problemas
flutter test      # 12 testes
```

Capturas de todas as telas em `docs/screenshots/` (veja o README de lá para o
motivo dos mapas aparecerem cinza nelas).

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
