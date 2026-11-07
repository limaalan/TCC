# Piloto manual com bots — uma sala

Ferramenta opcional, fora do pipeline. Usa os projetos reais, o mapa Highrise existente e peers ENet separados. Sem `--human`, todos os participantes são bots; com essa opção, uma das vagas é humana. **`--players` sempre é o total da sala.**

O teste executa os projetos-fonte com Python 3 e Godot 4.5.1. Importe os projetos no Godot e crie as junções `Client/shared` e `Server/shared` conforme o [guia de build](../build.md).

## Executar localmente

### Partida com 31 bots e um jogador

No Windows, abra `scripts/teste-31-bots-humano.cmd` e pressione uma tecla para iniciar o servidor local, 31 bots e um cliente gráfico. Na janela do jogo, escolha uma arma para entrar na partida. A coleta dura cinco minutos após 30 segundos de aquecimento.

O comando equivalente, executado na raiz do repositório, é:

```powershell
python scripts/run_loadtest.py --players 32 --human --preset koth_highrise --ammo 10000 --duration 300 --warmup 30
```

Sem `--logs`, os resultados ficam em uma pasta datada com sufixo `-32p` dentro de `build/loadtest/`. A pasta contém os CSVs, os logs e o `summary.json`.

### Outras quantidades

```powershell
python scripts/run_loadtest.py --godot "C:\Tools\Godot\Godot_v4.5.1-stable_win64_console.exe" --players 8 --duration 300 --warmup 30 --logs build/loadtest/rodada-8-01
```

O launcher inicia um Server local na porta UDP 17777 e oito Clients headless. Espera todos entrarem na mesma sala, libera uma barreira comum, aquece por 30 segundos e mede cinco minutos. Ao terminar, encerra somente os processos que iniciou. Escolha um diretório novo por rodada; resultados anteriores não são sobrescritos. Sem `--logs`, o nome recebe data/hora.

Os processos são iniciados com `--max-fps 60`; esse teto faz parte do cenário. Os CSVs do Server também incluem preparação/aquecimento; no teste local, a janela resumida vai de `barrier_unix_ms + warmup_sec * 1000` a `end_unix_ms`, conforme `summary.json`.

Para reservar uma vaga humana, acrescente `--human`: em `--players 8 --human`, são sete bots e um Client gráfico controlado por você. Nenhuma ação automática é aplicada ao humano. Esta opção requer presença para jogar e não deve ser usada em uma execução sem operador.

| Parâmetro | Padrão / significado |
| --- | --- |
| `--players` | 2; permite 2–64; acima de oito, reutiliza os nascimentos existentes somente no ensaio |
| `--human` | Ausente; reserva uma das vagas para um humano gráfico |
| `--duration` / `--warmup` | 300 / 30 segundos; duração medida começa depois da preparação e do aquecimento |
| `--ammo` | 10.000 munições iniciais por arma/nascimento no modo experimental; capacidade comporta o valor configurado |
| `--preset` | `koth_highrise`; também aceita `tdm_highrise`, sem mudar de mapa |
| `--seed` | 20261029; cada bot recebe um valor distinto a partir dele |
| `--port` | 17777; evita usar a porta normal 7777 sem necessidade |
| `--logs` | Pasta nova para toda a evidência da rodada |
| `--external-server --host ENDEREÇO` | Conecta a um Server previamente preparado; não inicia, modifica ou publica servidor remoto |

## Configuração experimental e ações

O launcher passa `--loadtest-players=N`, `--loadtest-duration=900`, `--loadtest-score=10000` e `--loadtest-ammo=10000` aos projetos. Para execuções mais longas, amplia a duração da partida para comportar a coleta. Sem os argumentos do ensaio, as partidas padrão usam dois jogadores, 300 segundos e 20 pontos. A pontuação alta evita o encerramento precoce. Acima de oito participantes, o teste reutiliza os pontos de nascimento de cada equipe no Highrise, com sobreposição inicial. O limite configurável do ensaio é 64 participantes.

Bots selecionam arma na fase autorizada, movem-se com a física normal, miram, disparam respeitando o caminho da arma e tentam lançar granadas. Também selecionam arma após morrer. O driver é externo ao startup normal do jogo e só contorna o foco de janela nos seus próprios processos headless.

No perfil `smg-single-pulse-2s-v1`, cada bot dispara um pulso curto de SMG a cada dois segundos, com início definido pela seed. A munição configurada com `--ammo` reduz a dependência de coletáveis e se aplica às cópias das definições de arma em memória durante o ensaio. Cada disparo mantém o consumo normal de munição.

O ensaio verifica movimento e disparos reais em janelas de tempo vivo, snapshots recentes, ocupação e duração. Se o bot ficar sem atividade sustentada, a rodada falha; conexão isolada não basta. Falhas conservam logs e CSVs para diagnóstico.

## Ler os resultados

- `server-metrics/server_network_metrics_*.csv`: amostras de jogadores/lobbies, RTT, perda estimada, tráfego e custo parcial instrumentado dos lobbies.
- `server-metrics/server_client_fps_metrics_*.csv`: FPS informados pelos Clients e identificados por `peer_id`.
- `bot-*.csv` e, se usado, `human-*.csv`: atividade observada, disparos, tentativas, mortes/retornos e janelas de validação. Tentativa de granada não é contagem de explosões confirmadas.
- `summary.json`: opções, seed, identificação da árvore de trabalho, peers/roster, comandos, resumo das amostras e estado da rodada.
- `*.log` / `*.engine.log`: diagnóstico por processo. `server-active.log`, quando produzido, separa a execução medida do encerramento.

`completed` indica que o ensaio concluiu a coleta e as verificações de atividade. O campo `playability: not_assessed_automated_run` indica que a jogabilidade ficou fora da avaliação automatizada. O tempo registrado para a sala cobre apenas o trecho instrumentado do ciclo de atualização.

Para testar um servidor remoto, habilite nele a coleta CSV e use `--external-server --host ENDEREÇO` em outra máquina, com o mesmo preset e número de participantes. Recolha os CSVs do servidor separadamente.
