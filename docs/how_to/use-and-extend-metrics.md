# Usar e estender métricas

## Executar a coleta

Para gravar CSV, inicie o Server com um diretório explícito:

```bash
./jumpnshoot-server.x86_64 --headless -- --port=7777 --record-metrics --metrics-output-dir=/caminho/metrics-logs
```

Para transmitir à dashboard local:

```bash
./jumpnshoot-server.x86_64 --headless -- --port=7777 --stream-metrics --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765
```

Para executar a dashboard, use o Python do ambiente virtual onde suas dependências foram instaladas:

```bash
<ambiente-virtual>/bin/python <caminho-da-dashboard>/main.py --udp-host=127.0.0.1 --udp-port=8765 --http-host=0.0.0.0 --http-port=8000
```

Se ocorrer `address already in use`, identifique a porta e o processo antes de iniciar outra instância. Para o receptor de métricas UDP, consulte `ss -lunp` (porta padrão 8765); para o serviço HTTP/WebSocket TCP, use `ss -ltnp` (porta padrão 8000).

## Adicionar uma métrica

1. Defina o nome, unidade, origem e frequência da nova medida no documento da feature de [observabilidade](../features/observability-metrics-and-dashboard.md).
2. Acrescente o valor no payload produzido por `Server/server/server_metrics_collector.gd` ou no emissor adequado.
3. Atualize `shared/metrics/network_metrics_logger.gd` se a serialização ou o CSV precisar reconhecer o campo.
4. Atualize `metrics_dashboard/udp_receiver.py`, armazenamento e interface apenas se a métrica for exibida na dashboard.
5. Rode com `--record-metrics` e `--stream-metrics`; confirme o campo no CSV, datagrama recebido e tela.

Não renomeie um campo existente silenciosamente: CSVs e dashboard podem depender dele.
