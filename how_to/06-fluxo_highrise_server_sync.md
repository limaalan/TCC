# 06 - Fluxo do sync do mapa highrise para o Server

Guia curto do script que sincroniza o `highrise` do `Client` para o `Server`.

## Objetivo

Permitir editar o mapa uma vez so no `Client` e regenerar a versao usada pelo `Server` sem ajustar manualmente duas copias.

## Arquivos envolvidos

- Script de geracao: `initial_project/generate_highrise_server_map.ps1`
- Strip visual no Server: `initial_project/shared/server_game_map.gd`
- Mapa fonte: `initial_project/Client/maps/highrise/`
- Mapa gerado no Server: `initial_project/Server/maps/highrise/server_map_highrise.tscn`

## Como funciona hoje

O script faz 4 coisas:

1. Copia `Client/maps/highrise/` para `Server/maps/highrise/`.
2. Recria `server_map_highrise.tscn` com:
   - `highRisePlayableArea`
   - `highRiseUnplayableArea`
   - `SpawnPoints`
   - `Pickups`
   - `Objectives`
   - `SpecialPlatforms`
3. Copia para `Server/assets/` os asset packages externos usados pelas cenas de geometria do highrise.
4. O `server_map_highrise.tscn` usa `res://shared/server_game_map.gd`, que remove os nodes visuais em runtime no Server.

## Fluxo de trabalho

### 1. Editar o mapa

Edite normalmente no `Client`:

- `initial_project/Client/maps/highrise/highRisePlayableArea.tscn`
- `initial_project/Client/maps/highrise/highRiseUnplayableArea.tscn`
- `initial_project/Client/maps/highrise/map_highrise.tscn` para spawns

Se voce adicionar assets novos dentro das cenas de geometria, o script tenta copiar esses assets para o `Server` tambem.

### 2. Gerar a versao do Server

Na raiz do repo, rode:

```powershell
.\initial_project\generate_highrise_server_map.ps1
```

### 3. Reimportar no Server quando necessario

Se o script copiar `.glb` ou assets novos para `initial_project/Server/assets/`, rode:

```powershell
godot --headless --path "initial_project/Server" --import
```

### 4. Testar

Suba o Server e depois o Client normalmente.

## Limitacoes atuais

Hoje o script ainda e especifico para o `highrise`.

Ele assume:

- pasta `maps/highrise`
- cena `map_highrise.tscn`
- cenas `highRisePlayableArea.tscn` e `highRiseUnplayableArea.tscn`
- `HillZone` e `DeathZone` mantidos no wrapper do Server

## Ideia futura: gerar isso para qualquer mapa

Para virar um pipeline generico, a ideia recomendada e:

1. Criar um script generico que receba `map_id`.
2. Padronizar nomes e estrutura de cada mapa, por exemplo:
   - `map_<nome>.tscn`
   - `server_map_<nome>.tscn`
   - `PlayableArea`
   - `UnplayableArea`
   - `SpawnPoints`
3. Ler os roots de gameplay do mapa fonte em vez de hardcode.
4. Detectar e copiar dependencias externas de forma generica.
5. Opcionalmente usar markers para itens server-only, por exemplo:
   - `HillZoneMarker`
   - `DeathZoneMarker`
   - `PickupMarker`

Com isso, o fluxo final vira:

```powershell
.\initial_project\generate_server_map.ps1 -MapName nome_do_mapa
```

## Resumo curto

- Edite o mapa no `Client`
- Rode `generate_highrise_server_map.ps1`
- Reimporte o `Server` se entrou asset novo
- Teste

Esse fluxo reduz bastante o retrabalho enquanto o projeto ainda esta em fase rapida de montagem e validacao de assets.
