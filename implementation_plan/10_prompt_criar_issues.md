# Prompt Para Criar Issues

## Objetivo

Este documento existe para ser usado diretamente em outro ChatGPT com acesso às ações do GitHub, para criar as tasks da fase atual do projeto sem precisar reinterpretar o plano inteiro.

Este arquivo está focado apenas no que vem do `Lote 2` em diante.

Ficam fora deste prompt:

- tasks do `Lote 1`;
- backlog já concluído de base de contratos/enums;
- qualquer issue extra fora das tabelas deste arquivo.

## Prompt Pronto: Lote 2 Em Diante

Copiar e colar o bloco abaixo no outro ChatGPT:

```text
Crie uma GitHub Issue para cada linha da tabela “Backlog Lote 2 Em Diante” abaixo.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “História curta” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo técnico além do que já está na linha.
- Crie apenas as issues do Lote 2 em diante nesta execução.
- Ao final, apenas informe quais issues foram criadas.
```

## Backlog Lote 2 Em Diante

| ID | Título | História curta | Tipo | Milestone | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 11 | Criar `MatchConfig.gd` | Como dev, quero um `MatchConfig` único para definir modo, mapa, tempo e score sem hardcode espalhado no lobby. | refact | Lote 2 | 60 min |
| 12 | Migrar tempo, score e modo para `MatchConfig` | Como dev, quero que o lobby leia regras da partida do `MatchConfig` para mudar a partida sem caçar constantes soltas. | refact | Lote 2 | 90 min |
| 13 | Criar `MapData.gd` | Como dev, quero representar mapa por `id`, nome e cena para parar de depender de `load()` hardcoded. | refact | Lote 2 | 45 min |
| 14 | Criar `MapRegistry` no Client e no Server | Como dev, quero resolver mapas por `map_id` nos dois projetos para manter Client e Server sincronizados ao trocar mapa. | refact | Lote 2 | 120 min |
| 15 | Fazer Client e Server carregarem mapa por `map_id` | Como dev, quero carregar mapa por `map_id` para permitir mais de um mapa sem editar vários scripts. | feat | Lote 2 | 120 min |
| 16 | Criar `GameMap.gd` | Como dev, quero um `GameMap` com roots exportados para spawns, pickups e objetivos ficarem padronizados. | refact | Lote 2 | 45 min |
| 17 | Adaptar os dois `farm maps` para `GameMap` | Como dev, quero que os dois mapas farm sigam a mesma estrutura para reduzir fragilidade entre Client e Server. | refact | Lote 2 | 120 min |
| 18 | Criar `PlayerSpawnPoint` com `team` exportado | Como dev, quero spawns com `team` explícito para remover dependência dos nomes `Blue` e `Red`. | refact | Lote 2 | 60 min |
| 19 | Migrar o lobby para usar `spawn_point.team` | Como dev, quero que o lobby escolha spawn por dado explícito para evitar erro por convenção frágil de nome. | refact | Lote 2 | 90 min |
| 20 | Registrar um segundo `map_id` | Como dev, quero um segundo `map_id` válido para provar que o sistema de multi-mapa já funciona na prática. | feat | Lote 3 | 45 min |
| 21 | Criar uma segunda cena de mapa protótipo | Como dev, quero um segundo mapa técnico para testar troca de mapa e fluxo multi-mapa sem depender de arte final. | art | Lote 3 | 120 min |
| 22 | Extrair regras atuais de TDM para funções dedicadas | Como dev, quero separar a lógica atual do TDM para adicionar outro modo sem duplicar o lobby inteiro. | refact | Lote 3 | 120 min |
| 23 | Criar switch central de `GameMode` no lobby | Como dev, quero escolher o fluxo da partida por `GameMode` para suportar mais de um modo com menos acoplamento. | feat | Lote 3 | 90 min |
| 24 | Criar `HillZone` server-side e reservar `objectives_root` | Como dev, quero a base server-side do Rei do Pedaço pronta no mapa para começar a pontuação por controle de área. | feat | Lote 3 | 120 min |
| 25 | Implementar controle, score e fim de partida de KOTH | Como dev, quero que o modo KOTH conte controle, pontue por tempo e termine pela regra correta. | feat | Lote 4 | 120 min |
| 26 | Replicar estado da hill e mostrar HUD mínimo | Como jogador, quero ver quem controla a zona e o estado básico do objetivo para entender o modo KOTH durante a partida. | feat | Lote 4 | 120 min |
| 27 | Criar `NetworkConfig` para IP e porta | Como dev, quero configurar IP e porta de Client/Server para testar fora do localhost e preparar deploy real. | deploy | Lote 4 | 120 min |
| 28 | Criar `export_presets.cfg` Client e Server | Como dev, quero presets de export para gerar build repetível por CLI sem depender do editor. | deploy | Lote 4 | 60 min |
| 29 | Rodar smoke test em 2 mapas e 2 modos | Como dev, quero validar TDM e KOTH em dois mapas para fechar a fase com confiança mínima de entrega. | deploy | Lote 4 | 90 min |

## Prompt Pronto: Backlog Secundário

Copiar e colar o bloco abaixo no outro ChatGPT quando quiser criar apenas os cards extras:

```text
Crie uma GitHub Issue para cada linha da tabela “Backlog Secundário” abaixo.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “História curta” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo.
- Crie apenas as issues do backlog secundário nesta execução.
- Ao final, apenas informe quais issues foram criadas.
```

## Backlog Secundário

| ID | Título | História curta | Tipo | Milestone | Tempo alvo |
| --- | --- | --- | --- | --- | --- |
| 30 | Criar `NetworkEntity` para pickups e granadas | Como dev, quero ids explícitos de rede para pickups e granadas para reduzir a fragilidade de usar `node.name` como contrato. | refact | Extra | 90 min |
| 31 | Criar `WeaponGameplayData` no Server | Como dev, quero os dados de gameplay das armas fora de `Dictionary` solto para evoluir balanceamento com menos risco. | refact | Extra | 90 min |
| 32 | Criar `WeaponPresentationData` no Client | Como dev, quero os dados visuais e de áudio das armas centralizados para reduzir `match` e espalhamento de config. | refact | Extra | 90 min |
| 33 | Criar `WeaponRegistry` e migrar pistol, SMG e shotgun | Como dev, quero resolver armas por registry para preparar armas novas sem replicar lógica por id em vários scripts. | refact | Extra | 120 min |
| 34 | Criar `PickupData` para vida e granada | Como dev, quero a configuração de pickups separada do script para preparar munição, arma e powerups depois. | refact | Extra | 120 min |
| 35 | Limpar `AudioManager` para `AudioEventData` | Como dev, quero que o áudio execute configs em vez de depender de catálogo manual por `match` e path hardcoded. | refact | Extra | 90 min |

## Prompt Pronto: Todos Os Cards Desta Fase

Se quiser criar tudo de uma vez, copiar e colar:

```text
Crie uma GitHub Issue para cada linha das tabelas “Backlog Lote 2 Em Diante” e “Backlog Secundário” do documento atual.

Regras:
- Crie exatamente uma issue por linha.
- Use o título exatamente como está na coluna “Título”.
- Use o texto da coluna “História curta” como corpo principal da issue.
- No corpo da issue, adicione também a linha “Tempo alvo: <valor da coluna Tempo alvo>”.
- Aplique exatamente a label da coluna “Tipo”.
- Defina a milestone exatamente como está na coluna “Milestone”.
- Não crie PR, branch, commit, comentário, checklist grande ou subtasks extras.
- Não reescreva o escopo.
- Ao final, apenas informe quais issues foram criadas.
```

## Observação

Se quiser criar apenas um lote por vez, a recomendação é criar primeiro:

- `Lote 2`

Depois:

- `Lote 3`
- `Lote 4`

Assim o backlog no GitHub fica mais limpo e acompanha melhor a ordem real de execução do projeto.
