# Power-ups e efeitos temporários

## O que faz

Aplica buffs temporários de dano e velocidade de disparo coletados no mapa. A HUD informa quais efeitos pertencem ao jogador e mostra um temporizador visual de duração aproximada.

## Como funciona

O Server identifica a coleta, guarda o efeito ativo no controlador do jogador e agenda sua remoção após a duração configurada. O multiplicador de dano e o multiplicador de cooldown são consultados pelo combate no Server.

Ao iniciar ou terminar um efeito, o Server notifica os Clients. Para o jogador local, o Client cria um item no container sobre as informações de munição/granada; o relógio visual começa com a duração recebida. Ele é indicativo: a expiração efetiva continua sendo a do Server.

## Onde fica no projeto

- Tipo de efeito: `shared/powerups/powerup_effect_data.gd` e `shared/game_enums.gd`.
- Autoridade e duração: `Server/player/powerups/player_powerup_controller.gd`.
- Replicação: `Server/server/lobby.gd`.
- HUD e efeito no personagem: `Client/player/local/player_local.gd`, `Client/ui/hud/powerup_status_item.tscn` e `Client/player/`.

## Rede e autoridade

O Server envia tipo, duração e multiplicadores quando o buff começa, e um evento de término ao expirar, morrer ou trocar de estado. Um Client que entra depois recebe os power-ups ativos na sincronização do lobby.
