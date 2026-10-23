# Observabilidade, métricas e dashboard

## O que faz

Coleta dados técnicos de uma partida em rede para avaliar o comportamento do servidor e apoiar testes. A feature pode gravar CSV e transmitir amostras por UDP para uma dashboard web.

## Como funciona

```text
ServerMetricsCollector
  -> NetworkMetricsLogger
       -> CSV em metrics-logs/       (modo record)
       -> UDP em 127.0.0.1:8765      (modo stream)
            -> metrics_dashboard -> navegador
```

O coletor do Server reúne valores como processo, lobbies, jogadores e dados de rede. `NetworkMetricsLogger` interpreta os argumentos de execução, serializa o payload e escolhe os destinos habilitados. A dashboard recebe os datagramas, mantém o histórico em memória e os expõe por HTTP/WebSocket.

## Onde fica no projeto

- Coletor: `Server/server/server_metrics_collector.gd`.
- Contrato, argumentos e CSV/UDP: `shared/metrics/network_metrics_logger.gd`.
- Dashboard: `metrics_dashboard/main.py`, `metrics_dashboard/udp_receiver.py` e `metrics_dashboard/static/`.
- Scripts locais: `scripts/start_server.ps1` e `scripts/start_with_metrics.ps1`.

## Configuração e extensão

Os argumentos incluem `--record-metrics`, `--stream-metrics`, `--metrics-interval=<segundos>`, `--metrics-output-dir=<caminho>`, `--metrics-stream-host=<host>` e `--metrics-stream-port=<porta>`. Para evitar ambiguidade em builds exportadas, prefira informar explicitamente o diretório de CSV.

Um campo novo é uma alteração de contrato: precisa nascer no coletor, atravessar a serialização compartilhada e ser interpretado pela dashboard/CSV conforme necessário. O procedimento está em [usar e estender métricas](../how_to/use-and-extend-metrics.md).

## Limitações

UDP privilegia baixo acoplamento e pode perder amostras. A dashboard é uma ferramenta de observação, não uma fonte de verdade para o estado da partida nem um substituto de armazenamento histórico permanente.
