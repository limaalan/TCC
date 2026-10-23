# Munição e pickups de munição

## O que faz

Mantém a quantidade de munição por arma, impede disparo sem saldo e permite recuperar munição em pickups do mapa.

## Como funciona

Cada jogador possui um `WeaponAmmoInventory`. No spawn, apenas a arma selecionada recebe sua munição inicial. Ao disparar, o saldo é consumido; ao coletar um pickup, o Server acrescenta munição até o máximo definido pela arma. O Client mostra o valor da arma equipada na HUD.

O Client reduz o contador local para resposta imediata, mas o Server envia a atualização confirmada ou um snapshot completo quando necessário.

## Onde fica no projeto

- Regras e snapshot: `shared/weapons/weapon_ammo_inventory.gd` e `shared/weapons/weapon_definition.gd`.
- Autoridade: `Server/player/player_server_real.gd` e `Server/server/lobby.gd`.
- HUD e predição visual: `Client/player/local/player_local.gd`.
- Cena visual: `Client/assets/meus_assets/ammo_pickup/ammo_pickup.tscn`.

## Rede e autoridade

As RPCs de atualização e snapshot de inventário estão no lobby do Server. O valor recebido do Server substitui a predição local quando houver divergência.
