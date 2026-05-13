Pelo TCC.md, o escopo prometido é um FPS 3D multiplayer estilo arena, com elementos de plataforma, diferentes modos de jogo e regras próprias, citando “mata-mata” e “capture a bandeira” como exemplos. O próprio texto também associa arena shooter a seleção de armas, munição limitada e coleta de itens pelo cenário.

O comparativo do projeto já registrava as lacunas principais: configuração de partida, suporte a controle, armas coletáveis, munição limitada, plataformas especiais, export/deploy, assets finais e atualização do texto para refletir a arquitetura real.

Minha recomendação: não implementar troca de arma + munição agora como feature principal. Ela atende bem ao TCC, mas aumenta risco porque toca arma, pickup, HUD, Server, Client, respawn e balanceamento. Eu deixaria como opcional P2, depois de fechar interface/deploy/validação.

Decisão de escopo
Mais simples que atende sua proposta

Eu fecharia assim:

Obrigatório para defesa:
- Server dedicado autoritativo documentado
- TDM funcionando
- KOTH funcionando como segundo modo real
- Pulo duplo
- JumpPad
- Plataforma móvel se der tempo
- Tela para digitar IP do servidor
- Fluxo simples de criação/configuração de partida no Server
- Suporte básico a controle
- Export Client/Server
- Assets mínimos e mapa final apresentável
- Smoke test final
Cortaria ou deixaria como futuro
Cortar:
- Capture the Flag
- arma coletável + munição completa
- powerups
- vida limitada
- lobby browser/lista de salas
- host automático pelo Client

Capture the Flag foi citado no TCC, mas seu projeto já tem KOTH como segundo modo. É defensável atualizar o texto dizendo que CTF foi substituído por KOTH por ser mais adequado ao prazo e à arquitetura.

Sobre as três dúvidas principais
1. Troca de arma e munição: vale o risco?

Não como prioridade agora.

Os refactors de arma realmente ajudam: o PR #71 já foi mergeado e fecha #44, #45 e #46, centralizando dados de arma no Server e no Client via WeaponGameplayData, WeaponPresentationData e WeaponRegistry.

Mas uma feature real de arma coletável + munição exigiria:

Server:
- inventário por jogador
- munição por arma
- validação de disparo com ammo > 0
- pickup de arma/munição
- troca de arma autorizada

Client:
- input para trocar arma
- HUD de munição
- feedback de sem munição
- arma atual replicada visualmente

Rede:
- RPC ou payload para arma atual
- update de munição
- pickup de arma

Isso é bastante coisa. Eu faria só se sobrar tempo.

Versão aceitável e menor:

Pistol infinita
SMG/Shotgun escolhidas no respawn
Sem munição limitada

Já é suficiente para mostrar seleção de arma e arena shooter.

2. Suporte a controle: vale a pena?

Sim. É baixo risco e ajuda a cumprir a proposta.

Não precisa criar UI complexa. Godot já trabalha bem com input actions. A task deve mapear gamepad para as ações existentes:

move
look
jump
sprint
shoot
throw_grenade
ui_accept
ui_cancel

O maior cuidado é o analógico direito para câmera.

Task sugerida:

#66 Adicionar suporte básico a controle/gamepad

Como jogador, quero controlar movimentação, câmera, pulo, sprint, tiro e menus usando controle para atender ao suporte previsto na proposta.

Tarefas:
- Mapear ações existentes para controle no Input Map.
- Adicionar look com analógico direito no PlayerLocal.
- Manter mouse/teclado funcionando.
- Testar menu principal, seleção de arma, pausa e partida.
- Não criar remapeamento de controles.
- Não criar tela de configuração de controle.

Prioridade: P1.

3. Configuração das regras da partida

Aqui eu escolheria a solução mais simples compatível com servidor dedicado:

Server define a configuração da partida.
Client apenas conecta.

Ou seja: não fazer o Client iniciar servidor headless agora.

Essa ideia de o Client abrir um servidor headless com parâmetros é mais próxima de “host local”/P2P. Ela complica sua arquitetura atual, que já está melhor como Client/Server dedicado. O comparativo já identificou que o código real usa servidor separado autoritativo, enquanto a proposta antiga falava em hospedeiro/P2P; a recomendação ali é manter a arquitetura autoritativa e atualizar o texto do TCC.

A solução simples:

Server:
- sobe com parâmetros:
  --port=7777
  --mode=koth
  --map=prototype
  --time-limit=300
  --score-to-win=30

Client:
- tela com campo IP
- conecta no servidor
- servidor responde estado:
  waiting_for_players / in_game / full
- se waiting_for_players, entra no lobby

Isso atende “configuração de regras” sem criar host integrado.

Plano de tarefas priorizado
P0 — Fechar entrega executável e demonstrável
#31 — Rodar smoke test em 2 mapas e 2 modos

Manter. Essa task valida TDM + KOTH em farm/prototype.

#63 — Garantir assets do Client no build final

Manter. O comparativo já alerta que assets e export final ainda eram lacunas importantes.

#64 — Atualizar prototype map para apresentação final

Manter. Essa task vira o mapa de demonstração.

#65 — Rodar smoke test final com movimento, KOTH e deploy

Manter. Essa deve ser a última task técnica antes de gravar vídeo/screenshots.

P1 — Criar tasks novas para cumprir a proposta com baixo risco
Nova task — Tela de conexão por IP
#66 Criar tela simples de conexão por IP

Como jogador, quero informar o IP do servidor para conectar em uma partida local/LAN ou remota.

Tarefas:
- Adicionar campo de texto para IP no menu principal.
- Adicionar campo opcional para porta.
- Usar valores padrão 127.0.0.1 e 7777.
- Integrar com NetworkConfig já existente.
- Exibir mensagem simples em caso de falha de conexão.
- Não criar lista de servidores.
- Não criar matchmaking público.

Prioridade: P0/P1.
É simples e resolve grande parte da promessa de fluxo de interface.

Nova task — Server aceitar configuração de partida por CLI
#67 Permitir configurar partida por parâmetros do Server

Como dev, quero iniciar o Server com modo, mapa, tempo e score por argumentos de linha de comando.

Tarefas:
- Ler argumentos após `--`.
- Suportar `--mode=tdm|koth`.
- Suportar `--map=farm|prototype`.
- Suportar `--time-limit=300`.
- Suportar `--score-to-win=30`.
- Aplicar os valores no MatchConfig usado pelo lobby.
- Manter defaults atuais se nenhum argumento for informado.
- Logar a configuração final no boot.
- Não criar UI de configuração no Client.

Prioridade: P1.

Essa é a forma mais simples de “configuração das regras da partida” mantendo servidor dedicado autoritativo.

Nova task — Client exibir estado da conexão/lobby
#68 Mostrar estado básico do servidor no Client

Como jogador, quero saber se consegui conectar ao servidor e se estou aguardando outro jogador.

Tarefas:
- Mostrar estado "Conectando...".
- Mostrar erro se a conexão falhar.
- Mostrar "Aguardando jogadores" quando estiver no lobby.
- Mostrar "Partida cheia" ou "Lobby bloqueado" se o Server recusar entrada.
- Reusar sinais já existentes do Client/Server.
- Não criar lista de salas.

Prioridade: P1.

Nova task — Suporte básico a controle/gamepad
#69 Adicionar suporte básico a controle/gamepad

Como jogador, quero jogar usando controle para atender ao suporte previsto na proposta.

Tarefas:
- Mapear ações de movimento no analógico esquerdo.
- Mapear câmera no analógico direito.
- Mapear tiro, pulo, sprint e granada.
- Mapear ações de UI: aceitar, voltar e pause.
- Ajustar PlayerLocal para processar look por joystick.
- Manter mouse/teclado funcionando.
- Não criar tela de remapeamento de controle.

Prioridade: P1.

P2 — Features que atendem ao TCC, mas têm risco maior
Nova task — HUD de munição sem lógica completa
#70 Preparar HUD de munição para arma atual

Como jogador, quero visualizar a munição da arma atual quando o sistema de munição estiver ativo.

Tarefas:
- Adicionar label/ícone de munição no HUD.
- Criar método `update_ammo(current, reserve)` no HUD.
- Manter escondido enquanto munição não for usada.
- Não implementar lógica de munição nesta task.

Prioridade: P2.

Só vale se você decidir implementar munição depois.

Nova task — Munição simples para armas não-pistola
#71 Implementar munição simples para SMG e Shotgun

Como jogador, quero que armas mais fortes tenham munição limitada para reforçar a dinâmica de arena shooter.

Tarefas:
- Pistola continua com munição infinita.
- SMG e Shotgun passam a ter munição limitada.
- Server valida se a arma atual tem munição antes de calcular tiro.
- Server decrementa munição ao disparar.
- Client recebe atualização de munição.
- HUD mostra munição atual.
- Se a arma ficar sem munição, o jogador continua com a pistola disponível.

Prioridade: P2 alto risco.

Eu só faria depois de #43 e #47.

Nova task — Pickup de munição
#72 Criar pickup de munição

Como jogador, quero coletar munição pelo mapa para continuar usando armas mais fortes.

Tarefas:
- Adicionar `PickupType.AMMO`.
- Criar PickupData para munição.
- Server aplica munição ao jogador.
- Client mostra visual simples do pickup.
- Pickup entra em cooldown como vida/granada.
- Não criar pickup de arma nesta task.

Prioridade: P2 alto risco.

Depende de #47.

Nova task — Troca de arma durante a partida
#73 Permitir trocar arma durante a partida

Como jogador, quero alternar entre armas disponíveis durante a partida.

Tarefas:
- Criar input para próxima arma/anterior arma.
- Manter arma atual no Client.
- Notificar Server da arma atual.
- Server valida se jogador possui a arma.
- Atualizar arma visual local e remota.
- Manter seleção inicial de arma funcionando.

Prioridade: P2 alto risco.

Essa é mais arriscada que munição, porque mexe no estado visual local/remoto e no Server.

O que fazer com #43, #47 e #48
#43 NetworkEntity para pickups e granadas

Eu manteria. É refactor seguro e prepara pickup de munição sem depender de node.name.

Prioridade: P1, antes de mexer em pickup de munição.

#47 PickupData para vida e granada

Eu faria se você quiser abrir caminho para munição. Sem #47, pickup de munição tende a virar mais um match hardcoded.

Prioridade:

Se for implementar munição: P1
Se não for implementar munição: P2
#48 AudioEventData

Eu deixaria para depois. Não bloqueia entrega.

Prioridade: P3.

Minha recomendação final de priorização
Caminho recomendado
1. #43 NetworkEntity para pickups e granadas
2. #63 Garantir assets do Client no build final
3. #64 Atualizar prototype map para apresentação final
4. Nova #66 Tela de conexão por IP
5. Nova #67 Server aceitar configuração por CLI
6. Nova #68 Estado básico de conexão/lobby
7. Nova #69 Suporte básico a controle
8. #61 Plataforma móvel determinística
9. #31 Smoke test em 2 mapas e 2 modos
10. #65 Smoke test final
Só depois, se sobrar tempo
11. #47 PickupData
12. Nova #70 HUD de munição
13. Nova #71 Munição simples
14. Nova #72 Pickup de munição
15. Nova #73 Troca de arma durante a partida
Sobre “configurar regras pela interface”

Eu não faria isso como UI completa agora.

A versão mínima defensável:

Server:
  configura regras por CLI

Client:
  digita IP e conecta

Menu:
  mostra estado da partida

Na escrita do TCC, você pode explicar:

A configuração da partida foi mantida no processo servidor, por coerência com a arquitetura dedicada/autoritativa. O cliente não decide regras da partida; ele apenas conecta-se a uma instância de servidor previamente configurada.

Isso é tecnicamente mais correto do que deixar o Client mandar regras para o Server sem autenticação/controle.

Conclusão

A feature de arma coletável + munição é coerente com o TCC.md, mas não é a melhor próxima aposta. O melhor custo-benefício agora é:

IP no menu
configuração do Server por CLI
controle/gamepad
assets/mapa final
smoke test

Isso fecha melhor a promessa do TCC com menos risco que inventário, munição e troca dinâmica de arma.