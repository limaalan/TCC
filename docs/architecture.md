# Arquitetura e pontos de alteração

O jogo usa dois projetos Godot 4.5.1 independentes e comunicação UDP/ENet. Os caminhos abaixo partem da raiz do repositório.

| Parte | Responsabilidade |
| --- | --- |
| `initial_project/Client/` | Entrada, movimentação local, interface, áudio e apresentação dos estados recebidos. |
| `initial_project/Server/` | Conexões, salas, times, nascimentos, combate, recursos, regras e resultado. |
| `initial_project/shared/` | Contratos de rede, configurações, catálogo de armas e tipos usados pelos dois projetos. |

Os projetos iniciam em `game/main_game.tscn`. No cliente, `game/local_game_scene_manager.gd` abre o menu principal; no servidor, a inicialização está no autoload `server/server.gd`. Ambos possuem um autoload chamado `Server` e uma classe `Lobby`, com implementações próprias.

## Fluxo e rede

1. O cliente informa nome e modo de jogo e solicita uma partida.
2. O servidor encontra ou cria uma sala compatível com a predefinição solicitada.
3. Ao completar a lotação, prepara os clientes, o mapa e a seleção de armas.
4. Durante a partida, distribui estados e eventos; ao terminar, envia o resultado.

O cliente envia posição, orientação e animação por `unreliable_ordered`. O servidor valida o formato e replica esses estados; a movimentação não possui validação autoritativa equivalente a uma simulação de entradas no servidor. Os clientes suavizam os jogadores remotos com um buffer de aproximadamente 100 ms.

Criação de jogadores, munição, coletáveis e encerramento usam eventos confiáveis. O disparo produz feedback local imediato, mas dano e consumo confirmado de munição são decididos pelo servidor. Raycasts usam representações históricas dos jogadores para compensação de latência. Não há reconciliação completa do personagem por repetição de entradas.

## Onde alterar

Os caminhos desta tabela são relativos a `initial_project/`.

| Sistema | Arquivos ou diretórios |
| --- | --- |
| Conexões e formação de salas | `Server/server/server.gd`; `Client/server/server.gd` |
| Partida, RPCs e replicação | `Server/server/lobby.gd`; `Client/server/lobby.gd` |
| Movimentação e entrada | `Client/player/local/player_local.gd`; InputMap de `Client/project.godot` |
| Regras TDM/KOTH | `Server/game_modes/`; `shared/match_preset_registry.gd` |
| Armas, munição e inventário | `shared/weapons/`; combate em `Server/server/lobby.gd` |
| Melhorias temporárias | `shared/powerups/`; `Server/player/powerups/`; `Client/ui/hud/` |
| Mapa Highrise | `Client/maps/highrise/`; `Server/maps/highrise/`; registros `maps/map_registry.gd` de cada projeto |
| Menus, HUD e resultado | `Client/ui/`; `Client/game/local_game_scene_manager.gd` |
| Áudio | `Client/game/audio/` |
| Métricas | `Server/server/server_metrics_collector.gd`; `shared/metrics/` |

## Contratos compartilhados

Edite `initial_project/shared/`. As pastas `Client/shared` e `Server/shared` são junções locais criadas por `initial_project/setup_shared_links.ps1`; o builder materializa o conteúdo em cada exportação.

Payloads e nomes de RPC precisam permanecer compatíveis nos dois projetos. As chaves estão em `shared/net/net_keys.gd` e as estruturas em `shared/net/net_payloads.gd`. Grupos e métodos de integração do cliente estão em `Client/game/client_names.gd`.

Veja [configuração](configuration.md), [build e execução](build.md) e [manutenção](maintenance.md).
