# Configuração

Os caminhos `Client/`, `Server/` e `shared/` abaixo partem de `initial_project/`.

## Cliente

`Client/game/settings_manager.gd` administra `user://settings.cfg`. Na primeira execução, copia os defaults de `Client/default_settings.cfg`; alterar o default não substitui um perfil já salvo.

| Chave | Padrão | Alteração |
| --- | --- | --- |
| `network/server_address` | Vazio | Configurações do cliente; obrigatório informar um endereço. |
| `network/server_port` | `7777` | Configurações do cliente. |
| `profile/player_name` | Vazio | Fluxo de identificação, até 16 caracteres. |
| `audio/master_volume`, `audio/music_volume`, `audio/sfx_volume` | `1.0` | Configurações, entre 0 e 1. |
| `display/fullscreen` | `false` | Configurações do cliente. |

Preferências salvas pela interface não exigem nova build. Distribuir outros defaults exige exportar novamente. Os títulos Godot `Jump'n'Shoot Client` e `Jump'n'Shoot Server` determinam os perfis separados; mudar `config/name` pode mudar o diretório `user://`.

## Servidor e partidas

`shared/network_config.gd` procura `--port=<inteiro>` nos argumentos depois de `--`, depois `network/server_port` em ProjectSettings e, por fim, usa `7777`. Uma porta numérica fora de 1–65535 cai em `7777`; a porta do jogo não é lida de uma variável de ambiente.

```bash
./jumpnshoot-server.x86_64 --headless -- --port=17777
```

| Parâmetro | Local | Configuração padrão |
| --- | --- | --- |
| Conexões e salas | `Server/server/server.gd` | `MAX_CLIENTS = 64`, `MAX_LOBBIES = 4`. |
| Modos aceitos | `shared/match_preset_registry.gd` | `tdm_highrise`, `koth_highrise`. |
| Jogadores por partida | Mesmo registro | 2 em ambos os modos; sobrescreve o fallback de 4 de `shared/match_config.gd`. |
| Tempo e pontuação | Mesmo registro | 300 segundos e 20 pontos. |
| Mapa | `Client/maps/map_registry.gd` e `Server/maps/map_registry.gd` | Highrise. |
| Armas e munição | `shared/weapons/` | Catálogo e inventário compartilhados. |
| Controles | `Client/project.godot` e `Client/player/local/player_local.gd` | InputMap e movimentação local. |

Alterar código, recursos ou ProjectSettings distribuídos exige nova build. Alterações compartilhadas devem ser verificadas nos dois projetos. Os limites configurados não são capacidade de desempenho medida. Salas aceitam entrada em `IDLE` e fecham ao completar a lotação; o mapa padrão tem quatro nascimentos por time.

Os ajustes experimentais de quantidade de participantes e munição pertencem ao [piloto de carga](how_to/run-load-pilot.md), não aos padrões normais acima.

## Ferramentas e hospedagem

| Parâmetro | Padrão / aplicação |
| --- | --- |
| `BUILD_VERSION` | `local`; seleciona a versão da build e imagem no Compose. |
| `SERVER_PORT` | `7777`; porta UDP publicada, com porta interna 7777. |
| `SERVER_BIND_ADDRESS` | `127.0.0.1` no Compose local; `0.0.0.0` no de produção. |
| `SERVER_IMAGE` | Imagem de produção por digest; não faz nova exportação. |
| `MATCH_PRESET` | `tdm_highrise`; escolha do teste no Compose. |
| Builder `--targets` | Quatro alvos por padrão; `--no-package` dispensa os arquivos compactados. |
| `VPS_DEPLOY_DIR`, `VPS_GAME_PORT`, `VPS_PORT` | `/opt/jumpnshoot`, `7777`, `22` no deploy. |

Recrie o serviço para aplicar mudanças de publicação de porta/interface. `SERVER_PORT` pertence ao Compose, não à leitura de porta do código Godot. As variáveis de métricas do shell não são encaminhadas automaticamente pelos Compose atuais; veja [métricas](metrics.md).

Veja [build e execução](build.md) e [publicação](publishing.md).
