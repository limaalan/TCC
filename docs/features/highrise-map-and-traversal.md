# Mapa Highrise e deslocamento

## O que faz

Highrise é o mapa selecionável das partidas atuais. Ele reúne geometria visual, colisões autoritativas, spawns, pickups, zona de KOTH e jump pads.

## Como funciona

O Client carrega a cena visual de Highrise. O Server carrega a cena correspondente para simulação e remove elementos estritamente visuais pelo comportamento compartilhado de mapa de servidor. A geometria usada por ambos deriva do fluxo de sincronização do mapa, evitando criar manualmente duas versões independentes.

Jump pads são registrados pelo Server com um identificador de plataforma e aplicam impulso validado na simulação. Spawns, pickups e hill zones são descobertos durante o carregamento do lobby.

## Onde fica no projeto

- Client: `Client/maps/highrise/map_highrise.tscn`.
- Server: `Server/maps/highrise/server_map_highrise.tscn`.
- Registro: `Client/maps/map_registry.gd`, `Server/maps/map_registry.gd` e `shared/map_data.gd`.
- Mapa autoritativo: `shared/server_game_map.gd`.
- Sincronização: `initial_project/generate_highrise_server_map.ps1`.

## Configuração e extensão

Mudanças estruturais no mapa devem passar pelo fluxo de sincronização e validação descrito em [sincronizar Highrise](../how_to/synchronize-highrise-server-map.md). Não adicione o Prototype à seleção do menu apenas por estar registrado.
