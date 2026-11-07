# Métricas e CSV

O cliente informa FPS ao servidor. O servidor coleta indicadores de rede/processamento e grava os CSVs quando habilitado. Sem flags ou variáveis habilitadoras, CSV e stream ficam desligados.

```bash
./jumpnshoot-server.x86_64 --headless -- --port=7777 \
  --record-metrics --metrics-interval=1.0 \
  --metrics-output-dir=/caminho/gravavel/metrics-logs
```

Prefira um diretório absoluto gravável em builds exportadas. Caminhos relativos são resolvidos pelo logger a partir de `res://../../`, não necessariamente da pasta atual do terminal.

| Opção do jogo | Variável de ambiente | Padrão |
| --- | --- | --- |
| `--record-metrics` | `TCC_RECORD_METRICS` | Desligado; grava CSV. |
| `--stream-metrics` | `TCC_STREAM_METRICS` | Desligado; transmite UDP. |
| `--metrics-interval=<segundos>` | `TCC_NETWORK_METRICS_INTERVAL_MS` | 1 segundo; variável em milissegundos. |
| `--metrics-output-dir=<caminho>` | `TCC_METRICS_OUTPUT_DIR` | Fallback `res://../../metrics-logs`. |
| `--metrics-stream-host=<host>` | `TCC_METRICS_STREAM_HOST` | `127.0.0.1`. |
| `--metrics-stream-port=<porta>` | `TCC_METRICS_STREAM_PORT` | `8765`. |

Variáveis habilitadoras aceitam `1`, `true` ou `yes`. CLI precede ambiente para host, porta e diretório. O primeiro argumento de intervalo encontrado prevalece. Existem aliases legados `--network-metrics`/`--metrics` e `TCC_NETWORK_METRICS`; prefira as opções modernas sem misturá-las.

## Interpretar os registros

- `server_network_metrics_*.csv`: quantidade de participantes/salas, RTT, perda estimada e tempo parcial do ciclo de atualização das salas.
- `server_client_fps_metrics_*.csv`: FPS informados pelos clientes, identificados por `peer_id`.
- RTT é ida e volta do transporte. Perda estimada ENet não é uma contagem direta de snapshots perdidos.
- O tempo instrumentado é parcial; não mede sozinho todo o tick de física ou uso de CPU. FPS de um cliente headless não comprova fluidez gráfica.

Os Compose atuais não encaminham essas variáveis nem montam um volume específico de coleta. O runtime usa filesystem somente leitura; configurar persistência no container exige indicar uma área gravável e acessível ao processo.

## Adicionar indicadores

Defina a unidade, a origem e a frequência do indicador. Atualize o coletor em `initial_project/Server/server/server_metrics_collector.gd` e a serialização em `initial_project/shared/metrics/network_metrics_logger.gd`, preservando os nomes dos campos existentes.

O [guia do piloto](how_to/run-load-pilot.md) descreve a coleta no ensaio de uma sala e a identificação dos seus resultados.
