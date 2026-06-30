# Feature: novo sistema de municao

## Visao geral

Esta branch substitui o modelo antigo de armas e municao, que estava mais espalhado e parcialmente hardcoded, por um fluxo mais consistente entre client e server.

O sistema novo cobre:

- catalogo compartilhado de armas
- dados de gameplay vindos de `WeaponDefinition`
- troca de arma por slot `1`, `2` e `3`
- inventario de municao por arma
- consumo de municao no client e validacao no server
- sincronizacao de municao entre server e client local
- HUD de municao
- pickup de municao
- regra de spawn/respawn em que so a arma escolhida nasce com municao inicial

## Estrutura implementada

O ponto central ficou em `initial_project/shared/weapons/`.

- `weapon_definition.gd` define os dados de gameplay da arma: `damage`, `accuracy`, `projectiles`, `shot_cooldown`, `is_automatic`, `start_ammo`, `max_ammo` e `ammo_per_shot`
- `weapon_catalog.gd` concentra o acesso as armas disponiveis e evita hardcode espalhado
- `weapon_ammo_inventory.gd` concentra a regra de inventario e as operacoes de gasto, adicao, snapshot e restauracao

Com isso, client e server passam a compartilhar a mesma definicao de arma e a mesma regra base de municao.

## Fluxo de armas

Antes, parte do comportamento da arma ficava separada em configuracoes locais e em logica de servidor. Agora:

- o server usa `WeaponCatalog` para validar `weapon_id` e calcular disparo
- o client usa `WeaponCatalog` para troca por slot e para ler `shot_cooldown` e `is_automatic`
- a presentation da arma ficou separada do gameplay: visual e recoil continuam no client, mas regra de tiro e municao vem do catalogo compartilhado

Essa separacao foi importante para evitar duplicacao de regra e reduzir divergencia entre client e server.

## Fluxo de municao

Cada player passou a ter um `WeaponAmmoInventory`.

Operacoes principais:

- `spend_for_shot(weapon_id)`
- `add_ammo(weapon_id, amount)`
- `set_ammo(weapon_id, amount)`
- `make_snapshot()`
- `apply_snapshot(snapshot)`
- `setup_spawn_ammo(selected_weapon_id)`

A decisao principal aqui foi tratar a municao como inventario por arma, e nao como um valor solto da arma atualmente equipada. Isso facilita troca rapida, pickup, respawn e sincronizacao.

## Autoridade de rede

O client faz a resposta imediata para a sensacao de controle:

- troca de arma local
- atualizacao imediata da HUD
- tentativa local de gastar municao antes de tocar FX de tiro

Mas o server continua sendo a fonte de verdade:

- valida a arma equipada
- gasta municao de forma autoritativa
- cancela tiro se a arma estiver sem municao
- envia correcoes de ammo para o client local
- envia snapshot completo no spawn e no respawn

Arquiteturalmente, isso manteve um modelo classico de client responsivo + server autoritativo.

## Spawn e respawn

O fluxo mais novo da branch foi a mudanca de inicializacao de municao no nascimento.

Regra final:

- ao nascer, apenas a arma escolhida na tela de selecao recebe `start_ammo`
- as outras armas existem no inventario, mas com valor `0`
- trocar de arma durante a vida nao cria municao
- ao morrer e escolher outra arma, o inventario anterior e descartado e recriado

A regra ficou centralizada no proprio `WeaponAmmoInventory`, nao no `Lobby`. O `Lobby` apenas informa qual arma foi escolhida no spawn.

## Sincronizacao com o client

No spawn:

- o client recebe `weapon_id` no `s_spawn_player`
- o `PlayerLocal` faz uma inicializacao otimista para a HUD nao aparecer vazia
- em seguida o server envia `s_sync_ammo_inventory` com o snapshot completo do inventario

Durante a partida:

- quando o server confirma ou corrige municao, ele usa `s_update_ammo`
- quando o estado inteiro precisa ser refeito, como no spawn/respawn, ele usa snapshot

A decisao de usar snapshot no spawn foi para evitar varios RPCs separados e simplificar manutencao futura.

## Pickup e HUD

A HUD base passou a mostrar a municao atual da arma equipada, entao o contador aparece em qualquer gamemode que use o `PlayerLocal`.

O pickup de municao foi integrado ao fluxo novo:

- o server identifica a arma equipada do jogador
- adiciona municao somente nessa arma
- sincroniza o novo valor para o client local
- o pickup nao desbloqueia todas as armas ao mesmo tempo

## Decisoes arquiteturais principais

- Gameplay compartilhado: dados de arma foram movidos para recursos compartilhados, reduzindo hardcode no server e divergencia com o client.
- Separacao entre gameplay e presentation: recoil, mesh, icone e audio continuam no lado de presentation; regras de tiro e municao ficaram no lado compartilhado.
- Server autoritativo: disparo e municao sao sempre confirmados no server.
- Inventario por arma: a municao nao pertence apenas a arma ativa, e sim ao estado completo do jogador.
- Snapshot para estado inicial: spawn e respawn usam sincronizacao de inventario completo, que e mais robusta do que varios updates isolados.
- Regra de spawn centralizada: a logica de "so a arma escolhida nasce com municao" ficou encapsulada no inventario, e nao espalhada no fluxo de rede.

## Resultado pratico

- o sistema de armas e municao ficou mais coerente entre client e server
- trocar de arma nao gera municao gratis
- armas nao escolhidas podem existir com `0` de municao sem quebrar HUD ou logica
- pickup de municao respeita a arma equipada
- o server bloqueia tiro sem municao
- o spawn/respawn agora respeita a escolha de arma como unica origem de municao inicial
