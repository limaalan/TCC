# Piloto manual com bots — uma sala

Ferramenta opcional, fora do pipeline. Usa os projetos reais, o mapa Highrise existente e peers ENet separados. Sem `--human`, todos os participantes são bots; com essa opção, uma das vagas é humana. **`--players` sempre é o total da sala.**

Requer Python 3, Godot 4.5.1 e os projetos preparados/importados, incluindo as junções `Client/shared` e `Server/shared`. Veja a [preparação do projeto](../build.md). Não use executáveis antigos de release para testar estes novos ajustes: o comando abaixo executa os fontes locais pelo Godot.

## Executar localmente

### Demonstração pronta: 31 bots + você

No computador já preparado, dê duplo clique em **`scripts/teste-31-bots-humano.cmd`**. O arquivo aguarda uma tecla antes de iniciar: prepare a gravação nesse intervalo. Ele abre um Server local, 31 Clients headless e somente uma janela gráfica, controlada por você.

Na janela do jogo, escolha uma arma para nascer e mantenha o foco nela. Depois que os 32 participantes estiverem prontos, haverá 30 segundos de aquecimento e cinco minutos de coleta. Jogue normalmente; após morrer, a seleção de arma segue o fluxo normal do Client. O launcher encerra os processos da rodada ao final. Não é necessário abrir outro servidor ou outro Client manualmente.

Grave a perspectiva do jogador com HUD legível, incluindo movimento/salto, disparos/dano, granada, objetivo e morte/retorno. Pare e salve a gravação após o encerramento. Anote o nome da pasta de resultados mostrada no terminal para associá-la ao vídeo.

O comando equivalente, executado na raiz do repositório, é:

```powershell
python scripts/run_loadtest.py --players 32 --human --preset koth_highrise --ammo 10000 --duration 300 --warmup 30
```

Sem `--logs`, cada execução cria uma pasta nova com data/hora e sufixo `-32p` dentro de `build/loadtest/`. Preserve essa pasta inteira com o vídeo: contém os CSVs do Server, `human-1.csv`, CSVs dos bots, logs e `summary.json`. O vídeo é gravado manualmente; o launcher não captura a tela.

O cenário usa munição inicial e pontuação altas, o Highrise existente e a porta local UDP 17777. São **32 participantes totais**, com um jogador substituindo um bot. Os critérios automáticos de atividade continuam aplicados aos bots; uma reprovação desse controle mantém os dados e deve ser analisada separadamente da experiência registrada no vídeo.

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

O launcher passa `--loadtest-players=N`, `--loadtest-duration=900`, `--loadtest-score=10000` e `--loadtest-ammo=10000` aos projetos. Para execuções mais longas, amplia o tempo da partida para comportar a janela. Esses argumentos são **opt-in**: sem eles, os presets continuam com dois jogadores, 300 segundos e 20 pontos. A pontuação alta evita o encerramento precoce; não muda regras de combate ou objetivo. Para as rodadas posteriores de 16/32, a formação inicial experimental reutiliza os nascimentos existentes por time, com sobreposição inicial; não há novo mapa, nascimentos adicionais ou entrada tardia. O limite experimental é 64.

Bots selecionam arma na fase autorizada, movem-se com a física normal, miram, disparam respeitando o caminho da arma e tentam lançar granadas. Também selecionam arma após morrer. O driver é externo ao startup normal do jogo e só contorna o foco de janela nos seus próprios processos headless.

O perfil atual, `smg-single-pulse-2s-v1`, usa SMG com um pulso curto a cada dois segundos, com fase inicial por seed. É combate leve sustentado, não rajadas contínuas; movimento, saltos e tentativas de granada continuam ativos. A munição inicial alta, solicitada pelo autor, permite sustentar a rodada sem depender de encontrar pickups: o catálogo experimental duplica as definições em memória, com início/capacidade compatíveis com `--ammo`, mas cada tiro ainda consome a quantidade normal. Os recursos base e a munição das partidas sem opt-in permanecem iguais. Identifique perfil e munição ao interpretar resultados, sem generalizar para uma carga de combate mais intensa ou para a economia normal de recursos do jogo.

O ensaio verifica movimento e disparos reais em janelas de tempo vivo, snapshots recentes, ocupação e duração. Se o bot ficar sem atividade sustentada, a rodada falha; conexão isolada não basta. Falhas conservam logs e CSVs para diagnóstico.

## Ler os resultados

- `server-metrics/server_network_metrics_*.csv`: amostras de jogadores/lobbies, RTT, perda estimada, tráfego e custo parcial instrumentado dos lobbies.
- `server-metrics/server_client_fps_metrics_*.csv`: FPS informados pelos Clients e identificados por `peer_id`.
- `bot-*.csv` e, se usado, `human-*.csv`: atividade observada, disparos, tentativas, mortes/retornos e janelas de validação. Tentativa de granada não é contagem de explosões confirmadas.
- `summary.json`: opções, seed, identificação da árvore de trabalho, peers/roster, comandos, resumo das amostras e estado da rodada.
- `*.log` / `*.engine.log`: diagnóstico por processo. `server-active.log`, quando produzido, separa a execução medida do encerramento.

`completed` significa que a janela automatizada e suas verificações foram concluídas. O resumo mantém **`playability: not_assessed_automated_run`**: CSV e FPS headless não comprovam resposta visual ou jogabilidade humana. Tempo parcial de lobby não é uso total de CPU nem orçamento de todo o tick. Resultados locais não medem a capacidade da KVM2.

Para medir a KVM2 futuramente, preparar nela o mesmo código/configuração e habilitar a gravação CSV do Server. Iniciar somente os clientes no computador gerador com `--external-server --host ENDEREÇO`, usando o mesmo N/preset. O launcher não faz SSH/deploy nem busca CSV remoto; copie esses arquivos separadamente. O resumo informa essa pendência e compara a identidade de lobby/roster dos participantes. Não rode clientes geradores na própria VPS usada como alvo.

Na execução com jogador humano, observe resposta aos comandos, movimentação, combate, reaparecimento e atualização do placar. Preserve o vídeo junto dos CSVs da mesma rodada. Nenhum resultado automatizado substitui essa observação.
