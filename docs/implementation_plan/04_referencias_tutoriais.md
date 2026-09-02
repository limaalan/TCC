# Referências E Tutoriais Para Funcionalidades Restantes

## Critério De Seleção

As referências abaixo foram avaliadas pensando no projeto atual: dois projetos Godot 4.5 separados, servidor dedicado em `initial_project/Server`, cliente em `initial_project/Client`, RPCs manuais, snapshots de estado e interpolação. Tutoriais single-player ou 2D podem ser úteis, mas não devem ser copiados diretamente. A regra prática é implementar a regra de jogo no servidor e deixar o cliente com visual, entrada e feedback imediato quando necessário.

Para mecânicas de mapa, sempre criar ou atualizar a versão server-side e a versão client-side do mapa. Hoje o fluxo usa `res://maps/server_map_farm.tscn` no servidor e `res://maps/map_farm.tscn` no cliente.

## Resumo Recomendado

| Funcionalidade | Prioridade prática | Referências principais | Adaptação necessária | Risco |
| --- | --- | --- | --- | --- |
| Plataforma quebradiça/desaparecendo | Alta | `Area3D`, `Timer`, sistema atual de pickups | Servidor decide quebrar e respawnar; cliente só replica visual/colisão | Baixo |
| Jump pad | Alta | `Area3D`, `CharacterBody3D`, KidsCanCode Using Areas | Cliente aplica impulso para resposta; servidor valida zona ou evento | Baixo-médio |
| Pulo duplo | Alta | `CharacterBody3D`, GDQuest 3D movement, código atual `PlayerLocal` | Alteração local em `PlayerLocal`; opcionalmente validar depois no servidor | Baixo |
| Rei do Pedaço | Alta | `Area3D`, `Timer`, multiplayer/RPC docs | Área existe no servidor; HUD recebe estado por RPC | Baixo-médio |
| Pickup de arma/munição | Média | sistema atual de pickups, GameIdea weapon pickup, DEV ammo pickups | Expandir enum e inventário server-side; cliente replica UI/visual | Médio |
| Plataforma móvel | Média | `AnimatableBody3D`, `CharacterBody3D`, KidsCanCode/Coding Academy moving platform | Sincronizar ou calcular transform igual em servidor e cliente | Médio-alto |
| Powerups temporários | Média | sistema atual de pickups, `Timer`, `Area3D` | Estado temporário no servidor e feedback visual no cliente | Médio |
| `MultiplayerSynchronizer` | Baixa | docs oficiais | Usar só como referência teórica no TCC, não como base da implementação atual | Alto se tentar misturar |

## Referências Avaliadas

| Referência | Melhor uso no projeto | Qualidade | Observações de adaptação |
| --- | --- | --- | --- |
| <https://docs.godotengine.org/en/stable/classes/class_area3d.html> | Triggers para jump pad, Rei do Pedaço, plataformas quebradiças, pickups e zonas de dano | Alta | Usar `body_entered`, `body_exited` e `get_overlapping_bodies()` no servidor. No cliente, usar para feedback local quando não afeta regra crítica. |
| <https://docs.godotengine.org/en/stable/classes/class_timer.html> | Cooldown de pickups, delay para quebrar plataforma, respawn de plataforma, duração de powerups | Alta | O projeto já usa `Timer` em pickups server-side; vale reaproveitar o padrão. |
| <https://docs.godotengine.org/en/stable/classes/class_animatablebody3d.html> | Base correta para plataformas móveis 3D | Alta | `AnimatableBody3D` é indicado para corpos movidos manualmente que afetam outros corpos. Ativar movimento no passo de física. |
| <https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html> | Movimento, jump pad, pulo duplo e interação com plataformas móveis | Alta | Importante por `move_and_slide()`, `platform_floor_layers`, `platform_on_leave` e detecção de chão. |
| <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html> | RPCs, `reliable`, `unreliable`, canais e estrutura de lobby | Alta | Confirmar o uso atual: eventos críticos confiáveis, snapshots frequentes não confiáveis/ordenados. |
| <https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html> | Detalhes de ENet e conexão por UDP | Alta | Útil para explicar porta UDP `7777`, LAN e limites de conexão no TCC. |
| <https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html> | Comparação com a proposta original | Média | Não é recomendado encaixar agora, porque o projeto já tem replicação manual. Útil para justificar a mudança técnica. |
| <https://kidscancode.org/godot_recipes/4.x/g101/3d/101_3d_04/index.html> | Exemplo simples de `Area3D` para coletáveis, projéteis e dano | Alta | Está em 3D e mostra o padrão de sinal `body_entered`. Adaptar para Godot 4 atual e servidor autoritativo. |
| <https://kidscancode.org/godot_recipes/4.x/3d/basic_fps/index.html> | Revisão de FPS com `CharacterBody3D`, mouse look e pulo | Média | O projeto já tem FPS local. Usar só para comparar decisões simples de movimento. |
| <https://kidscancode.org/godot_recipes/4.x/2d/moving_platforms/index.html> | Conceito de plataforma animada com tween em passo físico | Média | É 2D, mas a ideia passa para `AnimatableBody3D`. Não copiar tipos `2D`. |
| <https://www.coding.academy/blog/how-to-create-a-moving-platform-in-godot-4> | Fluxo visual com `AnimationPlayer` e `AnimatableBody2D` | Média | Bom para entender editor/animação, mas é 2D e single-player. Preferir docs oficiais para a versão 3D. |
| <https://www.gdquest.com/library/character_movement_3d_platformer/> | Movimento 3D com salto, queda e `CharacterBody3D` | Alta | Bom para estudar salto e controle de velocidade. Adaptar ao FPS existente em `Client/player/local/player_local.gd`. |
| <https://gameidea.org/2025/09/07/adding-interaction-system-to-pick-up-weapons-fps-series-part-5/> | Weapon pickup por interação com `RayCast3D` e `Area3D` | Média-alta | Bom para pickup por tecla. No projeto atual, qualquer coleta precisa virar pedido/validação no servidor. |
| <https://dev.to/christinec_dev/lets-learn-godot-4-by-making-an-rpg-part-8-adding-ammo-pickups-consumables-1n63> | Enum de pickups, UI de quantidade, consumíveis e ammo | Média | É 2D/single-player. Aproveitar o conceito de enum e UI, mas implementar estado no servidor. |
| <https://chaffgames.com/making-an-fps-weapon-manager-in-godot-4/> | Organização conceitual de weapon manager e recursos de arma | Baixa-média | A página é mais índice de vídeo do que tutorial textual. Usar só para ideias, não como base principal. |

## Como Adaptar Por Funcionalidade

### Plataforma Quebradiça Ou Desaparecendo

Melhor abordagem para o projeto atual: implementar primeiro como evento discreto server-side. Isso evita o risco de sincronização contínua.

Referências úteis: `Area3D`, `Timer`, padrão atual de `Server/player/pickups/pickup.gd` e RPCs de cooldown em `Server/server/lobby.gd`.

Implementação sugerida:

| Peça | Server | Client |
| --- | --- | --- |
| Cena | `Node3D` com visual, colisão e `Area3D` detector | Mesma posição/nome, visual e colisão local |
| Trigger | `_on_body_entered(player: PlayerServerReal)` | Opcional, só para som/efeito local |
| Estado | `ready`, `breaking`, `broken`, com `Timer` de break e respawn | Recebe estado por RPC e esconde/mostra mesh/colisão |
| Rede | `s_set_breakable_platform_state(platform_name, state)` confiável | Aplica visual e colisão no node de mesmo nome |

Ordem mínima:

1. Criar uma plataforma quebradiça no mapa server-side com `Area3D` e `Timer`.
2. Ao detectar jogador, marcar como `breaking` e enviar RPC para os clientes.
3. Depois de curto delay, desativar colisão no servidor, esconder no cliente e marcar `broken`.
4. Depois do cooldown, reativar colisão no servidor, mostrar no cliente e marcar `ready`.

Essa é a mecânica de plataforma especial com melhor custo-benefício para apresentação, porque depende de estado discreto e já combina com o padrão dos pickups.

### Jump Pad

Referências úteis: `Area3D`, `CharacterBody3D`, KidsCanCode Using Areas.

O ponto importante é que o movimento atual do jogador é calculado no cliente em `Client/player/local/player_local.gd`, enquanto o servidor recebe `playerState` e espelha a posição em `Server/server/lobby.gd`. Portanto, um jump pad puramente server-side não vai mover o jogador local com boa resposta. O caminho prático é aplicar o impulso localmente e validar no servidor.

Implementação sugerida:

| Peça | Server | Client |
| --- | --- | --- |
| Área | `Area3D` no mapa server-side para validação | `Area3D` equivalente no mapa client-side para resposta imediata |
| Efeito | Confirma que o jogador tocou a zona ou aceita evento se próximo | Define `velocity.y` e, se desejado, adiciona impulso horizontal |
| Rede | Opcional: RPC confiável `s_apply_jump_pad_impulse(pad_name, impulse)` | Recebe correção se servidor quiser forçar o impulso |

Ordem mínima:

1. Adicionar `apply_jump_pad_impulse(impulse: Vector3)` em `PlayerLocal`.
2. No `Area3D` client-side, chamar esse método ao entrar na área.
3. Enviar `c_jump_pad_touched(pad_name)` para o servidor ou deixar o servidor detectar pelo `PlayerServerReal`.
4. No servidor, ignorar eventos se o jogador estiver longe demais do pad conhecido.

Para entrega curta, basta cliente aplicar e servidor validar sem correção pesada. Para rede mais robusta, o servidor envia evento confirmado aos clientes.

### Pulo Duplo

Referências úteis: `CharacterBody3D`, GDQuest 3D character movement, código atual `PlayerLocal`.

Implementação sugerida em `Client/player/local/player_local.gd`:

| Item | Mudança |
| --- | --- |
| Estado | Adicionar `@export var max_jumps := 2` e `var jumps_left := max_jumps` |
| Reset | Quando `is_on_floor()`, resetar `jumps_left` |
| Input | Se `jump` pressionado e `jumps_left > 0`, aplicar `velocity.y = jump_velocity` e decrementar |
| Animação | Reusar `AIR_ANIM` no primeiro momento |

Não exige RPC novo porque o estado enviado para o servidor já contém posição e animação. Se o texto do TCC precisar defender antitrapaça, documentar que a validação completa de movimento ficaria como trabalho futuro.

### Plataforma Móvel

Referências úteis: `AnimatableBody3D`, `CharacterBody3D`, KidsCanCode Moving Platforms, Coding Academy Moving Platform, `AnimationPlayer`.

Esta é a mecânica de maior risco entre as plataformas porque tem estado contínuo. O cliente precisa colidir com a plataforma no mesmo lugar em que o servidor faz raycast e validação. Se cada lado animar em tempos diferentes, o jogador pode ver uma plataforma em uma posição e o servidor em outra.

Duas abordagens viáveis:

| Abordagem | Descrição | Vantagem | Custo |
| --- | --- | --- | --- |
| Determinística por tempo | Server e client calculam posição pelo mesmo `platform_id`, posição inicial, offset, duração e tempo de início da partida | Pouca rede | Precisa sincronizar relógio/tempo de partida com cuidado |
| Replicada por snapshot | Servidor adiciona transforms das plataformas em `current_world_state`, por exemplo chave `pl` | Mais fiel ao servidor | Aumenta snapshot e exige interpolação client-side |

Recomendação para este projeto: começar determinístico se houver poucas plataformas e movimento simples. Usar `AnimatableBody3D` com movimento em `_physics_process()` ou `AnimationPlayer` em modo de física. Só adicionar `pl` ao snapshot se aparecer divergência visível.

Checklist técnico:

1. Usar `AnimatableBody3D` para a colisão da plataforma, não `StaticBody3D` movido sem cuidado.
2. Garantir que o `CharacterBody3D` local detecte a plataforma em `platform_floor_layers`.
3. Colocar a mesma plataforma, com o mesmo nome e configuração, no mapa server-side e client-side.
4. Evitar trajetórias complexas até o básico funcionar em LAN.
5. Testar tiro contra/ao redor da plataforma, porque o servidor faz raycasts contra o mundo server-side.

### Rei Do Pedaço

Referências úteis: `Area3D`, `Timer`, docs de RPC/multiplayer.

Implementação sugerida:

| Peça | Server | Client |
| --- | --- | --- |
| Zona | `Area3D` com lista de jogadores dentro | Mesh/indicador visual da zona |
| Controle | Contar jogadores vivos por time dentro da zona | Recebe time controlador e progresso por RPC |
| Pontuação | `Timer` por segundo ou uso do match timer atual | HUD mostra controle/contestada/neutra |
| RPC | `s_update_hill_state(controller_team, blue_inside, red_inside, progress)` | Atualiza `MatchInfoUi` ou UI nova |

Essa é a melhor escolha de modo extra para escopo enxuto. É menor que CTF porque não exige carregar bandeira, dropar, devolver e lidar com estado por jogador.

### Pickup De Arma E Munição

Referências úteis: sistema atual de pickups, GameIdea weapon pickup, DEV ammo pickups, ChaffGames weapon manager.

O projeto já tem a base mais importante: pickups server-side com cooldown e RPCs de visual no cliente. Para o TCC, é melhor evoluir esse sistema existente do que introduzir uma arquitetura nova de interação.

Implementação sugerida:

| Item | Mudança recomendada |
| --- | --- |
| Enum | Expandir `PickupTypes` em Client e Server com `WeaponPickup` e `AmmoPickup` |
| Estado do jogador | Adicionar inventário server-side em `client_data` ou no `PlayerServerReal` |
| Disparo | Servidor valida munição antes de aceitar dano em `c_shot_fired` |
| UI | Cliente recebe `s_update_ammo` e mostra munição atual |
| Visual | Cliente instancia mesh por tipo de arma/munição como já faz para vida/granada |

Se quiser pickup por tecla, usar o padrão do GameIdea com `RayCast3D`, mas o cliente deve enviar só um pedido ao servidor. O servidor decide se o jogador está perto do item e se a coleta é válida.

### Powerups Temporários

Referências úteis: sistema atual de pickups, `Timer`, `Area3D`.

Implementação sugerida:

| Powerup | Estado server-side | Efeito no cliente |
| --- | --- | --- |
| Dano dobrado | `damage_multiplier_until` ou `damage_multiplier` com `Timer` | Ícone no HUD e talvez material no jogador |
| Velocidade | `speed_multiplier_until` validado pelo servidor | Ajustar velocidade em `PlayerLocal` por RPC confirmado |

Para dano dobrado, a implementação é mais segura porque o dano já é calculado no servidor. Para velocidade, o cliente controla movimento, então o servidor precisa enviar a autorização e idealmente validar abuso depois.

## Uso Dos Vídeos Encontrados

Os links de YouTube encontrados podem ajudar visualmente, mas foram classificados como secundários porque não há garantia de código textual acessível para consulta rápida. Use esses vídeos apenas para inspiração de cena/editor, não como base principal da implementação.

Links candidatos:

1. <https://www.youtube.com/watch?v=WSoluV_8ITU>
2. <https://www.youtube.com/watch?v=34AuhpD1EOg>
3. <https://www.youtube.com/watch?v=iwNQ2sqH2cw>
4. <https://www.youtube.com/watch?v=W9NO27q6m7I>

## Ordem Recomendada De Estudo E Implementação

1. Ler `Area3D` e `Timer` para implementar plataforma quebradiça, jump pad e Rei do Pedaço.
2. Implementar plataforma quebradiça primeiro, porque é discreta e fácil de replicar.
3. Implementar pulo duplo em `PlayerLocal`, sem mexer no protocolo de rede inicialmente.
4. Implementar jump pad com resposta local e validação server-side simples.
5. Implementar Rei do Pedaço com `Area3D` no servidor e RPC de HUD.
6. Expandir pickups para arma/munição usando o sistema existente.
7. Só depois atacar plataforma móvel, começando por movimento determinístico simples.

## Observação Para O Texto Do TCC

Ao citar essas referências, deixar claro que os tutoriais ensinam primitivas de Godot, enquanto a implementação final adapta essas primitivas para uma arquitetura cliente/servidor autoritativa. Essa distinção é importante porque a maior parte dos tutoriais de Godot pressupõe um projeto single-player ou uma cena única, diferente da divisão atual entre `initial_project/Server` e `initial_project/Client`.
