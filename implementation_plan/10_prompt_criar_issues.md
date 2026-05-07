# Prompt Para Criar Issues

## Objetivo

Este documento existe para ser usado diretamente em outro ChatGPT com acesso às ações do GitHub, para criar as tasks do projeto sem precisar reinterpretar o plano inteiro.

## Prompt Pronto: Backlog Principal

Copiar e colar o bloco abaixo no outro ChatGPT:

```text
Crie uma GitHub Issue para cada linha da tabela “Backlog Principal” abaixo.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “Descrição” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo.
- Crie apenas as issues do backlog principal nesta execução.
- Ao final, apenas informe quais issues foram criadas.
```

## Backlog Principal

| ID | Título | Descrição | Tipo | Milestone | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 1 | Criar `shared_src` e rotina de cópia | Ter uma fonte única para contratos compartilhados entre Client e Server. | refact | Lote 1 | 45 min |
| 2 | Criar `game_enums.gd` compartilhado | Centralizar ids de time, arma, pickup, modo e hit FX. | refact | Lote 1 | 60 min |
| 3 | Criar `net_keys.gd` compartilhado | Tirar chaves de payload de strings soltas espalhadas pelo projeto. | refact | Lote 1 | 60 min |
| 4 | Criar `net_payloads.gd` para `player_state` | Padronizar criação e validação do payload mais frequente da partida. | refact | Lote 1 | 90 min |
| 5 | Migrar `player_state` no Client e no Server | Fazer `create_player_data()` e `c_send_player_state` usarem factory e keys compartilhadas. | refact | Lote 1 | 90 min |
| 6 | Validar payloads de tiro e granada | Garantir que `c_shot_fired` e `c_try_throw_grenade` rejeitem dados inválidos sem quebrar a partida. | refact | Lote 1 | 60 min |
| 7 | Substituir ids mágicos críticos por `GameEnums` | Parar de depender de `0`, `1`, `2` para team, weapon e hit type. | refact | Lote 1 | 90 min |
| 8 | Criar `client_names.gd` e trocar `call_group` crítico | Centralizar nomes de grupos, inputs e animações usados como contrato implícito. | refact | Lote 1 | 90 min |
| 9 | Renomear `set_procecess` no fluxo completo | Remover o typo que virou contrato sem deixar chamada quebrada. | refact | Lote 1 | 30 min |
| 10 | Criar DTOs críticos de `spawn` e `end_match` | Parar de depender de RPCs longos e de `client_data` bruto para eventos importantes. | refact | Lote 1 | 120 min |
| 11 | Criar `MatchConfig.gd` | Ter um objeto único com `mode`, `map_id`, `time_limit` e `score_to_win`. | refact | Lote 2 | 60 min |
| 12 | Migrar tempo, score e modo para `MatchConfig` | Tirar regras hardcoded do lobby e centralizar no config da partida. | refact | Lote 2 | 90 min |
| 13 | Criar `MapData.gd` | Representar mapa por `id`, nome e cena em vez de `load()` hardcoded. | refact | Lote 2 | 45 min |
| 14 | Criar `MapRegistry` no Client e no Server | Resolver mapas por `map_id` nos dois projetos de forma consistente. | refact | Lote 2 | 120 min |
| 15 | Fazer Client e Server carregarem mapa por `map_id` | Permitir troca de mapa sem editar `load("res://maps/...")` em vários scripts. | feat | Lote 2 | 120 min |
| 16 | Criar `GameMap.gd` | Padronizar roots como `spawn_points_root`, `pickups_root` e `objectives_root`. | refact | Lote 2 | 45 min |
| 17 | Adaptar os dois `farm maps` para `GameMap` | Fazer `map_farm.tscn` e `server_map_farm.tscn` seguirem a mesma estrutura de roots. | refact | Lote 2 | 120 min |
| 18 | Criar `PlayerSpawnPoint` com `team` exportado | Parar de depender de prefixo `Blue` e `Red` no nome do node para saber o time. | refact | Lote 2 | 60 min |
| 19 | Migrar o lobby para usar `spawn_point.team` | Escolher spawn por dado explícito, não por convenção frágil de nome. | refact | Lote 2 | 90 min |
| 20 | Registrar um segundo `map_id` | Preparar o projeto para existir mais de um mapa no registry. | feat | Lote 3 | 45 min |
| 21 | Criar uma segunda cena de mapa protótipo | Ter um segundo mapa técnico para testar seleção e fluxo multi-mapa, mesmo que seja derivado do farm. | art | Lote 3 | 120 min |
| 22 | Extrair regras atuais de TDM para funções dedicadas | Isolar start, score, morte e fim de partida do TDM antes de adicionar outro modo. | refact | Lote 3 | 120 min |
| 23 | Criar switch central de `GameMode` no lobby | Escolher fluxo de partida por modo sem duplicar o lobby inteiro. | feat | Lote 3 | 90 min |
| 24 | Criar `HillZone` server-side e reservar `objectives_root` | Ter a peça básica do Rei do Pedaço pronta no mapa e no servidor. | feat | Lote 3 | 120 min |
| 25 | Implementar controle, score e fim de partida de KOTH | Fazer a zona contar controle por time, pontuar por tempo e encerrar a partida pela regra do modo. | feat | Lote 4 | 120 min |
| 26 | Replicar estado da hill e mostrar HUD mínimo | Mostrar no client quem controla a zona e o progresso básico do modo. | feat | Lote 4 | 120 min |
| 27 | Criar `NetworkConfig` para IP e porta | Permitir client conectar por IP configurável e server subir com porta configurável. | deploy | Lote 4 | 120 min |
| 28 | Criar `export_presets.cfg` Client e Server | Destravar export por CLI e build repetível fora do editor. | deploy | Lote 4 | 60 min |
| 29 | Rodar smoke test em 2 mapas e 2 modos | Validar TDM e KOTH com dois clients, troca de mapa, spawn, score e tela final. | deploy | Lote 4 | 90 min |

## Prompt Pronto: Backlog Secundário

Copiar e colar o bloco abaixo no outro ChatGPT quando quiser criar apenas os cards extras:

```text
Crie uma GitHub Issue para cada linha da tabela “Backlog Secundário” abaixo.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “Descrição” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo.
- Crie apenas as issues do backlog secundário nesta execução.
- Ao final, apenas informe quais issues foram criadas.
```

## Backlog Secundário

| ID | Título | Descrição | Tipo | Milestone | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 30 | Criar `NetworkEntity` para pickups e granadas | Parar de usar `node.name` como id de rede frágil. | refact | Extra | 90 min |
| 31 | Criar `WeaponGameplayData` no Server | Centralizar dano, precisão e projéteis fora de `Dictionary` solto. | refact | Extra | 90 min |
| 32 | Criar `WeaponPresentationData` no Client | Centralizar cena, cooldown, SFX, recoil e shake da arma. | refact | Extra | 90 min |
| 33 | Criar `WeaponRegistry` e migrar pistol, SMG e shotgun | Tirar `match weapon_id` espalhado do fluxo de armas. | refact | Extra | 120 min |
| 34 | Criar `PickupData` para vida e granada | Tirar regras de pickup de valores hardcoded em script e cena. | refact | Extra | 120 min |
| 35 | Limpar `AudioManager` para `AudioEventData` | Fazer o áudio executar configs em vez de ser catálogo manual de tudo. | refact | Extra | 90 min |

## Prompt Pronto: Todos Os Cards

Se quiser criar tudo de uma vez, copiar e colar:

```text
Crie uma GitHub Issue para cada linha das tabelas “Backlog Principal” e “Backlog Secundário” do documento atual.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “Descrição” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo.
- Ao final, apenas informe quais issues foram criadas.
```
