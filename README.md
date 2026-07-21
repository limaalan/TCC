# TCC - Jump'n'Shoot

Repositorio referente aos recursos do jogo proposto como trabalho de TCC

## Tarefas
As tarefas estao listadas no github projects, com a mesma divisao utilizada no cronograma da apresentacao.
Serao criados cards para as tarefas que surgirem, cada um com uma issue.

O padrao de commit sera: `1. Breve descricao da tarefa`

ex: `2. Criacao do modelo de personagem`

## Coleta de metricas de rede
O contrato oficial de observabilidade do servidor passa a ser:

- `--port=7777`
- `--record-metrics`
- `--stream-metrics`
- `--metrics-interval=1.0`
- `--metrics-output-dir=metrics-logs`
- `--metrics-stream-host=127.0.0.1`
- `--metrics-stream-port=8765`

Sem flags de observabilidade o servidor sobe normal, sem CSV e sem stream UDP. Quando `--record-metrics` estiver ativo, os arquivos CSV sao gravados por padrao em `metrics-logs/` na raiz do repositorio. O diretorio tambem pode ser sobrescrito com `--metrics-output-dir=<caminho>` ou `TCC_METRICS_OUTPUT_DIR`.

As flags antigas `--network-metrics` e `--metrics` permanecem apenas por compatibilidade temporaria. A documentacao completa de build, deploy e scripts de inicializacao esta em `implementation_plan/15_runtime_observabilidade_e_comandos_servidor.md`.
