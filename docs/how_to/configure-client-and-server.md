# Configurar Client e Server do jumpnshoot

As instruções de [build](build-client-and-server.md), [partida local](run-local-match.md) e [métricas](use-and-extend-metrics.md) complementam esta referência de configuração.

Os caminhos `Client/`, `Server/` e `shared/` abaixo partem de `initial_project/`. Os dois projetos possuem arquivos e cenas próprios; não editar as cópias locais de `shared` dentro deles.

## Endereço, perfil e preferências do Client

Fonte: `Client/game/settings_manager.gd`. O perfil usado é `user://settings.cfg`. Na primeira execução, se o perfil não existir, o Client lê `Client/default_settings.cfg` e grava as preferências; alterar esse arquivo depois não substitui um perfil existente.

| Parâmetro no CFG | Padrão inicial | Como alterar | Nova build? |
| --- | --- | --- | --- |
| `network/server_address` | Vazio; endereço precisa ser configurado | Tela de configurações; para novas instalações, `Client/default_settings.cfg` | Não pela tela; sim para distribuir novo default |
| `network/server_port` | `7777` | Tela de configurações; default no arquivo acima | Não pela tela; sim para distribuir novo default |
| `profile/player_name` | Vazio antes de o jogador definir | Fluxo de identificação; limite de 16 caracteres | Não |
| `audio/master_volume`, `music_volume`, `sfx_volume` | `1.0` | Tela de configurações; valores limitados a 0–1 | Não |
| `display/fullscreen` | `false` | Tela de configurações | Não |

O endereço é removido de espaços nas extremidades; endereço vazio ou porta fora de 1–65535 é recusado ao salvar pela tela. Uma porta inválida lida do perfil cai em 7777. A mudança de endpoint salva pela tela emite o sinal que solicita reconexão.

O nome canônico do produto é `jumpnshoot`. Os títulos atuais dos projetos ainda são `Jump'n'Shoot Client` e `Jump'n'Shoot Server`; mudar `config/name` pode mudar a localização de `user://`. Não presumir que uma renomeação de aplicação migre preferências anteriores. O nome do produto é diferente do nome do jogador.

## Porta do processo Server

Fonte: `shared/network_config.gd`. Precedência:

1. Primeiro argumento de usuário `--port=<inteiro>` encontrado, se for um inteiro válido sintaticamente.
2. `network/server_port` do `Server/project.godot` via ProjectSettings.
3. Default `7777`.

Uma porta numérica fora de 1–65535 usa 7777; nesse caso não volta ao valor de ProjectSettings. Um argumento não inteiro não substitui ProjectSettings. Não há variável de ambiente de porta lida por esse código.

Exemplo para uma build Linux, sem recompilar:

```bash
./jumpnshoot-server.x86_64 --headless -- --port=17777
```

`--headless` pertence à Godot; argumentos depois de `--` são lidos pelo jogo. Alterar ProjectSettings exige nova exportação para modificar o default de uma build. Para descobrir quem usa a porta de gameplay em Linux, consultar UDP, por exemplo `ss -lunp`; o serviço HTTP da dashboard usa TCP.

## Lotação e regras de partida

Estes valores são definidos em código/recursos, não por flags de capacidade atualmente disponíveis. Alterá-los exige nova build; validar os dois projetos quando a definição for compartilhada.

| Parâmetro | Valor atual | Origem e observação |
| --- | --- | --- |
| Conexões do processo | `MAX_CLIENTS = 64` | `Server/server/server.gd`; inclui conexões que podem não estar jogando |
| Quantidade de lobbies | `MAX_LOBBIES = 4` | Mesmo arquivo |
| Presets aceitos | `tdm_highrise`, `koth_highrise` | `shared/match_preset_registry.gd`; Client solicita um preset válido |
| Preset default do registro | `koth_highrise` | `DEFAULT_PRESET_ID`; ferramentas de smoke podem escolher TDM explicitamente |
| Jogadores por partida | `max_players = 2` em ambos os presets | O fallback de `shared/match_config.gd` é 4, sobrescrito pelo registro |
| Mapa | `highrise` em ambos os presets | Registros separados `Client/maps/map_registry.gd` e `Server/maps/map_registry.gd` |
| Tempo máximo | `time_limit_sec = 300` | Ambos os presets |
| Meta de pontos | `score_to_win = 20` | Ambos os presets |
| Vidas limitadas | `lives_per_player = 0` | Ambos os presets; não apresenta seleção de vidas na UI |

Capacidade configurada não comprova capacidade de desempenho. O lobby atual aceita entrada em `IDLE` e fecha ao alcançar a lotação. O mapa Server Highrise tem quatro pontos de nascimento por time; aumentar participantes numa sala exige verificar esses pontos e o fluxo, não apenas trocar `max_players`.

Para ajustar balanceamento futuramente, o catálogo de armas fica em `shared/weapons/`, os modos em `Server/game_modes/` e os controles locais em `Client/player/local/player_local.gd` e no InputMap de `Client/project.godot`. Essas são mudanças de jogo; este guia não as aplica.

## Métricas do Server

Fonte: `shared/metrics/network_metrics_logger.gd`. Sem flags ou variáveis habilitadoras, CSV e stream ficam desligados. Para habilitar por ambiente, o código aceita `1`, `true` ou `yes`, sem diferenciar maiúsculas/minúsculas. Flag ou variável habilitada basta; não existe flag negativa que desligue uma variável já habilitada.

| Opção do jogo | Variável de ambiente | Padrão / efeito |
| --- | --- | --- |
| `--record-metrics` | `TCC_RECORD_METRICS` | Desligado; habilita CSV |
| `--stream-metrics` | `TCC_STREAM_METRICS` | Desligado; habilita UDP para o receptor |
| `--metrics-interval=<segundos>` | `TCC_NETWORK_METRICS_INTERVAL_MS` (milissegundos) | 1 segundo; mínimo interno de 1 ms |
| `--metrics-output-dir=<caminho>` | `TCC_METRICS_OUTPUT_DIR` | `res://../../metrics-logs` no fallback do código |
| `--metrics-stream-host=<host>` | `TCC_METRICS_STREAM_HOST` | `127.0.0.1` |
| `--metrics-stream-port=<porta>` | `TCC_METRICS_STREAM_PORT` | `8765`; porta inválida cai nesse default |

Para host, porta e diretório, a opção CLI correspondente precede a variável de ambiente, seguida do default. Para intervalo, vence a primeira opção de intervalo encontrada na linha de comando, incluindo a opção legada; sem opção, usa a variável em milissegundos ou o default. Não misturar alternativas modernas e legadas na mesma execução.

Compatibilidade existente: `--network-metrics`, `--metrics` e `TCC_NETWORK_METRICS` habilitam gravação. Também são lidos `--network-metrics-interval-ms`, `--network-metrics-output-dir` / `TCC_NETWORK_METRICS_OUTPUT_DIR` e `--network-metrics-label` / `TCC_NETWORK_METRICS_LABEL`. O label acrescenta um sufixo aos nomes de saída, após sanitização. Para diretório, primeiro é resolvido o par moderno CLI/ambiente; se estiver vazio, usa o par legado e o fallback.

Os caminhos relativos de saída são resolvidos pelo logger a partir de `res://../../`, não necessariamente do diretório de trabalho do shell. Em executável exportado, prefira um caminho absoluto gravável. Se CSV falhar por diretório/permissão, não presumir que exista um arquivo válido. O stream UDP é independente da gravação.

Exemplo de coleta futura em Linux, sem recompilar:

```bash
./jumpnshoot-server.x86_64 --headless -- --port=7777 --record-metrics --metrics-output-dir=/caminho/gravavel/metrics-logs --metrics-interval=1.0
```

O Client reporta FPS ao Server; não configurar cada Client como emissor UDP da dashboard. CPU/RSS acrescentados pela dashboard são medidas do processo acessível no ambiente do monitor e não entram automaticamente no CSV da Godot.

## Docker, build e deploy

Para o ensaio pontual, consulte o [piloto de uma sala](run-load-pilot.md). O launcher oferece `--players`, `--human`, `--ammo`, duração e saída de CSVs; parâmetros `--loadtest-*` são ajustes experimentais opt-in, não os defaults de distribuição.

Estes parâmetros pertencem às ferramentas, não são opções lidas pelo jogo.

| Parâmetro | Padrão / onde fica | Efeito e aplicação |
| --- | --- | --- |
| `BUILD_VERSION` | `local` no `compose.yaml` | Seleciona versão/diretório da release e tag local; gerar imagem com os artefatos da versão escolhida |
| `SERVER_PORT` | `7777` nos dois Compose | Porta UDP publicada no host; porta interna do container continua 7777. Recriar serviço para aplicar |
| `SERVER_BIND_ADDRESS` | `127.0.0.1` local; `0.0.0.0` em `compose.prod.yaml` | Interface de publicação do host. Recriar serviço para aplicar |
| `SERVER_IMAGE` | Obrigatório no Compose de produção | Imagem identificada por digest `sha256`; o deploy usa a imagem pronta, sem exportar novamente |
| `MATCH_PRESET` | `tdm_highrise` no serviço `test` | Escolha do smoke, não configuração global das partidas do Server |
| `--targets` do builder | Quatro alvos por default | `client-windows`, `client-linux`, `server-windows`, `server-linux` em `scripts/build_release.py` |
| `--version`, `--output` do builder | `local`, `build/releases` quando chamado diretamente | Saída `<output>/<version>`; uma release existente não é sobrescrita. Compose passa seus próprios caminhos |
| `--no-package` do builder | Ausente | Mantém exportações/manifestos/checksums e dispensa ZIP/tar.gz; não equivale a pacote final de release |
| `VPS_DEPLOY_DIR`, `VPS_GAME_PORT`, `VPS_PORT` | `/opt/jumpnshoot`, `7777`, `22` no `scripts/deploy-vps.sh` | Diretório remoto, porta de gameplay publicada e porta SSH; entram na etapa de deploy |

`scripts/deploy_server.py` também expõe `--directory`, `--project`, `--image`, `--port`, `--bind-address` e `--rollback`; consulte o script e o [guia de CI/CD](ci-cd.md) antes de operar. Não incluir credenciais em guias ou no repositório.

As flags de métricas acima valem para o processo Godot; os serviços Compose atuais não expõem opções próprias para habilitar CSV/stream nem configuram volume de coleta. Não presumir que definir `TCC_*` no shell do host as encaminhe ao container. Essa integração exige configuração e validação em outra etapa; o runtime atual é somente leitura, com áreas temporárias específicas.

Para construir, iniciar e verificar artefatos, siga o [guia único de build](build-client-and-server.md). Este documento registra configuração; não atesta execução desses procedimentos nesta rodada.
