# Sincronizar Highrise com o mapa do Server

## Objetivo

Atualizar a versão autoritativa de Highrise depois de uma alteração estrutural no mapa visual.

## Procedimento

1. Salve a alteração da cena/fontes de Highrise no Client.
2. Feche cenas abertas que possam regravar o mapa durante a cópia.
3. Na raiz do repositório, execute:

```powershell
.\initial_project\generate_highrise_server_map.ps1
```

4. Abra `initial_project/Server/maps/highrise/server_map_highrise.tscn` e confirme que a cena carrega.
5. Rode uma partida local e teste colisão, spawns, jump pads, pickups e zona de KOTH.

## Como funciona

O script mantém a versão do mapa usada pelo Server alinhada à fonte de Highrise. Durante a execução, `shared/server_game_map.gd` trata a cena do Server como mapa de gameplay e remove elementos somente visuais.

Não use esse fluxo para adicionar o Prototype ao menu; ele continua fora da seleção de modos por decisão de produto.
