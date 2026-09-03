# Visão geral da arquitetura

O repositório contém dois projetos Godot 4.5 independentes que participam da mesma partida.

```text
Client ── solicita ações e apresenta o jogo ──┐
                                               ├── Server ── simula e valida a partida
shared ── contratos, configurações e regras ──┘
```

## Componentes

| Componente | Responsabilidade | Entrada principal |
| --- | --- | --- |
| `initial_project/Client` | Interface, renderização, entrada local, predição visual e apresentação dos estados recebidos. | `game/main_game.tscn` |
| `initial_project/Server` | Lobbies, mapa autoritativo, jogadores, combate, pickups, modos e estado de rede. | autoload `server/server.tscn` |
| `initial_project/shared` | Tipos, contratos de rede, catálogo de armas, presets e regras reutilizadas pelos dois projetos. | ligado aos dois projetos por junctions |

O servidor escuta a porta `7777` por padrão. O Client tenta se conectar usando as configurações persistidas do jogador; o endereço padrão pode ser definido em `Client/default_settings.cfg`.

## Fluxo de uma partida

1. O Client conecta e escolhe um preset de partida.
2. O Server cria ou encontra um lobby compatível com esse preset.
3. O lobby carrega o mapa autoritativo, cria jogadores e envia metadados ao Client.
4. O Client carrega a apresentação visual correspondente e envia entradas/solicitações.
5. O Server valida o estado e replica o resultado: posições, combate, munição, pickups, placar e encerramento.

## Configuração de partida

`shared/match_preset_registry.gd` define os presets atuais de Highrise para TDM e KOTH. Cada preset cria um `MatchConfig` com modo, mapa, limite de tempo, pontuação para vitória e quantidade máxima de jogadores. O Server pode hospedar mais de um lobby, mas cada preset atualmente limita a partida a dois jogadores.

## Limites atuais

- A seleção de modos expõe os presets de Highrise; o mapa Prototype existe no projeto, mas não é oferecido no menu.
- O Server é a autoridade da partida. O Client não é uma fonte confiável para dano, munição, pickups ou resultado.
- Assets e cenas visuais ainda estão em processo de consolidação para uma build completamente reproduzível.
