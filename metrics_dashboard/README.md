# Metrics Dashboard

Dashboard local para acompanhar, em tempo real, as metricas de rede produzidas pelo servidor Godot.

## Dependencias

```bash
pip install -r metrics_dashboard/requirements.txt
```

## Executar dashboard

```bash
python metrics_dashboard/main.py --udp-host=127.0.0.1 --udp-port=8765 --http-host=127.0.0.1 --http-port=8000
```

Depois abra [http://127.0.0.1:8000](http://127.0.0.1:8000).

## Executar servidor Godot com streaming

Contrato oficial:

```bash
godot --path initial_project/Server --headless res://game/main_game.tscn -- --port=7777 --stream-metrics --metrics-interval=1.0 --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765
```

Se quiser manter o CSV ao mesmo tempo:

```bash
godot --path initial_project/Server --headless res://game/main_game.tscn -- --port=7777 --record-metrics --stream-metrics --metrics-interval=1.0 --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765
```

No Windows, os launchers locais equivalentes sao:

```powershell
.\start_metrics_console.ps1
.\start_metrics_console.ps1 -RecordMetrics
.\start_metrics_server.ps1 -StartDashboard
.\start_metrics_server.ps1 -StartDashboard -RecordMetrics
```

O cliente nao envia UDP para a dashboard e nao grava CSV proprio. Ele apenas reporta FPS para o servidor por RPC, e o servidor continua sendo a fonte oficial do stream UDP.

## Payload UDP esperado

O payload continua compativel com a dashboard atual e com a lista `peers`, mas agora inclui os campos extras abaixo:

```json
{
  "schema_version": 2,
  "source": "godot_server",
  "role": "server",
  "timestamp_ms": 1783340100000,
  "server_pid": 12345,
  "players_count": 2,
  "lobbies_count": 1,
  "server_physics_process_ms": 1.4,
  "server_physics_process_ms_sum": 1.8,
  "sent_kib_per_sec": 12.4,
  "received_kib_per_sec": 4.8,
  "sent_packets_per_sec": 64.0,
  "received_packets_per_sec": 31.0,
  "peers": [
    {
      "peer_id": 2,
      "rtt_ms": 32.0,
      "last_rtt_ms": 31.0,
      "rtt_variance_ms": 3.5,
      "packet_loss_percent": 0.0,
      "app_ping_ms": 34.0,
      "client_fps": 59.8
    }
  ],
  "client_fps": [
    { "peer_id": 2, "fps": 59.8 }
  ]
}
```

## CSVs gerados

Quando `--record-metrics` estiver ativo, o servidor passa a gerar dois CSVs em `user://network_metrics/`:

- `server_network_metrics_<timestamp>[_label].csv`: uma linha agregada por amostra.
- `server_client_fps_metrics_<timestamp>[_label].csv`: uma linha por peer em cada amostra.

## Notas

- A dashboard Python e um processo separado; ela nao e habilitada por uma flag interna da Godot.
- O CSV continua sendo gravado em `user://network_metrics/`.
- Se o dashboard Python nao estiver ativo, o servidor continua rodando normalmente.
- O dashboard mantem apenas uma janela curta em memoria; o historico completo continua no CSV.
- As flags `--network-metrics` e `--metrics` permanecem apenas como compatibilidade temporaria.
