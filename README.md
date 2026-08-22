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
deploy/deploy.sh android    # via Docker, sem instalar SDK nenhum
flutter build apk --release # ou direto, com o SDK do Android local
# build/app/outputs/flutter-apk/app-release.apk
```

Needs the Android SDK (platform + build-tools) and a JDK 17+; `flutter doctor
--android-licenses` once if this is a fresh SDK. The release build is signed
with the debug key, which is enough to sideload for testing but not to
publish. Passe `--keystore` e `--key-properties` para `deploy/deploy.sh
android` e o release é assinado de verdade; `deploy/README.md` tem o
formato do `key.properties`.

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

## Deploy

Uma entrada só, para as três plataformas:

```bash
deploy/deploy.sh web        # bundle estático + imagem nginx pronta para rodar
deploy/deploy.sh android    # apk, ou --aab para o Play Console
deploy/deploy.sh ios        # ipa - só no macOS, e o script explica por quê
deploy/deploy.sh all
```

Web e Android são construídos dentro do Docker, sem instalar SDK nenhum na
sua máquina; os artefatos saem em `build/deploy/<plataforma>/`. O alvo web
também produz a imagem `trailwatt-web`, porque um bundle que ninguém
consegue servir é meio deploy:

```bash
deploy/deploy.sh web --run 8080
deploy/deploy.sh web --push registry.exemplo.com/trailwatt:2026-08-20
```

Em Mac com Apple Silicon os estágios de build rodam emulados em
`linux/amd64`: o SDK do Flutter para Linux só existe em x86_64. Isso está
fixado no Dockerfile — sem isso o Rosetta falha com `failed to open elf at
/lib64/ld-linux-x86-64.so.2`. Detalhes em `deploy/README.md`.

**Não existe imagem Docker capaz de compilar para iOS**: o Xcode só roda em
macOS, e a licença da Apple não permite macOS em container fora de hardware
Apple. Nenhuma configuração resolve isso — é a razão de o iOS ser o único
alvo que sai do Docker.

`deploy/README.md` cobre o resto: assinatura do Android por secret do
BuildKit (a keystore nunca entra numa camada), o que o nginx não pode
cachear, e como passar client ids por `DART_DEFINES`.

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
deploy/deploy.sh web        # via Docker: bundle + runnable nginx image
flutter build web --release --web-renderer html   # ou direto, sem Docker
# build/web/  (main.dart.js ~2.9 MB)
```

O renderer `html` é escolha, não default: o CanvasKit baixa ~2 MB de wasm
antes do primeiro frame, e esta interface é texto, lista e um mapa de tiles -
nada que precise do canvas.

**Sem a flag o build sai em CanvasKit**, que por padrão busca o wasm em
`gstatic.com`. Numa rede que bloqueia esse domínio — ou offline — o app não
desenha nada e não diz nada. Por isso `web/index.html` aponta o
`canvasKitBaseUrl` para a cópia local em `canvaskit/`, que já vem no build:
o app nunca depende de CDN para abrir, com qualquer renderer.

E se mesmo assim ele não iniciar, `web/index.html` mostra o porquê em HTML
puro em vez de deixar a página em branco: detecta `file://` na hora, e usa a
promessa do loader do Flutter para reportar falha real. Um `file://` aberto
direto do disco falha igual em todo navegador — é a causa mais comum de
"não funciona".

Sirva a pasta por HTTP; abrir `index.html` como `file://` não funciona
(módulos e `fetch` de assets exigem origem). Para hospedar fora da raiz do
domínio, passe `--base-href=/subpasta/`.

## Layout por tamanho de tela

A mesma build serve telefone, tablet e navegador, e escolhe a forma pela
**largura da janela**, não pela plataforma: um navegador arrastado até ficar
estreito se comporta como telefone, e um tablet deitado não recebe cromo de
telefone.

| Largura | Destinos | Conteúdo |
| --- | --- | --- |
| `< 600` | barra inferior | ocupa tudo |
| `600 - 1099` | trilho lateral com ícone e rótulo | no máximo 760 px |
| `>= 1100` | trilho lateral aberto, com o nome do app | no máximo 760 px |

Os dois números vivem em `lib/theme/layout.dart` (`LayoutSize`), e a barra
inferior e o trilho são duas formas da **mesma** lista de destinos
(`lib/widgets/app_shell.dart`) - alargar a janela nunca muda o que o app
oferece, só onde a oferta fica.

O limite de largura (`ContentWidth`) existe por causa do comprimento de
linha. Antes disso, o layout de telefone despejado numa janela de 1440 px
dava 24 px de texto e 1300 px de nada entre um rótulo e o seu valor - era o
que a versão web mostrava. Telas de mapa usam um limite maior, porque um
mapa realmente melhora com espaço.

`ContentAlignedFabLocation` mantém o botão flutuante junto da coluna em vez
de no canto da janela, a algumas centenas de pixels do formulário em que ele
age.

## O motor de rotas

O casamento treino x terreno vive em `lib/engine/`, sem dependência de UI,
porque é a parte licenciável sozinha (Artigo VIII).

**`cycling_power_model.dart`** — uma fórmula de potência para todo mundo
(spec 001): resistência de rolamento, gravidade e arrasto. A
personalização move constantes (massa, CdA, Crr, eficiência), nunca a
fórmula. Resolve nos dois sentidos: potência a partir da velocidade, e
velocidade a partir da potência.

**`workout_route_matcher.dart`** — casa o treino **inteiro** contra a rota.
Escolher o melhor morro para a primeira série e só depois procurar a
próxima é uma caminhada gulosa que gasta o terreno de que uma série
posterior precisava — é por isso que uma rota parece perfeita para um
estímulo e é inútil para a sessão. Aqui todos os passos da timeline
expandida, aquecimento e recuperação inclusive, são posicionados de uma
vez, e vence a distribuição que serve melhor a sessão como um todo, mesmo
onde isso dá terreno pior a uma série individual.

O posicionamento é um programa dinâmico sobre (passo, distância na rota):
os passos ocupam trechos consecutivos, sem sobreposição e em ordem. Os
inícios candidatos ficam dentro de uma janela de duração — um passo que
quer 8 minutos não é servido por 40 — o que transforma uma varredura
quadrática numa deslizante e deixa o casamento **linear em (passos ×
trechos)**. Uma rota de 20 km amostrada a cada 10 m contra uma sessão de
21 passos é medida em teste e fica bem abaixo de 1 segundo.

O teste que importa compara contra um casador guloso escrito no próprio
teste: na rota-armadilha, o guloso serve menos séries. É a afirmação
central, verificada em vez de prometida.

### O que a busca custa, medido

Medido no app compilado, no Chromium, com Overpass e elevação
interceptados: payload no formato real do Overpass (`out geom tags`, vias
que compartilham nó nos cruzamentos como no OSM), latência de servidor
injetada — 3000 ms no Overpass, 300 ms por chamada de elevação.

| vias no raio | 1ª busca (fria) | 2ª (memória) | 3ª (após recarregar a página) |
|---|---|---|---|
| 1500 | 3796 ms | 250 ms | 393 ms |
| 4000 | 3888 ms | 275 ms | 520 ms |

Antes da rodada de otimização, as duas últimas colunas eram 717/748 ms e
1145/1229 ms. O que mudou, em ordem de ganho:

- **A base local não é lida quando a memória já tem a área.** Decodificar
  todas as vias guardadas de novo, para linhas que o índice já segurava,
  custava mais que a própria busca.
- **Uma transação para tudo, não uma por linha.** O IndexedDB abria uma
  transação por via — milhares numa área urbana, cada uma com sua ida ao
  thread de armazenamento do navegador.
- **Haversine no lugar de Vincenty.** `const Distance()` usa Vincenty por
  padrão, uma geodésica iterativa: 83 ms contra 21 ms em 200 mil chamadas,
  por uma diferença que ninguém pedala. Onde o número só decide algo — cabe
  no círculo? vale manter esta amostra? — vai uma aproximação plana, 14×
  mais barata; onde o número é mostrado, vai o exato.
- **O solver de potência é memoizado por gradiente.** Ele bisseciona 60
  vezes por chamada e o casador quer uma por (passo, trecho): 12 mil por
  candidato. Gradiente se repete ao longo de uma estrada.
- **Comprimento de via medido uma vez por busca**, não a cada salto da
  caminhada.
- **A gravação no banco saiu do caminho crítico.** Milhares de linhas numa
  área urbana, e a busca já tem tudo em memória — fazer o ciclista esperar
  por uma escrita que só ajuda a *próxima* busca é a troca errada.

### Onde o tempo ainda está

Medido isolando cada parte, em vez de supor:

| | tempo |
|---|---|
| navegar para uma tela **sem** mapa | 52 ms |
| navegar para uma tela **com** FlutterMap | 195 ms |
| busca repetida inteira | ~250 ms |

Ou seja: dos ~250 ms, cerca de **145 ms são inicialização do mapa** e
~52 ms navegação. **A busca em si custa ~60 ms.** O algoritmo deixou de ser
o gargalo; o que resta é custo da biblioteca de mapa.

Uma tentativa que **não** funcionou, registrada porque medir foi o que
disse: cachear a geometria da rota para não realocar 600 `LatLng` a cada
quadro. Está no código porque é menos lixo por quadro, mas não moveu o
número — o tempo não estava ali.

### A busca fria: sobrepor, já que não dá para encurtar

A primeira busca é ~87% espera de rede, e nada deste lado encurta isso. O
que dá para fazer é não esperar em série: quando o pino assenta, o app já
sabe de onde o ciclista quer sair e quanto terreno a sessão precisa, e
começa a buscar enquanto ele ainda ajusta o raio.

| tempo no mapa antes de pedir a rota | busca fria |
|---|---|
| toque imediato | 3702 ms |
| 1,8 s | 3067 ms |
| 2,5 s | 2244 ms |
| 4 s | **880 ms** |

Isso só funciona porque requisições para a mesma área são **deduplicadas em
voo**: a busca entra na consulta que o prefetch já começou. Sem isso o
palpite custava uma consulta em vez de economizar — medido, eram duas
chamadas ao Overpass.

Uma chamada ao Overpass e **uma** de elevação, em qualquer densidade. A
terceira linha é depois de recarregar a página: zero rede, servida pelo
IndexedDB.

O que a medição corrigiu: a busca fria custava 5,7 s e ~2 s disso era
espera **nossa**, não do servidor. A elevação era pedida por candidato —
três chamadas para 79 pontos que cabem numa — e o serviço segura um
segundo entre chamadas por política. Pedindo os quatro candidatos de uma
vez, 5,7 s viraram 3,8 s.

O que não está medido: a latência real do Overpass público e do DEM, e a
densidade real de uma cidade real. Os 3000 ms são parâmetro, não medição —
a rede externa é bloqueada neste ambiente. O que a tabela mostra é que o
custo do lado do cliente é pequeno e cresce devagar: 10× mais vias
somaram ~170 ms na busca fria.

### Ponto de partida

Três formas de dizer de onde sair, porque num mapa elas não são
intercambiáveis: **arrastar** o pino quando o lugar certo está à vista,
**tocar** quando está mais longe, e **escrever** quando o ciclista sabe o
nome do lugar mas não onde ele fica no mapa. Qualquer uma das três assenta
o ponto na via mais próxima, então a busca sempre parte de algo pedalável.

O arraste usa o mesmo `flutter_map_dragmarker` dos waypoints da edição de
rota — arrastar um ponto num mapa se comporta igual em todo o app.

A busca por nome usa **Nominatim**, o geocodificador do próprio
OpenStreetMap (`lib/services/geocoding_service.dart`). A política de uso
dele faz parte do contrato, não é rodapé: no máximo uma requisição por
segundo e um `User-Agent` que identifique a aplicação. As duas coisas são
impostas dentro do serviço, não deixadas para quem chama — uma tela que
esquecesse bloquearia o app inteiro, não só a si mesma. A digitação ainda
tem debounce de 450 ms, senão cada letra viraria uma busca por um prefixo
que ninguém quis pesquisar.

"Nada encontrado" e "a busca não rodou" são mensagens diferentes. A
primeira é uma resposta; a segunda não.

### O ajuste ao atleta

O motor de rotas roda com dois números que são do ciclista e da bicicleta,
não da física: **CdA** (arrasto) e **Crr** (rolamento). Enquanto ninguém os
mede, são chutes de catálogo — e são eles que decidem que velocidade um
alvo compra num gradiente, ou seja, decidem a rota inteira.

`lib/engine/calibration_engine.dart` aprende os dois a partir do que
aconteceu na estrada. A equação **nunca muda** (spec 009, requisito 3); só
as duas constantes se movem. O ajuste é exato, não iterativo: dividindo a
equação de potência por `v` e passando a gravidade para o outro lado,

```
P*eta/v - m*g*sin0  =  Crr*(m*g*cos0)  +  CdA*(0.5*rho*v^2)
```

que é linear nas duas incógnitas — mínimos quadrados de duas colunas, sem
chute inicial para errar e sem nada para convergir.

Validado do jeito que um ajuste tem que ser validado: gerando pedaladas de
um ciclista com CdA e Crr **conhecidos** e verificando que o fit os
encontra. Recupera 0,281 e 0,0056 dentro da tolerância, inclusive com 6%
de ruído.

**E recusa mais do que aceita**, porque é assim que tem que ser:

- descida é rejeitada — ali quem manda é vento e freio, não o ciclista;
- rampa acima de 20% também — nada ali é regime permanente;
- pedalada muito diferente da prescrita idem: não foi a pedalada planejada;
- se todas as observações se parecerem (mesma velocidade, mesmo gradiente),
  as duas constantes são **indistinguíveis** e o ajuste é descartado em vez
  de jogar todo o erro numa delas;
- ajuste que cai fora do fisicamente plausível vai fora.

Mudar peso, FTP ou equipamento marca a calibração como **desatualizada**,
não a apaga: o ciclista precisa ver que ela deixou de valer, em vez de
achar as estimativas silenciosamente diferentes.

E a rota diz de qual modelo os números vieram — genérico, calibrado com
quantos por cento de acerto, ou desatualizado.

**De onde vêm as observações.** Quando você associa uma pedalada a um
treino, o app busca o registro amostra a amostra dela (tempo, distância,
altitude, potência) e recorta em janelas de um minuto. Uma janela só entra
se você estava fazendo **uma coisa só** o tempo todo:

- parada no semáforo não vira "trecho devagar" — a janela é descartada;
- buraco no medidor de potência descarta a janela; ausência **não é zero
  watt**;
- esforço oscilando demais (ou velocidade) não é regime permanente;
- pedalada sem medidor de potência ou sem barômetro não rende nada, e o app
  diz isso em vez de inventar.

Validado de ponta a ponta: uma pedalada sintetizada de um ciclista com
CdA 0,294 e Crr 0,0048 atravessa leitor e ajuste e sai com aquelas
constantes. E uma pedalada plana inteira, por mais longa que seja, é
**recusada** — a uma velocidade só num gradiente só, as duas constantes são
indistinguíveis.

**Só o Strava está implementado.** O endpoint de streams dele é
documentado, vem indexado por tipo e traz exatamente as quatro séries. O de
Garmin e Wahoo é diferente e este repositório não chuta endpoint que
ninguém leu a documentação — a mesma regra que mantém a exportação de rota
em upload documentado. Eles respondem "não suportado", e a checagem de que
**nem tentam a chamada** está em teste.

### Da fonte à sugestão

O caminho completo, em `lib/services/terrain/`:

**`cycling_segment_source.dart`** — OpenStreetMap via Overpass. A consulta
pede só o que uma bicicleta pode usar: sem via expressa, sem
`bicycle=no`, sem `access=private`. Uma sugestão que o ciclista não tem
direito de pedalar é pior que sugestão nenhuma. `out geom` traz a
geometria embutida, o que reduz ida-e-volta de way + nós a uma só.
Superfície, trânsito e segurança saem das tags — e a classe da via como
proxy de trânsito é dito como proxy, não como medição.

**`elevation_service.dart`** — OpenTopoData sobre DEM aberto. O gradiente
é o insumo principal do casador e o OSM quase não traz `ele`, então é
consulta separada. Ponto fora do DEM volta **null**, nunca zero: nível do
mar é uma altura real, e uma rota "a 0 m" seria pontuada como plana em
vez de desconhecida. Lotes de 100 pontos, que é o limite documentado.

**`terrain_elevation.dart`** — alturas para os pontos que a rota **usa**,
não para a área. Foi aqui que a busca ficou lenta: pedir elevação de todo
nó de toda via no raio dá, numa área urbana de 8 km, **30.000 pontos =
300 chamadas**. A cada 100 pontos por chamada e uma chamada por segundo,
são **5 minutos por busca** — e um terço da cota diária gasto de uma vez.
Agora só os candidatos que o finder constrói pedem altura, já
reamostrados: **15 pontos, 1 chamada**. O ponto repetido (uma ida-e-volta
passa duas vezes por tudo) é pedido uma vez só, e o memo vive no índice,
então a segunda busca não pede nada.

**`terrain_index.dart`** — a base local. Grade espacial por célula, então
achar as vias perto de um ponto é consulta de célula, não varredura de
tudo que já se baixou. E área já buscada **nunca é buscada de novo** — a
chamada de rede é a parte cara por ordens de grandeza e o terreno não
muda entre dois pedais. Área vazia é lembrada como vazia; falha **não**
é cacheada, senão um minuto ruim viraria um dia ruim.

**`route_finder.dart`** — encadeia ways adjacentes num grafo para formar
percursos maiores que qualquer via isolada (uma sessão não cabe numa via
só, e casar via a via daria nota baixa em todo candidato por um motivo
que não tem nada a ver com o terreno), roda o casador e ordena. Uma
caminhada por preferência, então as alternativas diferem no que foram
construídas para buscar.

A `const` escrita à mão que as telas mostravam **saiu**. Onde não há
busca, a tela diz isso — e diferencia "a fonte não respondeu" de "não há
via pedalável nesse raio", porque a primeira se resolve tentando de novo
e a segunda movendo o pino.

**`terrain_database.dart`** — a base local no disco. No web é
**IndexedDB** (`package:web` + `dart:js_interop`), dimensionado para os
megabytes de geometria e alturas que isto guarda, e não para os poucos
kilobytes de um armazenamento chave-valor. Duas tabelas espelham como o
índice lê: vias pelo próprio id, e por célula da grade os ids que caem
nela — uma estrada longa é gravada uma vez e listada em várias.

Na abertura o app lê de volta só a lista de células e as alturas: a lista
é o que decide se a busca precisa tocar a rede, e as alturas são a metade
cara (mil chamadas por dia). As vias são lidas por busca, para as células
daquela busca.

Tudo ali é cache, nunca fonte da verdade. Janela anônima, dados de site
bloqueados, cota recusada — cada um desses termina com o app funcionando
exatamente como antes de existir base: mais lento, nunca quebrado.

**Em nativo ainda não há base.** O diretório de documentos do app exige um
plugin que este projeto não tomou, e entregar meio funcionando seria pior
que o índice em memória que já existe.

### Fonte de dados

Ainda a decidir, e é a P0 "candidate map/road data source" de
`DECISIONS_REQUIRED.md`. O matcher recebe `List<RouteSegment>` e não sabe
de onde veio, então a escolha não toca no motor.

**Wikiloc não serve.** Não há API pública para consultar trilhas em
massa; existe widget de incorporação e acordo comercial. Raspar o site
violaria os termos deles e a regra deste repo de nunca usar endpoint não
documentado — a mesma regra que vale para as integrações.

O que serve, e é específico para ciclismo:

- **OpenStreetMap via Overpass** — `highway=cycleway`, `bicycle=designated`,
  relações `route=bicycle` (`lcn`/`rcn`/`ncn`/`icn`), `surface`,
  `smoothness`. Licença ODbL: atribuição e share-alike sobre base derivada.
- **BRouter** — roteador de bicicleta open source, com perfis de ciclismo,
  auto-hospedável e rápido.
- **Elevação** — o gradiente é o insumo principal do modelo e o OSM quase
  não traz `ele`. Precisa de um DEM (SRTM/Copernicus) próprio.

## Navegação

Duas regras, e um teste para cada uma.

**Toda tela tem saída.** Uma tela empurrada sobre outra começa com
`PageHeader` (`lib/widgets/page_header.dart`): o link de volta, o título e o
subtítulo que essas telas já escreviam à mão. Antes disso o mapa da rota e o
construtor de treino não tinham saída nenhuma - só o gesto do aparelho ou o
botão do navegador, nenhum dos dois na tela. O link nunca leva a lugar
nenhum: normalmente faz `pop`; quando não há para onde voltar (link direto
na web, ou pilha limpa) vai para a aba de treino.

Telas que ficam dentro do shell de navegação (`TrailwattShell`) não levam
header - a barra inferior ou o trilho **é** a saída delas.

**Toda tela é alcançável.** `test/navigation_exits_test.dart` percorre
`lib/routes/screen_inventory.dart` e falha se uma tela implementada não tem
saída, ou se nada no app aponta para ela. As duas coisas já estavam
quebradas: o fluxo de importar resultado inteiro existia e nenhuma tela
chegava nele.

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

### Habilitando de verdade

O código do fluxo está pronto e testado. O que separa "implementado" de
"funcionando" são os **client ids**, e só você pode obtê-los: são
registros de aplicação que cada plataforma emite para o seu app.

1. Registre um app em cada plataforma que for usar.
2. Cadastre lá o redirect: `trailwatt://oauth/strava`, `/garmin`,
   `/wahoo`, `/trainingpeaks` — no build web, o endereço da sua página em
   vez do esquema.
3. Passe os ids no build (veja "Configurando" acima). Sem id, a tela diz
   **"Indisponível nesta build"** em vez de oferecer um botão que só
   poderia falhar.

O redirect volta sozinho: o esquema `trailwatt://` está registrado no
`AndroidManifest.xml` e no `Info.plist`, e no web o app lê o `Uri.base` ao
iniciar. A plataforma é identificada pelo `state` que ela devolve, não
pelo formato da URL — cada uma monta o callback do seu jeito, e um
redirect com um `state` que ninguém emitiu não é atribuído a ninguém.

O ponto que fazia isso falhar: no web o redirect **recarrega a página**, e
a verificação PKCE morria junto com a memória do app. Ela agora espera em
`sessionStorage` (`lib/services/platform/auth_session_store.dart`), que
morre com a aba — o tempo máximo que uma autorização pela metade deveria
viver. Uma autorização vale por um redirect só: é lida e esquecida no
mesmo passo, então uma URL reapresentada não reconecta nada.

O diálogo de colar a URL continua ali como saída manual, para quando o
redirect não voltar.

### O que ainda falta para produção

Uma coisa, de propósito fora daqui em vez de meio-feita:
- **Guardar os tokens.** Eles vivem só em memória: persistir exige keystore
  do Android / keychain do iOS, e guardar token de plataforma em
  `shared_preferences` seria pior do que não guardar.

## Idiomas

A interface segue o idioma do aparelho (ou do navegador, na web) **até você
discordar**: **Perfil › Idioma** oferece Sistema, Português e English. Os
nomes das línguas aparecem sempre na própria língua - quem abriu o app num
idioma que não lê precisa conseguir achar o seu.

A escolha vive em memória, como todo o resto do estado deste app
(`lib/services/locale_store.dart`): vale para a sessão e volta a seguir o
aparelho num início limpo. Português e inglês estão traduzidos; qualquer
outro idioma cai no inglês.

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
flutter test      # 213 testes
```

Capturas de todas as telas em `docs/screenshots/` (veja o README de lá para o
motivo dos mapas aparecerem cinza nelas).

## Structure

```
lib/
  models/    domain types (rider profile, workout, route, calibration, ...)
  engine/    pure route-score calculation, shared by app and future API
  theme/     colors, text styles, ThemeData, breakpoints - design tokens
  widgets/   shared building blocks (buttons, fields, zone pill, app shell)
  screens/   one file per screen, wired together in lib/main.dart
  routes/    screen_inventory.dart - route table cross-referenced with specs
prototype/   original HTML flow prototype these screens were ported from
ui/          web-flow and mobile-flow HTML references
spec-reference/  contractual UI reference (does not override specs/)
specs/       per-feature specs (Spec Kit format)
```
