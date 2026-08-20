# Screenshots

Capturadas do app real (`flutter build web` + Chromium headless, viewport de
telefone 390pt @2x). O script que as gera está em `shoot.js`.

| Arquivo | Tela |
|---|---|
| `01-splash.png` | 01 Abertura |
| `01a-login.png` | 01a Entrar |
| `01b-criar-conta.png` | 01a Criar conta |
| `02-perfil.png` | 02 Perfil |
| `02a-criar-treino.png` | 02a Criar treino |
| `02a2-onde-treinar.png` | 02a2 Onde treinar |
| `03-treino-do-dia.png` | 03 Treino do dia |
| `04-rota-no-mapa.png` | 04 Rota no mapa |
| `05-editar-rota.png` | 05 Editar rota |
| `06-importar-resultado.png` | 06 Importar resultado |
| `06a-manual-intervalado.png` | 06a Manual, intervalado |
| `06b-manual-continuo.png` | 06b Manual, contínuo |
| `07-historico.png` | 07 Histórico |
| `08a-calendario-semana.png` | 08a Calendário, semana |
| `08b-calendario-dia-concluido.png` | 08b Calendário, dia concluído |
| `08c-calendario-mes.png` | 08c Calendário, mês |
| `web-landing.png` | Landing page (web, 1440px) |

## Por que os mapas aparecem cinza

O ambiente onde estas imagens foram geradas bloqueia, por política de rede,
tanto os servidores de tiles (`tile.openstreetmap.org` e alternativas) quanto
o servidor de rotas (`router.project-osrm.org`).

Isso **não** é um defeito do app: é exatamente o estado degradado que ele foi
feito para mostrar. Sem malha viária o traçado vira linha reta, e a tela avisa
("Servico de rotas indisponivel — distancia em linha reta") em vez de exibir
um número com cara de preciso. Rodando localmente, com rede normal, as telas
04, 05 e 02a2 carregam o mapa e a rota segue as ruas.

## Edição das tabelas de zona

`edicao-de-zonas/` mostra o editor da tela de perfil em uso:

- `1-tabela-personalizada.png` — tabela de potência trocada para
  PERSONALIZADA: cada zona ganha um campo de limite inferior editável, e o
  limite superior é derivado da zona seguinte.
- `2-limite-invalido-bloqueia-salvar.png` — com Z4 abaixo de Z3 a tabela é
  marcada como inválida e "Salvar perfil" fica desabilitado, em vez de gravar
  uma tabela com sobreposição.

## Verificação do roteamento

`verificacao-roteamento/` prova que o caminho de código de rota/edição
funciona, capturado com um servidor local que responde no formato OSRM:

- `04-rota-seguindo-vias.png` — traçado multiponto acompanhando a geometria
  devolvida pelo roteador; a distância (1237 m) vem da rota, não do valor fixo
  do modelo.
- `05-antes-do-arraste.png` — trecho editável com as três alças.
- `05-depois-do-arraste-reroteado.png` — depois de arrastar a alça do meio: o
  ponto encaixou na via (23 m), a rota foi refeita (1,24 km → 1,47 km) e o
  painel de impacto apareceu.

A **geometria desse servidor local é sintética** — serve para verificar o
comportamento do app, não é dado cartográfico real.
