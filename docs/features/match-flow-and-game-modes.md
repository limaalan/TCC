# Fluxo de partida e modos de jogo

## O que faz

Controla a preparação, execução e encerramento das partidas. Os modos disponíveis são Team Deathmatch (TDM) e King of the Hill (KOTH), ambos configurados pelos presets de Highrise.

## Como funciona

O Server cria o lobby com um `MatchConfig`, carrega o mapa e aguarda os Clients necessários. Durante a partida, o modo ativo acompanha placar e tempo restante. A partida termina ao alcançar a pontuação alvo ou o limite de tempo; o resultado é replicado para a tela final do Client.

- **TDM:** eliminações concedem pontuação ao time responsável.
- **KOTH:** o controle da zona de colina acumula pontuação para o time controlador.

## Onde fica no projeto

- Presets: `shared/match_preset_registry.gd` e `shared/match_config.gd`.
- Modos: `Server/game_modes/team_deathmatch_mode.gd` e `Server/game_modes/king_of_the_hill_mode.gd`.
- Orquestração: `Server/server/lobby.gd`.
- Apresentação: `Client/server/lobby.gd`, `Client/ui/` e cenas de HUD/resultados.

## Configuração e extensão

Para criar um preset, adicione-o ao registro compartilhado com um modo e um mapa existentes. Um modo novo exige implementação no Server e apresentação/metadata correspondente no Client. O mapa Prototype continua registrado para desenvolvimento, mas não deve ser adicionado à seleção principal sem decisão explícita.
