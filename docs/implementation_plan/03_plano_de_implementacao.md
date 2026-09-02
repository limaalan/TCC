# Plano De Implementação

## Direção Recomendada

Manter a arquitetura atual de servidor autoritativo. Reverter para P2P apenas para seguir literalmente o texto antigo do `TCC.md` custaria tempo e removeria soluções úteis já implementadas para validação, latência e consistência. O caminho mais seguro é atualizar a redação do TCC para explicar que a implementação evoluiu para cliente/servidor dedicado.

O objetivo prático deve ser transformar o protótipo atual em uma entrega coerente: um FPS arena multiplayer com pelo menos o modo mata-mata em equipe estável, uma ou duas mecânicas avançadas bem demonstradas e documentação clara das técnicas de rede.

## Prioridades

| Prioridade | Entrega | Motivo |
| --- | --- | --- |
| P0 | Estabilizar o loop atual de mata-mata | Sem estabilidade, qualquer modo novo aumenta bugs de rede |
| P0 | Criar configuração de partida mínima | Tempo, score, vidas e modo são citados no TCC |
| P0 | Exportar build PC e testar em LAN | Necessário para demonstrar o jogo fora do editor |
| P1 | Implementar vidas limitadas e munição | São regras explícitas da proposta |
| P1 | Implementar CTF ou Rei do Pedaço | Entrega pelo menos um modo extra proposto |
| P1 | Implementar powerups ou plataformas especiais | Mostra elementos de arena/plataforma além do FPS básico |
| P2 | Completar todos os modos, armas e polimento audiovisual | Aproxima o escopo completo, mas tem maior custo |

## Fase 0: Estabilizar O Projeto Atual

### Objetivo

Garantir que o estado atual seja jogável, previsível e documentável antes de adicionar novas mecânicas.

### Tarefas

| Tarefa | Arquivos prováveis | Critério de pronto |
| --- | --- | --- |
| Testar servidor + dois clientes localmente | Ambos os projetos | Dois jogadores entram, escolhem arma, se movem e veem um ao outro |
| Validar tiros, dano, morte e respawn | `Server/server/lobby.gd`, `Client/server/lobby.gd` | Tiro causa dano no alvo correto e respawn ocorre sem erro |
| Validar granadas e pickups | `Server/player/grenade`, `Server/player/pickups`, equivalentes no Client | Contador de granadas, cooldown e explosão funcionam para ambos os clientes |
| Remover prints excessivos ou marcar como debug | `WeaponConfig`, lobby scripts | Console não fica poluído durante apresentação |
| Criar checklist manual de teste | `implementation_plan` ou docs finais | Checklist cobre conexão, partida, combate, pickups e fim |

### Observações

Antes de adicionar funcionalidades, vale corrigir qualquer regressão de estado autoritativo. Um exemplo típico é garantir que métodos como `update_grenades_left()` alterem o estado no servidor antes de replicar para o cliente.

## Fase 1: Configuração De Partida E Mata-Mata Completo

### Objetivo

Fechar o modo mata-mata em equipe como modo completo, com regras configuráveis e aderentes ao TCC.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Criar `MatchConfig` | Dictionary ou Resource com `mode`, `time_limit`, `score_to_win`, `lives`, `map_id` | Servidor inicia lobby usando config, mesmo que ainda hardcoded |
| Substituir constantes diretas | Trocar `MATCH_LENGTH_SEC` e `TEAM_SCORE_TO_WIN` por valores da config | Tempo e pontuação vêm de um único objeto |
| Adicionar vidas limitadas | `client_data[client_id].lives_left`; decrementar em morte | Jogador sem vidas não respawna |
| Encerrar por eliminação | Verificar se um time não tem jogadores com vidas | Partida termina por score, tempo ou eliminação |
| Atualizar HUD | Mostrar vidas restantes e objetivo atual | Jogador entende a regra da partida |
| Atualizar tela final | Mostrar vencedor e motivo da vitória | Tela final deixa claro quem venceu |

## Fase 2: Munição, Armas E Pickups De Arma

### Objetivo

Aproximar o combate da proposta de arena shooter: pistola infinita, armas fortes com munição limitada e coleta no mapa.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Definir inventário simples | Estado server-side por jogador: arma atual e munição por arma | Servidor sabe se o jogador pode disparar |
| Pistola infinita | Arma 0 sem consumo de munição | Jogador sempre consegue voltar à pistola |
| Munição para SMG/shotgun | Consumir munição no servidor a cada tiro aceito | Arma para de atirar ao acabar munição |
| Pickup de arma/munição | Expandir `PickupTypes` ou criar `WeaponPickup` | Coletar item concede arma e munição |
| UI de munição | Adicionar label no HUD | Jogador vê munição atual |
| Hotkeys 1/2/3/4 | Inputs de troca de arma no cliente, pedido ao servidor | Troca respeita inventário validado pelo servidor |
| Canhão laser | Hitscan preciso, dano alto, cooldown alto | Arma id 3 funcional no client/server |
| Lança-foguetes | Projétil server-side com dano em área, reutilizando lógica de granada | Arma id 4 funcional com explosão |

## Fase 3: Plataformas E Movimento Avançado

### Objetivo

Entregar os elementos de plataforma prometidos no `TCC.md` sem comprometer o multiplayer.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Pulo duplo | Contador de pulos em `PlayerLocal`; incluir estado se necessário | Jogador consegue um segundo pulo antes de tocar o chão |
| Jump pad | `Area3D` no client/server ou impulso validado pelo servidor | Jogador é lançado para frente/cima em ambos os clientes |
| Plataforma móvel | Movimento determinístico por tempo ou estado enviado pelo servidor | Clientes veem plataforma no mesmo lugar |
| Plataforma quebradiça | Trigger ao contato, timer, desativação e respawn | Plataforma some para todos e volta após cooldown |
| Atualizar mapa | Colocar uma mecânica de cada tipo no mapa farm ou novo mapa | Mecânicas aparecem em locais úteis, não apenas decorativos |

## Fase 4: Powerups Temporários

### Objetivo

Implementar as melhorias temporárias descritas na proposta.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Powerup de dano dobrado | Estado server-side `damage_multiplier_until` | Dano dobra por 15 segundos e depois volta ao normal |
| Powerup de velocidade | Estado autorizado pelo servidor e replicado ao cliente local | Velocidade aumenta por 15 segundos sem permitir trapaça simples |
| Feedback visual | Ícone no HUD e/ou material no jogador | Todos entendem que o powerup está ativo |
| Cooldown no mapa | Reutilizar sistema de pickups | Powerup some e reaparece corretamente |

## Fase 5: Modos De Jogo Extras

### Objetivo

Implementar os modos restantes do TCC com o mínimo de duplicação.

### Preparação

Antes dos modos extras, separar no servidor funções comuns de partida: `start_match`, `player_died`, `update_game_scores`, `match_timer_sec_passed` e `end_match`. Não precisa criar uma hierarquia complexa; um enum `GameMode` e funções específicas por modo já bastam para o escopo do TCC.

### Capture A Bandeira

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Criar cenas de bandeira | Versão server-side com `Area3D`; versão client-side visual | Bandeiras aparecem nas bases |
| Estado da bandeira | `at_base`, `carried_by`, `dropped_transform`, `team` | Servidor controla quem carrega cada bandeira |
| Captura | Jogador entra na base com bandeira inimiga e sua bandeira em casa | Time pontua corretamente |
| Queda/devolução | Ao morrer, bandeira cai; aliado devolve; inimigo recolhe | Fluxo básico de CTF funciona |
| HUD de CTF | Mostrar placar e estado das bandeiras | Jogador entende objetivo |

### Rei Do Pedaço

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Criar zona central | `Area3D` server-side no mapa | Servidor detecta jogadores dentro da zona |
| Determinar controle | Contar jogadores vivos por time dentro da área | Time controla se está sozinho ou em vantagem conforme regra escolhida |
| Pontuar por tempo | Timer soma pontos ao time controlador | Pontuação cresce enquanto time controla a área |
| Disputa neutra | Sem pontuação quando ambos contestam | Regra fica clara e justa |
| HUD de zona | Mostrar time controlador e progresso | Jogador entende quem está pontuando |

## Fase 6: Interface De Partida

### Objetivo

Alinhar o fluxo de telas com a proposta: criar partida, entrar em partida, escolher opções e pausar.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| Tela de conexão por IP | Campo de IP substitui `ADDRESS = "127.0.0.1"` | Cliente conecta em outro computador na LAN |
| Tela de criar partida | Se mantiver servidor dedicado, virar tela de configuração local ou admin | Jogador escolhe modo, tempo, score e vidas |
| Tela de entrar em partida | IP + nome do jogador + botão conectar | Fluxo documentável no TCC |
| Menu de pausa | ESC abre overlay com voltar ao menu e sair | Jogador não precisa fechar o jogo para sair |
| Mensagens de erro | Falha de conexão, lobby cheio, partida em andamento | Erros ficam compreensíveis |

## Fase 7: Áudio, Arte, Exportação E Testes

### Objetivo

Finalizar a entrega demonstrável.

### Tarefas

| Tarefa | Implementação sugerida | Critério de pronto |
| --- | --- | --- |
| SFX de tiros | Adicionar streams por arma no `AudioManager` ou na cena da arma | Cada disparo tem som local/remoto |
| SFX de passos, pickups e UI | Reutilizar enum `SFXKeys` já iniciado | Ações principais têm feedback sonoro |
| Polimento visual | Ajustar materiais, iluminação, VFX e tela final | Visual coerente com estilo cartunesco |
| Export preset PC | Criar `export_presets.cfg` em Client e, se necessário, Server | Build executável gerada fora do editor |
| Teste LAN | Rodar servidor em uma máquina e clientes em duas máquinas | Conexão por IP funciona na rede local |
| Teste Internet | Testar porta, firewall ou VPN | Documentar limitações de infraestrutura |
| Capturas para TCC | Prints do menu, mapa, combate, pickups, placar e modos | TCC 2 tem evidência visual do resultado |

## Plano De Entrega Enxuto

Se o prazo estiver curto, a ordem mínima recomendada é esta:

1. Estabilizar mata-mata em equipe atual.
2. Adicionar vidas limitadas e configuração de tempo/pontuação.
3. Adicionar munição e pelo menos um pickup de arma.
4. Implementar apenas um modo extra completo, preferencialmente Rei do Pedaço por ser menor que Capture a Bandeira.
5. Adicionar jump pad ou pulo duplo como evidência dos elementos de plataforma.
6. Fazer export PC e teste LAN.
7. Atualizar o TCC para explicar a arquitetura cliente/servidor autoritativa.

## Checklist Manual De Verificação

| Cenário | Passos | Resultado esperado |
| --- | --- | --- |
| Conexão local | Abrir Server, abrir dois Clients, clicar Play nos dois | Lobby fecha em 2/2 e mapa carrega |
| Spawn | Ambos escolhem arma | Jogadores aparecem em times opostos e controle é liberado |
| Movimento remoto | Mover um jogador | Outro cliente vê movimento interpolado sem travamentos graves |
| Tiro | Atirar no inimigo | Vida diminui, hit FX aparece e placar atualiza ao morrer |
| Respawn | Aguardar cooldown após morte | Jogador volta para seleção de arma e respawna |
| Pickups | Coletar vida/granada | Efeito aplica, item some e volta após cooldown |
| Granada | Arremessar granada perto do inimigo | Granada replica, explode e causa dano por distância |
| Fim de partida | Atingir score ou tempo limite | Tela final aparece para ambos com estatísticas |
| Reconexão/sair | Fechar um cliente durante lobby ou partida | Servidor remove cliente sem travar |

## Ajustes Recomendados No Texto Do TCC

| Trecho do TCC | Ajuste recomendado |
| --- | --- |
| Arquitetura P2P/hospedeiro | Atualizar para arquitetura cliente/servidor dedicado/autoritativo ou justificar a mudança nos resultados |
| Uso de `MultiplayerSynchronizer` | Substituir por explicação de RPCs, snapshots, interpolação e lag compensation |
| Hospedeiro define opções | Se não for implementado, explicar que opções foram fixadas no protótipo; se for implementado, documentar `MatchConfig` |
| Três modos de jogo | Informar claramente quais modos foram entregues e quais ficaram como trabalhos futuros, caso o escopo seja reduzido |
| Armas propostas | Ajustar nomes finais: pistola, SMG/rifle, shotgun, laser e lança-foguetes conforme o que for entregue |
