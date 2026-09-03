# Armas, combate e granadas

## O que faz

Implementa seleção de arma, cadência, disparo, dano, morte e granadas. O jogador recebe feedback local imediato, mas o Server confirma o resultado que vale para a partida.

## Como funciona

As armas são definidas por recursos compartilhados com atributos como dano, cadência e requisitos de munição. O Client solicita o disparo e apresenta modelo, áudio e efeitos. O Server verifica a solicitação, aplica a regra de arma, calcula dano e comunica o resultado aos participantes.

Granadas são entidades dinâmicas criadas no Server. Elas possuem identificador de rede, posição replicada, quantidade limitada por jogador e evento de explosão comunicado aos Clients.

## Onde fica no projeto

- Catálogo: `shared/weapons/weapon_definition.gd` e `shared/weapons/weapon_catalog.gd`.
- Validação e dano: `Server/server/lobby.gd`, `Server/player/` e cenas de arma/granada em `Server/player/`.
- Apresentação: `Client/player/local/player_local.gd`, `Client/weapons/`, `Client/player/grenade/` e `Client/game/audio/`.
- IDs de granada: `shared/network_entity.gd`.

## Rede e autoridade

O Server aceita ou recusa o disparo conforme estado do jogador e munição. A explosão e a remoção da granada também nascem no Server. O Client não deve aplicar dano definitivo nem criar uma granada autoritativa.
