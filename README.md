# TCC - Jump'n'Shoot

Repositorio referente aos recursos do jogo proposto como trabalho de TCC

## Tarefas
As tarefas estao listadas no github projects, com a mesma divisao utilizada no cronograma da apresentacao.
Serao criados cards para as tarefas que surgirem, cada um com uma issue.

O padrao de commit sera: `1. Breve descricao da tarefa`

ex: `2. Criacao do modelo de personagem`

## Coleta de metricas de rede
Servidor e cliente aceitam os argumentos abaixo para registrar metricas em CSV durante testes manuais:

- `--network-metrics`
- `--network-metrics-interval-ms=1000`
- `--network-metrics-label=teste_2p`

Os arquivos sao gravados em `user://network_metrics/`, um CSV por processo, com o cabecalho pedido na issue `#102`.
