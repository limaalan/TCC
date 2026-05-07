# Comparativo Entre Proposta E Implementação Atual

## Resumo

A implementação atual já cobre o núcleo de um FPS multiplayer em arena: conexão cliente-servidor, lobby rápido, movimentação em primeira pessoa, times, armas, dano, vida, respawn, placar, pickups, granadas, HUD e tela final. O maior desvio em relação ao `TCC.md` é arquitetural: a proposta descreve P2P com hospedeiro e `MultiplayerSynchronizer`, enquanto o código atual usa servidor separado autoritativo com RPCs, snapshots e interpolação manual.

O estado atual é mais próximo de um protótipo jogável de mata-mata em equipe do que do escopo completo proposto, que inclui três modos de jogo, plataformas especiais, armas específicas, munição limitada, powerups temporários, criação de partida configurável, suporte a controle e exportação final.

## Tabela De Funcionalidades

| Item proposto no TCC | Estado atual | Evidência no projeto | Lacuna principal |
| --- | --- | --- | --- |
| Jogo 3D multijogador FPS estilo arena | Implementado parcialmente | Client/Server separados, mapa 3D farm, jogadores FPS | Escopo ainda limitado a partidas pequenas e mapa hardcoded |
| Jogadores em times azul e vermelho | Implementado | `spawn_players()` alterna times e spawns; HUD mostra placar azul/vermelho | Times não são configuráveis |
| Conexão via rede | Implementado | `ENetMultiplayerPeer` em client e server | Cliente fixa `127.0.0.1`; falta tela para IP/host |
| Hospedeiro cria partida e define opções | Não implementado | Servidor separado inicia automaticamente | Falta menu de criar partida e configuração de tempo, vidas, pontuação e modo |
| Quick play ou entrar em partida | Implementado parcialmente | Menu chama `Server.try_connect_client_to_lobby()` | Não há lista de salas ou conexão por IP configurável |
| Movimento para frente, trás e lados | Implementado | `PlayerLocal.move()` usa input vector | Sem suporte a gamepad |
| Corrida | Implementado | `sprint_speed` com ação `sprint` | Sem stamina ou feedback específico |
| Pulo | Implementado | `jump_velocity` em `PlayerLocal` | Nenhum |
| Pulo duplo | Não implementado | Não há contador de pulos no ar | Implementar segunda carga de pulo antes de tocar o chão |
| Mira com mouse | Implementado | `look_around()` rotaciona corpo e cabeça | Sem analógico direito/gamepad |
| Disparo contra adversários | Implementado | Cliente envia tiro; servidor calcula raycast e dano | Munição e troca dinâmica de armas não existem |
| Todos possuem arma padrão infinita | Parcial | Pistol existe e auto-seleção usa arma 0 | Não há regra explícita de arma padrão mais armas coletáveis |
| Armas coletáveis no cenário | Não implementado | Arma é escolhida em UI antes do spawn | Criar pickup de arma e inventário/munição |
| Munição limitada para armas fortes | Não implementado | Armas possuem cooldown, mas não munição | Adicionar munição server-side e UI |
| Pistola | Implementado | `weapon_pistol.tscn`, `WeaponConfig` id 0 | Nenhum essencial |
| Rifle automático | Implementado como SMG | `weapon_smg.tscn`, `is_automatic = true` | Renomear/ajustar se o TCC exigir rifle em vez de SMG |
| Canhão laser | Não implementado | Não há weapon id para laser | Criar hitscan preciso com dano alto e cooldown maior |
| Lança-foguetes | Não implementado | Não há weapon id para foguete | Reaproveitar base de granada para projétil explosivo |
| Granadas | Implementado como funcionalidade extra | `c_try_throw_grenade`, `Grenade`, pickups de granada | Não faz parte da lista original de armas, mas é coerente com arena shooter |
| Pontos de vitalidade | Implementado | `MAX_HEALTH`, `change_health`, health bar | Nenhum essencial |
| Vidas limitadas | Não implementado | Respawn ocorre após cooldown sem contador de vidas | Adicionar `lives_left` por jogador/time e fim por eliminação |
| Pontos de nascimento | Implementado | `SpawnPoints` no mapa server-side e client-side | Spawns dependem de nomes `Blue` e `Red` |
| Coleta de vida | Implementado | `HealthPickup` cura e entra em cooldown | Quantidade de cura hardcoded |
| Coleta de vidas | Não implementado | Não há pickup ou contador de vidas | Só implementar se vidas limitadas forem mantidas no escopo |
| Melhoria temporária de dano | Não implementado | Não há estado de powerup de dano | Criar buff server-side com duração e multiplicador |
| Melhoria temporária de velocidade | Não implementado | Velocidade é fixa no cliente local | Buff precisa ser autorizado e replicado pelo servidor |
| Plataforma fixa/suspensa | Parcial | O mapa possui geometria e elevações estáticas | Não há mecânica específica de plataforma como entidade de gameplay |
| Plataforma móvel | Não implementado | Não há script de plataforma móvel sincronizada | Criar movimento server/client determinístico ou replicado |
| Plataforma quebradiça | Não implementado | Não há script ou cena de plataforma quebradiça | Criar trigger, timer, esconder/colidir e respawn |
| Plataforma de impulso | Não implementado | Não há jump pad | Criar Area3D que aplica impulso ao jogador |
| Modo capture a bandeira | Não implementado | Não há flag, base ou score zone | Criar entidade flag, bases, carregar/devolver/capturar |
| Modo mata-mata em equipe | Implementado parcialmente | Pontos por mortes, tempo e fim por score | Falta vidas limitadas e configuração pré-partida |
| Modo rei do pedaço | Não implementado | Não há área neutra ou pontuação por presença | Criar Area3D central e timer de controle por time |
| Menu principal | Implementado | `ui/main_menu/main_menu.tscn` | Sem fluxo de criar/entrar por IP |
| Menu de pausa/ESC | Não implementado como menu | ESC apenas libera mouse | Criar overlay com voltar ao menu e sair |
| Tela de seleção de arma | Implementado, embora não estivesse exatamente na proposta | `WeaponSelectionUI` | Integrar com pickups/munição se armas forem coletáveis |
| HUD de vida/placar/tempo | Implementado | `hud.tscn`, `match_info_ui.gd` | Falta ammo, vidas, modo, objetivos e mensagens de captura/controle |
| Tela final com estatísticas | Implementado | `match_end_info_ui.gd` | Poderia mostrar vencedor explicitamente |
| Arte cartunesca/colorida | Parcial | Mapa farm, personagem, materiais, armas e FX | Ainda precisa polimento consistente com a referência de arte |
| Música e efeitos sonoros | Parcial | `AudioManager` toca música de menu e partida | Falta SFX de tiro, passos, UI, pickups e pontuação |
| Exportação PC | Não implementado | Não há `export_presets.cfg` | Criar preset e validar build final |
| Testes LAN/Internet | Não verificado por código | `TODO.md` cita testes em máquinas e redes diferentes | Executar testes manuais documentados |

## Diferenças Técnicas Importantes

| Tema | Proposta no TCC | Implementação atual | Recomendação |
| --- | --- | --- | --- |
| Arquitetura de rede | P2P com jogador hospedeiro | Servidor Godot separado e autoritativo | Manter servidor autoritativo e atualizar o texto do TCC para refletir a decisão |
| Sincronização | `MultiplayerSynchronizer` e RPC | RPCs manuais, snapshots, histórico e interpolação | Documentar como técnica própria usada no resultado final |
| Escala | Vários jogadores | Servidor aceita até 64 conexões, mas matchmaking limita lobby a 2 jogadores | Aumentar só depois de estabilizar modos e spawns |
| Configuração de partida | Usuário define opções antes da partida | Constantes hardcoded no servidor | Implementar `MatchConfig` antes dos modos extras |
| Mapa planejado | Protótipo inspirado em Facing Worlds/CTF | Mapa farm com spawns e pickups | Decidir se o mapa farm será o mapa final ou se haverá mapa específico de CTF |

## Estado Geral Por Área

| Área | Situação | Observação |
| --- | --- | --- |
| Networking | Bom para protótipo | Já há arquitetura autoritativa, clock sync, snapshots e lag compensation |
| Gameplay básico | Bom para mata-mata simples | Movimento, tiros, dano, respawn, score e granadas existem |
| Modos de jogo | Baixo | Só existe mata-mata em equipe simplificado |
| Conteúdo de arena | Médio | Há armas, pickups e mapa, mas faltam plataformas especiais e powerups |
| Interface | Médio | Loop principal existe, mas falta criar partida, IP, configurações e pause menu |
| Arte e áudio | Parcial | Há modelos, mapa e música; faltam SFX e polimento final |
| Entrega final | Baixo | Falta export preset, checklist de testes e build final |
