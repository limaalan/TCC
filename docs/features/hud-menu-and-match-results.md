# HUD, menus e resultado de partida

## O que faz

Apresenta ao jogador a entrada na partida, status durante o jogo e o resultado final. A interface segue o estilo visual do menu principal e usa português como idioma corrente.

## Como funciona

O fluxo começa no menu principal, passa pela seleção/conexão de partida e chega à HUD local. Durante a partida, a HUD mostra vida, indicador de time, arma e munição, granadas, buffs ativos e informações do modo. Ao fim, a tela de resultado recebe os dados autoritativos do Server e oferece a ação **Voltar ao menu**.

## Onde fica no projeto

- Fluxo de cenas: `Client/game/local_game_scene_manager.gd`.
- Jogador/HUD: `Client/player/local/player_local.tscn` e `Client/player/local/player_local.gd`.
- Menus e telas: `Client/ui/main_menu/`, `Client/ui/hud/` e `Client/ui/`.
- Dados de partida: `Client/server/lobby.gd` e `Server/server/lobby.gd`.
