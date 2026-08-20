# Trailwatt

Translates a rider's training target — power in watts, or a heart-rate zone —
into real-world route recommendations, using on-device physics to work out
the terrain (gradient, distance) needed to produce that stimulus.

See `.specify/memory/constitution.md` for the product principles every
screen and model below follows, and `specs/` for the per-feature specs this
app was built from.

## Status

All 17 screens in `lib/routes/screen_inventory.dart` are implemented:
account/auth, rider profile, workout builder (block editor + location map),
today's workout, route map, route editing, result import (auto + two manual
fallbacks), history, calendar (week and month), "Mais" and platform
integrations. The physics/route-score engine (`lib/engine/`), domain models
(`lib/models/`) and design tokens (`lib/theme/`) are the same ones the
audited spec package shipped with.

A block in the workout builder can hold two or more stimuli - e.g. a Z4
work stimulus and its Z1 recovery - added and repeated together instead of
typed out as separate blocks; see the "repeat group" decision in
`specs/005-workout-builder/spec.md`. The builder can also pull the rider's
preferred workout in from TrainingPeaks (via the floating action button, or
the "Mais" tab's Integrations link) when connected, falling back to the
manual block editor otherwise.

Map screens resolve their geometry against a real road network (see
"Mapas e rotas" below), and the platform connections are real OAuth
sessions rather than a flag (see "Integrações" below). The workout→terrain
matching engine in `specs/006-route-recommendation` remains subject to the
"Implementation gate" in `SETUP.md`: the routing layer added here covers the
"geospatial candidate source" and "route editing re-scoring" items, not the
timeline matching or the score formula.

## Running it

```bash
flutter pub get
flutter run -d chrome   # or an attached device/emulator
```

This repo ships `lib/`, `test/`, a hand-built `web/` folder, `android/` and
`ios/`. The remaining platform folders (`macos/`, `windows/`, `linux/`) are
not committed - generate the ones you need with
`flutter create . --platforms=macos`, which only adds platform folders and
does not touch `lib/`.

## Android APK

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Needs the Android SDK (platform + build-tools) and a JDK 17+; `flutter doctor
--android-licenses` once if this is a fresh SDK. The release build is signed
with the debug key, which is enough to sideload for testing but not to
publish - add a real signing config in `android/app/build.gradle` before any
store release.

Smaller download, one ABI at a time:

```bash
flutter build apk --release --split-per-abi
# app-arm64-v8a-release.apk covers essentially every current tablet/phone
```

Two things about this Android config worth knowing:

- `INTERNET` is declared in the **main** manifest, not only the debug one.
  Flutter's template puts it in `debug/` alone, which would leave a release
  APK unable to fetch map tiles or reach the routing service - the app would
  run but sit permanently in its degraded, straight-line state.
- The Gradle wrapper, AGP and Kotlin were bumped past Flutter's template
  defaults (Gradle 8.7 / AGP 8.3.2 / Kotlin 1.9.22) so the build works on a
  current JDK; the shipped Gradle 8.3 rejects JDK 21.

## iOS

O projeto Xcode está versionado em `ios/` (bundle id `app.trailwatt`,
mínimo iOS 12). Compilar exige **macOS com Xcode** - o Flutter só registra os
subcomandos `build ios`/`build ipa` nessa plataforma, então num Linux eles
nem existem. Num Mac:

```bash
flutter build ios --release            # .app para rodar em device
flutter build ipa --release            # build/ios/ipa/*.ipa para distribuir
```

Sem conta de desenvolvedor à mão, `flutter build ios --release --no-codesign`
compila e para antes de assinar - serve para validar que o projeto compila.
Para publicar, abra `ios/Runner.xcworkspace` e preencha o time de assinatura
em *Signing & Capabilities*; o template não traz um.

O `Info.plist` já registra o esquema `trailwatt://` em `CFBundleURLTypes`,
que é o redirect de OAuth das integrações. Isso deixa o iOS **entregar** o
redirect ao app; quem ainda falta é o handler que chama
`IntegrationsStore.completeConnect` - veja "O que ainda falta para produção".

## Web

```bash
flutter build web --release --web-renderer html
# build/web/  (main.dart.js ~2.9 MB)
```

O renderer `html` é escolha, não default: o CanvasKit baixa ~2 MB de wasm
antes do primeiro frame, e esta interface é texto, lista e um mapa de tiles -
nada que precise do canvas. `build/web/canvaskit/` sai do template mesmo
assim e pode ser apagado do que você publica.

Sirva a pasta por HTTP; abrir `index.html` como `file://` não funciona
(módulos e `fetch` de assets exigem origem). Para hospedar fora da raiz do
domínio, passe `--base-href=/subpasta/`.

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

## Integrações (Strava, Garmin, Wahoo, TrainingPeaks)

A tela **Mais › Integrações** conecta e desconecta cada plataforma de forma
independente. A conexão é uma sessão OAuth de verdade — Authorization Code
com PKCE (RFC 7636), que é o fluxo correto para app público: **nenhum client
secret vai no binário**, e o app só marca uma plataforma como conectada
quando está segurando um token que ela emitiu.

O papel de cada uma:

- **Strava, Garmin, Wahoo** — recebem a rota sugerida e devolvem a atividade
  concluída correspondente.
- **TrainingPeaks** — lê o treino já planejado para dentro do construtor.
  Não recebe rota.

### Configurando

Cada plataforma precisa do client id registrado por você. Sem ele a tela diz
**"Indisponível nesta build"** em vez de oferecer um botão que só poderia
falhar:

```bash
flutter run \
  --dart-define=TRAILWATT_STRAVA_CLIENT_ID=... \
  --dart-define=TRAILWATT_GARMIN_CLIENT_ID=... \
  --dart-define=TRAILWATT_WAHOO_CLIENT_ID=... \
  --dart-define=TRAILWATT_TRAININGPEAKS_CLIENT_ID=... \
  --dart-define=TRAILWATT_OAUTH_REDIRECT=trailwatt://oauth
```

O redirect registrado em cada plataforma é o valor acima com o nome dela no
fim — `trailwatt://oauth/strava`, `/garmin`, `/wahoo`, `/trainingpeaks`.

### Exportar rota

O GPX é sempre gerado (`lib/services/platform/gpx_export.dart`). Onde a
plataforma documenta um endpoint de rotas, ele é enviado direto; onde não
documenta, o app entrega o GPX para você importar pelo importador da própria
plataforma — **nunca** simula sessão de navegador nem usa endpoint não
documentado. Qual plataforma tem qual capacidade é dado, não suposição:
veja `PlatformCapabilities` em
`lib/services/platform/platform_credentials.dart`.

Os endpoints padrão são **provisórios**, no mesmo sentido dos defaults do
OSRM: servem para desenvolvimento e precisam ser verificados contra a
documentação e os termos de cada parceiro antes de publicar — é a decisão P0
"Platform API capabilities" de `DECISIONS_REQUIRED.md`.

### O que ainda falta para produção

Duas coisas, ambas de propósito fora daqui em vez de meio-feitas:

- **Receber o redirect por deep link.** Hoje o app abre o endereço de
  autorização e você cola de volta a URL para onde foi redirecionado. Um
  build de produção registra o esquema `trailwatt://` e chama
  `IntegrationsStore.completeConnect(platform, uri)` direto do handler —
  mesmo fluxo, sem o passo manual.
- **Guardar os tokens.** Eles vivem só em memória: persistir exige keystore
  do Android / keychain do iOS, e guardar token de plataforma em
  `shared_preferences` seria pior do que não guardar.

## Idiomas

A interface segue o idioma do aparelho (ou do navegador, na web). Português e
inglês estão traduzidos; qualquer outro idioma cai no inglês.

As strings ficam em `lib/l10n/app_pt.arb` e `app_en.arb`. Depois de editar um
ARB, regenere as classes:

```bash
flutter gen-l10n
```

O código gerado (`lib/l10n/app_localizations*.dart`) é versionado para o repo
analisar e testar logo após o clone. `l10n-missing.json` lista chaves sem
tradução — hoje está vazio.

Para adicionar um idioma, crie `app_<code>.arb`, traduza e rode `gen-l10n`;
nada mais precisa mudar. Os modelos não carregam texto de interface: uma zona
guarda `ZoneName.threshold`, e o nome visível é resolvido na UI
(`lib/l10n/domain_labels.dart`), então o motor continua licenciável sozinho
(Artigo VIII).

Datas e nomes de mês/dia vêm do `intl`, seguindo as convenções de cada idioma
— não são listas fixas.

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze   # sem problemas
flutter test      # 183 testes
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
