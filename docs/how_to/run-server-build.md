# Executar uma build do Server

## Objetivo

Iniciar uma build exportada do Server em modo headless e confirmar que a porta está livre.

## Iniciar

No Linux, torne o executável exportado executável e inicie-o com a porta desejada:

```bash
chmod +x ./jumpnshoot-server.x86_64
./jumpnshoot-server.x86_64 --headless -- --port=7777
```

Para registrar métricas em CSV durante a execução:

```bash
./jumpnshoot-server.x86_64 --headless -- --port=7777 --record-metrics --metrics-output-dir=./metrics-logs
```

## Diagnóstico

Se a porta estiver ocupada, descubra o processo antes de encerrá-lo:

```bash
ss -ltnp | grep ':7777'
ps -fp <pid>
```

Pare apenas o PID confirmado:

```bash
kill <pid>
```

Para habilitar streaming de métricas, acrescente `--stream-metrics --metrics-stream-host=127.0.0.1 --metrics-stream-port=8765`. Veja [métricas](use-and-extend-metrics.md).
