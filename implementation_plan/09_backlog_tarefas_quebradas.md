# Backlog De Tarefas Quebradas

## Objetivo

Este documento quebra os refactors e entregas principais em cards pequenos, pensados para caber em até 2 horas cada, com foco em preparar a base para:

- contrato RPC menos frágil;
- suporte a mais de um mapa;
- suporte a dois modos de jogo com regras diferentes;
- build e teste mais previsíveis.

Escopo travado para o mês:

- `TEAM_DEATHMATCH` estável;
- `KING_OF_THE_HILL` como segundo modo;
- multi-mapa;
- contratos compartilhados e payloads validados;
- export/teste PC/LAN/CLI básico.

Escopo explicitamente fora do núcleo deste backlog:

- `CAPTURE_THE_FLAG`;
- munição completa e arsenal expandido;
- laser e lança-foguetes;
- powerups;
- grandes refactors visuais/polimento final.

## Backlog Principal

| ID | Lote | Nome da tarefa | História curta | Tipo | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 1 | Lote 1 | Criar `shared_src` e rotina de cópia | Ter uma fonte única para contratos compartilhados entre Client e Server. | refact | 45 min |
| 2 | Lote 1 | Criar `game_enums.gd` compartilhado | Centralizar ids de time, arma, pickup, modo e hit FX. | refact | 60 min |
| 3 | Lote 1 | Criar `net_keys.gd` compartilhado | Tirar chaves de payload de strings soltas espalhadas pelo projeto. | refact | 60 min |
| 4 | Lote 1 | Criar `net_payloads.gd` para `player_state` | Padronizar criação e validação do payload mais frequente da partida. | refact | 90 min |
| 5 | Lote 1 | Migrar `player_state` no Client e no Server | Fazer `create_player_data()` e `c_send_player_state` usarem factory e keys compartilhadas. | refact | 90 min |
| 6 | Lote 1 | Validar payloads de tiro e granada | Garantir que `c_shot_fired` e `c_try_throw_grenade` rejeitem dados inválidos sem quebrar a partida. | refact | 60 min |
| 7 | Lote 1 | Substituir ids mágicos críticos por `GameEnums` | Parar de depender de `0`, `1`, `2` para team, weapon e hit type. | refact | 90 min |
| 8 | Lote 1 | Criar `client_names.gd` e trocar `call_group` crítico | Centralizar nomes de grupos, inputs e animações usados como contrato implícito. | refact | 90 min |
| 9 | Lote 1 | Renomear `set_procecess` no fluxo completo | Remover o typo que virou contrato sem deixar chamada quebrada. | refact | 30 min |
| 10 | Lote 1 | Criar DTOs críticos de `spawn` e `end_match` | Parar de depender de RPCs longos e de `client_data` bruto para eventos importantes. | refact | 120 min |
| 11 | Lote 2 | Criar `MatchConfig.gd` | Ter um objeto único com `mode`, `map_id`, `time_limit` e `score_to_win`. | refact | 60 min |
| 12 | Lote 2 | Migrar tempo, score e modo para `MatchConfig` | Tirar regras hardcoded do lobby e centralizar no config da partida. | refact | 90 min |
| 13 | Lote 2 | Criar `MapData.gd` | Representar mapa por `id`, nome e cena em vez de `load()` hardcoded. | refact | 45 min |
| 14 | Lote 2 | Criar `MapRegistry` no Client e no Server | Resolver mapas por `map_id` nos dois projetos de forma consistente. | refact | 120 min |
| 15 | Lote 2 | Fazer Client e Server carregarem mapa por `map_id` | Permitir troca de mapa sem editar `load("res://maps/...")` em vários scripts. | feat | 120 min |
| 16 | Lote 2 | Criar `GameMap.gd` | Padronizar roots como `spawn_points_root`, `pickups_root` e `objectives_root`. | refact | 45 min |
| 17 | Lote 2 | Adaptar os dois `farm maps` para `GameMap` | Fazer `map_farm.tscn` e `server_map_farm.tscn` seguirem a mesma estrutura de roots. | refact | 120 min |
| 18 | Lote 2 | Criar `PlayerSpawnPoint` com `team` exportado | Parar de depender de prefixo `Blue` e `Red` no nome do node para saber o time. | refact | 60 min |
| 19 | Lote 2 | Migrar o lobby para usar `spawn_point.team` | Escolher spawn por dado explícito, não por convenção frágil de nome. | refact | 90 min |
| 20 | Lote 3 | Registrar um segundo `map_id` | Preparar o projeto para existir mais de um mapa no registry. | feat | 45 min |
| 21 | Lote 3 | Criar uma segunda cena de mapa protótipo | Ter um segundo mapa técnico para testar seleção e fluxo multi-mapa, mesmo que seja derivado do farm. | art | 120 min |
| 22 | Lote 3 | Extrair regras atuais de TDM para funções dedicadas | Isolar start, score, morte e fim de partida do TDM antes de adicionar outro modo. | refact | 120 min |
| 23 | Lote 3 | Criar switch central de `GameMode` no lobby | Escolher fluxo de partida por modo sem duplicar o lobby inteiro. | feat | 90 min |
| 24 | Lote 3 | Criar `HillZone` server-side e reservar `objectives_root` | Ter a peça básica do Rei do Pedaço pronta no mapa e no servidor. | feat | 120 min |
| 25 | Lote 4 | Implementar controle, score e fim de partida de KOTH | Fazer a zona contar controle por time, pontuar por tempo e encerrar a partida pela regra do modo. | feat | 120 min |
| 26 | Lote 4 | Replicar estado da hill e mostrar HUD mínimo | Mostrar no client quem controla a zona e o progresso básico do modo. | feat | 120 min |
| 27 | Lote 4 | Criar `NetworkConfig` para IP e porta | Permitir client conectar por IP configurável e server subir com porta configurável. | deploy | 120 min |
| 28 | Lote 4 | Criar `export_presets.cfg` Client e Server | Destravar export por CLI e build repetível fora do editor. | deploy | 60 min |
| 29 | Lote 4 | Rodar smoke test em 2 mapas e 2 modos | Validar TDM e KOTH com dois clients, troca de mapa, spawn, score e tela final. | deploy | 90 min |

## Backlog Secundário Se Sobrar Tempo

| ID | Lote | Nome da tarefa | História curta | Tipo | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 30 | Extra | Criar `NetworkEntity` para pickups e granadas | Parar de usar `node.name` como id de rede frágil. | refact | 90 min |
| 31 | Extra | Criar `WeaponGameplayData` no Server | Centralizar dano, precisão e projéteis fora de `Dictionary` solto. | refact | 90 min |
| 32 | Extra | Criar `WeaponPresentationData` no Client | Centralizar cena, cooldown, SFX, recoil e shake da arma. | refact | 90 min |
| 33 | Extra | Criar `WeaponRegistry` e migrar pistol, SMG e shotgun | Tirar `match weapon_id` espalhado do fluxo de armas. | refact | 120 min |
| 34 | Extra | Criar `PickupData` para vida e granada | Tirar regras de pickup de valores hardcoded em script e cena. | refact | 120 min |
| 35 | Extra | Limpar `AudioManager` para `AudioEventData` | Fazer o áudio executar configs em vez de ser catálogo manual de tudo. | refact | 90 min |

## Ordem Recomendada

| Lote | Foco | Cards |
| --- | --- | --- |
| Lote 1 | Contratos de rede e enums | 1 a 10 |
| Lote 2 | `MatchConfig`, `MapData` e multi-mapa | 11 a 19 |
| Lote 3 | Segundo mapa e base de modos | 20 a 24 |
| Lote 4 | KOTH, deploy e smoke test | 25 a 29 |

## Regras De Execução

| Regra | Motivo |
| --- | --- |
| Abrir no máximo 3 cards ao mesmo tempo | Evita dispersão e sensação de backlog infinito |
| Fechar o Lote 1 inteiro antes de abrir KOTH | Modo novo em cima de contrato frágil vira retrabalho |
| Escolher KOTH como segundo modo | É menor e mais seguro que CTF para o prazo |
| Usar o segundo mapa como mapa técnico primeiro | Valida o sistema antes de gastar energia em arte e polimento |
| Se um card passar de 2h, parar e dividir de novo | Mantém o projeto digerível e previsível |

## Sugestão De Uso No GitHub

| Campo | Sugestão |
| --- | --- |
| Título da issue | Usar exatamente a coluna `Nome da tarefa` |
| Descrição curta | Usar exatamente a coluna `História curta` |
| Label de tipo | Usar exatamente a coluna `Tipo` |
| Milestone | `Lote 1`, `Lote 2`, `Lote 3` ou `Lote 4` |
| Ordem de criação | Seguir a coluna `ID` |

## Recorte Mais Seguro Para Entrega

Se o mês apertar, o recorte mínimo mais seguro é:

| Prioridade mínima | Cards |
| --- | --- |
| Base de contratos | 1 a 10 |
| Multi-mapa | 11 a 21 |
| Dois modos | 22 a 26 |
| Export e teste | 27 a 29 |

Esse recorte já entrega uma base sólida e coerente com o plano de refatoração e com a apresentação final do projeto.
