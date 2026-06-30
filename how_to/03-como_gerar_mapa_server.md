# 03 - Como gerar mapa server automaticamente

Ideia de pipeline para manter um mapa autoral unico e gerar a versao server de forma automatica.

## Objetivo

Hoje o projeto tem dois mapas por cena principal:

- client map com visual
- server map focado em colisao e gameplay

O objetivo desta abordagem e:

- editar um mapa autoral so uma vez
- reaproveitar os mesmos prefabs modulares
- gerar automaticamente a versao server
- evitar divergencia entre client e server

## Fonte de verdade

Use um mapa autoral como fonte principal.

Esse mapa pode conter:

- meshes
- prefabs modulares com colisoes
- `SpawnPoints`
- `Pickups`
- `Objectives`
- `SpecialPlatforms`

## O que a versao server precisa manter

A versao server nao precisa de visual, mas precisa manter:

- colisao de movimento
- colisao exact para raycast
- pickups
- spawn points
- objetivos
- plataformas especiais e outros elementos de gameplay

## Estrategia recomendada

1. Duplicar a cena autoral.
2. Percorrer a arvore inteira.
3. Remover elementos puramente visuais.
4. Manter `StaticBody3D`, `CollisionShape3D` e outros nos de gameplay.
5. Salvar o resultado como `server_map_<nome>.tscn`.

## O que remover na geracao

Normalmente remover:

- `MeshInstance3D`
- nodes decorativos sem gameplay
- efeitos visuais
- audio ambiente visual
- cameras usadas so para preview

## O que manter na geracao

Manter:

- `StaticBody3D`
- `CollisionShape3D`
- `Area3D` que afetem gameplay
- `Pickups`
- `SpawnPoints`
- `Objectives`
- `SpecialPlatforms`
- script raiz do `GameMap`

## Relacao com prefabs modulares

Se cada asset modular ja tiver:

- `PlayerCollision`
- `ExactCollision`

entao a geracao da versao server fica muito mais simples.

O script pode apenas:

- apagar `VisualRoot`
- manter os colliders

Isso e melhor do que tentar reconstruir colisao global depois.

## Estrutura sugerida do mapa autoral

```text
Map
- Environment
  - Prefabs modulares de cenario
- SpawnPoints
- Pickups
- Objectives
- SpecialPlatforms
```

Na geracao server:

- `Environment` pode permanecer
- mas os visuais dentro dele sao removidos
- os colliders internos continuam

## Formato do arquivo gerado

Padrao sugerido:

- mapa autoral: `map_farm_authoring.tscn`
- mapa client final: `map_farm.tscn`
- mapa server final: `server_map_farm.tscn`

Ou, se preferir menos etapas:

- mapa autoral = client map final
- script gera apenas `server_map_farm.tscn`

## Tipo de implementacao

Melhor opcao:

- `EditorScript`
- ou script `@tool`

Esse script pode:

- abrir a cena autoral
- duplicar a arvore
- limpar visuais
- validar roots obrigatorios
- salvar o arquivo final

## Validacoes uteis no script

Durante a geracao, o script deve validar:

1. O mapa tem `SpawnPoints`.
2. O mapa tem `Objectives` quando necessario.
3. Pickups tem `network_id` valido.
4. `ExactCollision` esta na layer `16`.
5. Nenhuma `ConcavePolygonShape3D` exact esta vazia.

## Tamanho do refactor no codigo

Para suportar esse pipeline, o refactor tende a ser pequeno a medio.

Pequeno se:

- o mapa autoral ja mantiver os roots esperados pelo `GameMap`
- os assets modulares ja tiverem colisoes corretas

Medio se:

- voce quiser formalizar convencoes de prefab
- criar script de validacao e geracao
- adaptar o fluxo da equipe para sempre editar o mapa fonte

Grande nao parece necessario neste momento.

## Beneficios

- menos retrabalho
- menos chance de client/server divergirem
- montagem de mapa mais rapida
- colisoes mais proximas do asset real
- pipeline mais escalavel para mapas maiores

## Riscos e cuidados

- prefabs mal configurados podem ir quebrados para client e server ao mesmo tempo
- `ExactCollision` vazia passa despercebida se nao houver validacao
- remover visual automaticamente exige cuidado para nao apagar nodes de gameplay por acidente

## Conclusao

Se o projeto seguir o padrao modular de prefab, gerar `server_map` automaticamente passa a ser uma extensao natural do pipeline.

Direcao recomendada:

1. Padronizar prefabs modulares de cenario.
2. Usar um mapa autoral unico.
3. Criar um script que gere `server_map_<nome>.tscn` removendo apenas o visual.

Esse caminho reduz manutencao e combina bem com a estrutura atual do projeto.
