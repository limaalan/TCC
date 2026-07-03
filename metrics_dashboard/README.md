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

## Notas

- A dashboard Python e um processo separado; ela nao e habilitada por uma flag interna da Godot.
- O CSV continua sendo gravado em `user://network_metrics/`.
- Se o dashboard Python nao estiver ativo, o servidor continua rodando normalmente.
- O dashboard mantem apenas uma janela curta em memoria; o historico completo continua no CSV.
- As flags `--network-metrics` e `--metrics` permanecem apenas como compatibilidade temporaria.
