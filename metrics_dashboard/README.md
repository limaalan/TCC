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

## Executar servidor Godot com CSV + streaming

Compatibilidade com a branch `feature/metrics`:

```bash
godot --path initial_project/Server -- --network-metrics --stream-metrics --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765
```

Flags novas equivalentes:

```bash
godot --path initial_project/Server -- --metrics --record-metrics --stream-metrics --metrics-interval=1.0 --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765
```

## Notas

- O CSV continua sendo gravado em `user://network_metrics/`.
- Se o dashboard Python nao estiver ativo, o servidor continua rodando normalmente.
- O dashboard mantem apenas uma janela curta em memoria; o historico completo continua no CSV.
