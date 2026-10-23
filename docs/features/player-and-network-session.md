# Jogador, times e sessão em rede

## O que faz

Permite que um jogador configure seu nome, conecte-se ao servidor, entre em um lobby e controle a própria instância durante a partida. O servidor define o time, spawn e ciclo de vida de cada jogador; o Client diferencia a própria instância das representações remotas.

## Como funciona

1. O Client lê endereço, porta e nome das configurações locais.
2. O Server associa o cliente a um lobby com o preset solicitado.
3. Ao iniciar a partida, o Server cria o jogador autoritativo, atribui spawn e time.
4. Cada Client cria ou atualiza a apresentação local/remota a partir dos dados replicados.

O time é usado pelos modos, placar, materiais do personagem e indicadores de HUD. A morte limpa efeitos temporários, agenda respawn e restaura o estado inicial de munição.

## Onde fica no projeto

- Client: `Client/game/settings_manager.gd`, `Client/player/local/player_local.gd` e `Client/player/remote/`.
- Server: `Server/server/server.gd`, `Server/server/lobby.gd` e `Server/player/player_server_real.gd`.
- Compartilhado: `shared/game_enums.gd`, `shared/match_config.gd` e `shared/network_config.gd`.

## Rede e autoridade

O Client controla a entrada e apresenta sua movimentação, mas o Server é dono da presença no lobby, time, spawn, morte e respawn. Dados de entidades são identificados com chaves de `shared/network_entity.gd`.
