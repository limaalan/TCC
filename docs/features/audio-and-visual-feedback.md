# Áudio e feedback visual

## O que faz

Converte eventos de gameplay em sinais visuais e sonoros: disparo, acerto, explosão, coleta, buffs, time e estado de combate. Esses elementos não decidem regras da partida; tornam decisões já confirmadas legíveis ao jogador.

## Como funciona

O Client recebe ou inicia a apresentação de eventos e os encaminha ao `AudioManager`, às cenas de arma, à HUD e aos efeitos no personagem. Exemplos atuais são muzzle flash por arma, SFX de granada, emissão de buff, anéis por time e ícones de status de buff.

## Onde fica no projeto

- Áudio: `Client/game/audio/audio_manager.gd` e `Client/game/audio/audio_library.gd`.
- Efeitos de arma: cenas e scripts em `Client/weapons/`.
- Buff visual e HUD: `Client/player/local/player_local.gd`, `Client/ui/hud/` e `Client/player/`.
- Materiais de time: `Client/assets/meus_assets/char/rings.tscn` e materiais associados.
