# Documentação Técnica Básica

## Visão Geral Atual

O projeto `Jump'n'Shoot` está implementado como dois projetos Godot 4.5 separados em `initial_project/Server` e `initial_project/Client`. O servidor abre uma instância `ENetMultiplayerPeer` na porta `7777`, enquanto o cliente tenta conectar automaticamente em `127.0.0.1:7777` no autoload `Server`.

A implementação atual não segue exatamente a arquitetura P2P descrita em `TCC.md`. O jogo usa um servidor separado e autoritativo. Essa escolha reduz o risco de inconsistência entre clientes e facilita validação de dano, pontuação, coleta de itens e estado de partida, que são problemas apontados no TCC ao discutir jogos multijogador em rede.

## Fluxo De Execução

O cliente inicia em `initial_project/Client/project.godot`, carrega `res://game/main_game.tscn` e o nó `LocalGameSceneManager` troca a cena inicial para `res://ui/main_menu/main_menu.tscn`. O autoload `res://server/server.tscn` mantém a conexão com o servidor e cria o lobby local quando recebe a autorização do servidor.

O servidor inicia em `initial_project/Server/project.godot`, mas a lógica real de inicialização fica no autoload `res://server/server.tscn`. O script `server/server.gd` cria o peer ENet, controla clientes ociosos, cria lobbies e bloqueia o lobby quando atinge `MAX_PLAYERS_PER_LOBBY`.

O lobby do servidor carrega `res://maps/server_map_farm.tscn`. O lobby do cliente carrega `res://maps/map_farm.tscn`. O servidor cria os jogadores reais e dummies; o cliente cria o jogador local e os jogadores remotos visuais.

## Problemas Do TCC E Soluções Implementadas

| Problema citado ou implícito no TCC | Solução atual no projeto | Arquivos principais |
| --- | --- | --- |
| Conectar jogadores em rede | Cliente e servidor usam `ENetMultiplayerPeer`; o cliente conecta em `127.0.0.1:7777` e pede entrada em lobby por RPC. | `Client/server/server.gd`, `Server/server/server.gd` |
| Organizar jogadores em partida | O servidor mantém `idle_clients`, cria `Lobby`, envia progresso de fila e bloqueia o lobby ao atingir a capacidade. | `Server/server/server.gd`, `Client/ui/main_menu/quick_play_connection_ui.gd` |
| Evitar inconsistência de estado entre clientes | O servidor é autoritativo para lobby, spawn, vida, morte, pontuação, pickups, granadas e fim da partida. | `Server/server/lobby.gd` |
| Sincronizar movimento remoto | O cliente envia `playerState` ao servidor; o servidor inclui estados no `current_world_state`; clientes interpolam estados recebidos. | `Client/server/lobby.gd`, `Server/server/lobby.gd` |
| Compensar latência em tiros | O cliente envia timestamp do disparo; o servidor mantém histórico de estados, reposiciona dummies para o estado passado e calcula raycasts. | `Client/server/server.gd`, `Server/server/lobby.gd`, `Server/player/player_server_dummy.gd` |
| Tratar eventos frequentes e eventos críticos | Estados frequentes usam RPC `unreliable_ordered` ou `unreliable`; eventos críticos como spawn, início de mapa, pickups, morte e fim de partida usam RPC `reliable`. | `Client/server/lobby.gd`, `Server/server/lobby.gd` |
| Representar diferentes hitboxes | O servidor usa dummies com `HitBox` em ossos do personagem e multiplicador de dano por parte do corpo. | `Server/player/player_server_dummy.tscn`, `Server/player/hitbox.gd` |
| Feedback visual de combate | Cliente mostra muzzle flash, impactos de bala, shake de câmera, máscara de dano e barra de vida. | `Client/player/local_weapon_holder.gd`, `Client/player/bullet_hit_fx`, `Client/player/local/camera_shake_component.gd`, `Client/ui/hud/health_change_mask.gd` |
| Coleta de itens com estado compartilhado | O servidor detecta coleta, aplica efeito, inicia cooldown e replica início/fim do cooldown para os clientes. | `Server/player/pickups/pickup.gd`, `Client/player/pickups/pickup.gd` |
| Simular projéteis explosivos | Granadas são simuladas no servidor como `RigidBody3D`; clientes recebem a transformação no estado de mundo e interpolam o visual. | `Server/player/grenade/grenade.gd`, `Client/player/grenade/grenade.gd` |

## Funcionalidades Implementadas

### Lobby E Matchmaking

O servidor implementa uma fila simples de quick play. A capacidade atual é intencionalmente pequena: `MAX_LOBBIES = 1` e `MAX_PLAYERS_PER_LOBBY = 2`. Quando dois clientes entram, o lobby é bloqueado e os clientes criam o lobby local.

O cliente mostra uma interface de conexão rápida, informa se está procurando outro jogador e permite cancelar a busca antes do lobby ser bloqueado. O nome do jogador é salvo em `user://player_name.dat`.

### Carregamento De Partida

O servidor carrega a versão server-side do mapa farm e coleta os nós `SpawnPoints` e `Pickups`. O cliente carrega a versão visual do mapa farm, limpa a cena de menu e avisa o servidor quando o mapa está pronto.

Depois do carregamento, o servidor inicia a tela de seleção de arma nos clientes. Quando todos escolhem uma arma, o servidor cria os jogadores, espera um curto intervalo e libera o controle do jogador local.

### Movimento E Estado De Jogador

O jogador local implementa movimentação FPS básica com teclado e mouse: andar, correr, pular, mirar e atirar. A movimentação é calculada no cliente local para manter resposta imediata.

O cliente envia ao servidor posição, rotação vertical e horizontal e animação atual. O servidor replica esses dados em estados de mundo. Os clientes interpolam jogadores remotos com um buffer de `100 ms`, reduzindo tremedeira visual causada por variação de rede.

### Combate E Armas

As armas atuais são pistola, SMG e shotgun. O cliente controla cooldown, disparo automático quando aplicável, efeitos de muzzle flash, recuo visual e shake de câmera. O servidor busca os dados de dano, precisão e quantidade de projéteis em `WeaponConfig`.

O cálculo de acerto é autoritativo no servidor. Para tiros, o servidor usa o timestamp enviado pelo cliente, busca um estado antigo salvo em `previous_world_states`, posiciona os dummies naquele estado e realiza raycasts contra hitboxes e colisões exatas do cenário. Isso implementa uma forma simples de compensação de latência.

### Vida, Morte, Respawn E Pontuação

Cada jogador server-side tem `MAX_HEALTH = 100`. Ao receber dano, o servidor atualiza a vida e replica o valor para os clientes. Quando a vida chega a zero, o servidor remove o jogador, incrementa mortes e kills, atualiza o placar e inicia um cooldown de respawn.

Após o cooldown, o jogador volta para a seleção de arma e respawna no time original. O modo atual funciona como mata-mata em equipe simplificado, com tempo máximo de `300` segundos e vitória ao atingir `TEAM_SCORE_TO_WIN = 2`.

### Pickups E Granadas

O mapa server-side possui pickups de vida e pickups de granada. Pickups de vida curam o jogador quando ele não está com vida cheia. Pickups de granada aumentam a quantidade disponível de granadas. O servidor replica cooldown dos pickups para o cliente esconder ou mostrar o item visual.

Granadas são arremessadas pelo cliente, mas validadas e simuladas no servidor. A explosão aplica dano por distância dentro de um raio. O cliente replica a posição da granada por interpolação, mostra efeito de explosão e exibe indicadores direcionais para granadas próximas.

### Interface, Música E Feedback

A interface atual inclui menu principal, quick play, seleção de arma, HUD com vida/granadas, placar de partida, tempo restante e tela final com kills/deaths. O cliente possui um `AudioManager` autoload que troca entre música de menu e música de partida com transição por tween.

## Decisões Técnicas Relevantes

### Servidor Autoritativo Em Vez De P2P

Embora o TCC proponha uma arquitetura P2P/hospedeiro, a implementação atual usa um servidor dedicado em projeto separado. Para o estágio atual do jogo, essa é uma decisão defensável porque simplifica validação de regras e reduz a chance de divergência entre clientes.

Se o texto do TCC permanecer com P2P, será necessário ajustar a implementação ou atualizar a documentação acadêmica para refletir a arquitetura real. A opção mais segura para entrega é manter o servidor autoritativo e explicar a mudança como refinamento técnico.

### Snapshots De Estado E Interpolação

O servidor envia snapshots contendo estado dos jogadores (`ps`), timestamp (`t`) e granadas (`gr`). O cliente renderiza estados antigos com atraso controlado para interpolar entre dois snapshots conhecidos. Isso resolve parte do problema de jitter e perda de pacotes sem exigir sincronização automática por `MultiplayerSynchronizer`.

### Histórico Para Lag Compensation

O servidor guarda estados anteriores em `previous_world_states`. Ao receber um tiro, calcula o estado-alvo usando o timestamp do cliente e reposiciona dummies antes de fazer raycast. Essa técnica resolve parcialmente o problema de o jogador atirar no que viu na tela, enquanto o servidor já está em outro instante.

### Contratos Por Dictionary

Várias mensagens usam `Dictionary` com chaves string como `pos`, `rot_y`, `rot_x`, `anim`, `ps`, `gr` e `t`. Isso é simples e rápido para prototipagem, mas cria risco de erro de digitação e divergência entre cliente e servidor. O próprio `TODO.md` já registra a necessidade de evoluir esses contratos.

## Débitos Técnicos Atuais

| Débito | Impacto | Sugestão |
| --- | --- | --- |
| Constantes hardcoded de lobby, mapa, porta, pontuação e tempo | Dificulta menus de configuração e modos diferentes | Criar um `MatchConfig` enviado pelo servidor aos clientes |
| Contratos de rede baseados em `Dictionary` livre | Alto risco de chave errada entre projetos | Centralizar nomes de chaves e enums em scripts compartilhados copiados para Client/Server |
| Ausência de testes automatizados | Regressões só aparecem em teste manual | Manter checklist manual e criar cenas de teste pequenas para armas/pickups |
| Mapa e modo hardcoded | Impede seleção de modo e mapa | Introduzir `GameMode` e `MapId` no fluxo de lobby |
| Sem export preset | Não há artefato final para entrega | Criar `export_presets.cfg` para PC quando o loop principal estiver estável |
