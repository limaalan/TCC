# Plano De Refatoração Técnica

## Objetivo

Este documento propõe refatorações para aumentar legibilidade, reduzir acoplamento implícito entre `initial_project/Client` e `initial_project/Server` e facilitar a implementação de plataformas especiais, novos modos, pickups, munição, armas e powerups.

O foco não é reescrever o projeto. A recomendação é estabilizar os contratos e centralizar dados aos poucos, começando pelas áreas que hoje mais dependem de "funcionar na base da fé": `Dictionary` sem schema, chaves string repetidas, enums duplicados, `call_group()` com strings, IDs inteiros mágicos e configuração espalhada em scripts.

## Diagnóstico Resumido

| Problema | Evidência no projeto | Risco prático |
| --- | --- | --- |
| Contratos de rede implícitos | `Client/server/lobby.gd` cria `playerState` com `"pos"`, `"rot_y"`, `"rot_x"`, `"anim"`; `Server/server/lobby.gd` consome essas chaves diretamente | Uma chave errada quebra em runtime, sem aviso no editor |
| `world_state` opaco | `Server/server/lobby.gd` usa `{"ps": {}, "t": 0.0, "gr": {}}`; cliente espera as mesmas abreviações | Difícil entender, validar e evoluir para plataformas, objetivos e munição |
| Enums duplicados | `PickupTypes` existe no Client e no Server em arquivos diferentes | Se a ordem divergir, `int` recebido passa a significar outra coisa |
| IDs mágicos de time/arma | `team == 0`, `weapon_id == 2`, botões enviam `0`, `1`, `2` | Código fica pouco legível e fácil de quebrar ao adicionar arma/time/modo |
| Configuração de arma espalhada | Server tem dano/precisão em `WeaponConfig`; Client tem cena, cooldown, SFX e recoil em scripts separados | Para ajustar uma arma, é preciso lembrar vários lugares |
| Strings de grupo e método | `call_group("Lobby", "local_shot_fired")`, `call_group("PlayerLocal", "set_procecess")` | Renomear grupo/método quebra silenciosamente; typo vira contrato permanente |
| Caminhos hardcoded | Mapa, players, pickups, FX, telas e áudio usam `res://...` em vários scripts | Trocar mapa/arma/tela exige busca manual |
| Estado interno enviado para UI | `s_end_match(client_data)` envia o dicionário interno do lobby | A UI depende de campos adicionados dinamicamente no servidor |
| Node names como IDs de rede | Pickups e granadas usam `name` como chave de sincronização | Renomeação automática ou colisão de nomes pode quebrar associação |
| Duplicação de pose/animação | `PlayerRemote` e `ServerPlayerDummy` repetem nomes de bones e escalares | Hitbox server-side e visual client-side podem divergir |

## Práticas Profissionais Aplicáveis Ao Godot

| Prática | Como o Godot recomenda | Aplicação neste projeto |
| --- | --- | --- |
| Static typing | Tipos em variáveis, parâmetros, retornos, arrays e dictionaries ajudam autocomplete, leitura e erros antecipados | Tipar progressivamente RPC handlers, estados, registries, configs e scripts de gameplay |
| Warning system | Avisos de GDScript podem revelar acessos inseguros e podem virar erro em áreas críticas | Ativar warnings primeiro em scripts novos e contratos, depois expandir |
| `Resource` customizado | Resources são containers de dados editáveis no Inspector, serializáveis em `.tres` e melhores que JSON/CSV para dados do jogo | `WeaponData`, `PickupData`, `GrenadeData`, `MatchConfig`, `MapData`, `AudioEventData` |
| Autoloads/registries | Autoloads são úteis para dados persistentes e acesso global, mas não devem virar depósito de tudo | `WeaponRegistry`, `PickupRegistry`, `MapRegistry`, `GameConfig`, `AudioManager` |
| `class_name` | Registra tipos globais e melhora autocomplete/Inspector | Criar tipos nomeados para configs, payload helpers e componentes de mapa |
| Exports tipados | `@export var resource: WeaponData` limita o Inspector ao tipo correto | Configurar armas, pickups, mapas e spawns sem string/path manual no script |
| Groups com documentação | Groups são úteis para desacoplar, mas são convenções baseadas em nome | Manter onde há muitos receptores; substituir ou centralizar onde há um único alvo |
| RPC com payload serializável | RPC não serializa `Object` ou `Callable`; `Resource`/classes não devem ser enviados diretamente | Usar `Dictionary`/Array/primitivos na rede, mas com factories, validators e versão |

Observações importantes:

- `Dictionary` tipado em GDScript ajuda parcialmente, mas não resolve schema aninhado. `Dictionary[String, Variant]` ainda não garante que existe `"pos"` nem que `"pos"` é `Vector3`.
- Enum em GDScript continua sendo `int`; uma variável tipada como enum melhora leitura, mas valor recebido da rede ainda precisa ser validado.
- Para payloads frequentes como `world_state`, evite criar objetos `RefCounted` por pacote se isso virar custo. Use funções estáticas de schema e validação. Para payloads raros, como fim de partida ou spawn, objetos DTO locais com `to_dict()` e `from_dict()` são aceitáveis.

## Ranking Benefício Versus Complexidade

Escala: benefício `1` baixo até `5` alto; complexidade `1` baixa até `5` alta. A prioridade considera impacto nas novas funcionalidades e risco de regressão.

| Rank | Refactor | Benefício | Complexidade | Prioridade | Motivo |
| --- | --- | --- | --- | --- | --- |
| 1 | Criar schemas/factories/validators para payloads de rede | 5 | 2 | P0 | Ataca o maior risco: contratos implícitos por `Dictionary` |
| 2 | Centralizar enums e constantes compartilhadas | 5 | 2 | P0 | Remove `team == 0`, `weapon_id == 2`, strings de chaves e tipos duplicados |
| 3 | Criar processo simples para sincronizar scripts compartilhados Client/Server | 5 | 3 | P0 | Evita divergência entre projetos separados |
| 4 | Refatorar armas para `WeaponData`/registry, incluindo áudio e cooldown | 5 | 3 | P1 | Facilita munição, pickups de arma, laser, foguete e balanceamento |
| 5 | Trocar RPCs longos por DTOs versionados em eventos críticos | 5 | 3 | P1 | Evita quebra por ordem de parâmetros e permite evolução incremental |
| 6 | Criar `MatchConfig` e `MapData` | 4 | 2 | P1 | Necessário para modos, mapas, tempo, score, vidas e UI de partida |
| 7 | Centralizar pickups, granada e powerups em configs | 4 | 3 | P1 | Reduz duplicação e prepara munição, powerups e plataformas especiais |
| 8 | Substituir strings de grupos/métodos por constantes e sinais/autoloads onde fizer sentido | 4 | 2 | P1 | Diminui falhas silenciosas em UI, HUD e fluxo local |
| 9 | Criar `Map.gd` e `PlayerSpawnPoint.gd` tipados | 4 | 2 | P1 | Remove dependência de nomes como `BluePlayerSpawnPoint` e `Pickups` |
| 10 | Introduzir tipagem e warnings gradualmente | 4 | 2 | P1 | Melhora autocomplete e detecta acessos inseguros sem grande arquitetura |
| 11 | Usar IDs explícitos de entidade de rede em pickups/granadas/plataformas | 4 | 3 | P2 | Importante para plataformas quebradiças/móveis e objetos replicados |
| 12 | Separar dados de fim de partida em payload próprio | 3 | 2 | P2 | Desacopla UI de `client_data` interno |
| 13 | Centralizar `ScenePaths`, `InputActions`, `AnimationNames`, `PhysicsLayers`, `AudioBuses` | 3 | 1 | P2 | Baixo custo, melhora leitura e reduz typo |
| 14 | Extrair `CharacterPoseConfig` compartilhado | 3 | 2 | P2 | Evita divergência entre visual remoto e dummy de hitbox |
| 15 | Criar checks manuais/automatizados de simetria RPC | 3 | 3 | P2 | Bom para longo prazo, mas não bloqueia as features imediatas |

## Refactors Recomendados

### 1. Schemas De Rede Versionados

Problema atual: o contrato real está espalhado entre quem monta e quem consome `Dictionary`. Exemplo: `Client/server/lobby.gd` monta `playerState` com `"pos"`, `"rot_y"`, `"rot_x"`, `"anim"`; `Server/server/lobby.gd`, `Client/player/remote/player_remote.gd` e `Server/player/player_server_dummy.gd` acessam essas chaves por conhecimento prévio.

Recomendação: criar helpers espelhados em Client e Server, por exemplo `res://shared/net/net_keys.gd` e `res://shared/net/net_payloads.gd`.

Exemplo de chaves:

```gdscript
class_name NetKeys
extends RefCounted

const VERSION := "v"

const POS := "pos"
const ROT_Y := "rot_y"
const ROT_X := "rot_x"
const ANIM := "anim"
const ANIM_POS := "anim_pos"

const WORLD_PLAYERS := "ps"
const WORLD_TIME_MS := "t"
const WORLD_GRENADES := "gr"
const TRANSFORM := "tform"

const DISPLAY_NAME := "display_name"
const KILLS := "kills"
const DEATHS := "deaths"
const TEAM := "team"
const WEAPON_ID := "weapon_id"
```

Exemplo de factory/validator:

```gdscript
class_name NetPayloads
extends RefCounted

const PLAYER_STATE_VERSION := 1

static func make_player_state(pos: Vector3, rot_y: float, rot_x: float, anim: StringName) -> Dictionary:
	return {
		NetKeys.VERSION: PLAYER_STATE_VERSION,
		NetKeys.POS: pos,
		NetKeys.ROT_Y: rot_y,
		NetKeys.ROT_X: rot_x,
		NetKeys.ANIM: String(anim),
	}

static func is_player_state(data: Dictionary) -> bool:
	return (
		data.get(NetKeys.VERSION) == PLAYER_STATE_VERSION
		and data.get(NetKeys.POS) is Vector3
		and data.get(NetKeys.ROT_Y) is float
		and data.get(NetKeys.ROT_X) is float
		and data.get(NetKeys.ANIM) is String
	)
```

Como migrar sem quebrar tudo:

1. Criar `NetKeys` e `NetPayloads` nos dois projetos sem alterar comportamento.
2. Trocar primeiro `create_player_data()` para usar `NetPayloads.make_player_state()`.
3. Trocar acessos diretos como `playerState.pos` por `playerState[NetKeys.POS]` ou helpers de leitura.
4. Adicionar `is_player_state()` nos pontos de entrada do servidor: `c_send_player_state`, `c_shot_fired`, `c_try_throw_grenade`.
5. Adicionar `push_warning()` ou `push_error()` quando payload inválido chegar, mas retornar sem travar.

Critério de pronto:

- Nenhuma chave de `player_state`, `world_state`, `grenade_state` ou `end_match` aparece como literal fora dos helpers.
- Todo RPC que recebe `Dictionary` valida o mínimo necessário antes de acessar.
- Payloads novos incluem versão `v`.

### 2. Enums E Constantes Compartilhadas

Problema atual: existem IDs mágicos e enums duplicados. Exemplos: `PickupTypes` em Client e Server; armas `0`, `1`, `2`; times `0`, `1`; tipos de hit `0`, `1`; layers físicas `4`, `16`.

Recomendação: criar um script de contrato comum, por exemplo `res://shared/game_enums.gd`, copiado de forma idêntica para Client e Server.

Conteúdo sugerido:

```gdscript
class_name GameEnums
extends RefCounted

enum Team {
	BLUE = 0,
	RED = 1,
}

enum WeaponId {
	PISTOL = 0,
	SMG = 1,
	SHOTGUN = 2,
}

enum PickupType {
	HEALTH = 0,
	GRENADE = 1,
	WEAPON = 2,
	AMMO = 3,
	DAMAGE_POWERUP = 4,
	SPEED_POWERUP = 5,
}

enum HitFxType {
	ENVIRONMENT = 0,
	PLAYER = 1,
}

enum GameMode {
	TEAM_DEATHMATCH = 0,
	KING_OF_THE_HILL = 1,
	CAPTURE_THE_FLAG = 2,
}

enum PlatformState {
	READY = 0,
	BREAKING = 1,
	BROKEN = 2,
}
```

Também criar constantes locais no Client:

```gdscript
class_name ClientNames
extends RefCounted

const GROUP_LOBBY := &"Lobby"
const GROUP_PLAYER_LOCAL := &"PlayerLocal"
const GROUP_LOCAL_GAME_SCENE_MANAGER := &"LocalGameSceneManager"
const GROUP_WEAPON_SELECTION_UI := &"WeaponSelectionUI"
const GROUP_MATCH_INFO_UI := &"MatchInfoUi"
const GROUP_CAMERA_SHAKE := &"CameraShakeComponent"
const GROUP_HEALTH_CHANGE_MASK := &"HealthChangeMask"
const GROUP_GRENADE_PROMPTS := &"GrenadePromptsControl"

const INPUT_SHOOT := &"shoot"
const INPUT_JUMP := &"jump"
const INPUT_SPRINT := &"sprint"
const INPUT_THROW_GRENADE := &"throw_grenade"

const ANIM_IDLE := &"Idle"
const ANIM_AIR := &"Jump_Idle"
const ANIM_WALK_SHOOT := &"Walk_Shoot"
const ANIM_RUN_SHOOT := &"Run_Shoot"
```

Critério de pronto:

- Não há `team == 0`; há `team == GameEnums.Team.BLUE`.
- Não há `weapon_selected(2)`; há `weapon_selected(GameEnums.WeaponId.SHOTGUN)`.
- Não há `call_group("Lobby", ...)`; há `call_group(ClientNames.GROUP_LOBBY, ...)` ou substituição por sinal/referência.

### 3. Sincronização De Scripts Compartilhados Entre Projetos

Problema atual: Client e Server são projetos Godot separados. Isso é correto para arquitetura, mas cria risco de drift em contratos duplicados.

Recomendação: não tentar fazer `res://` cruzado entre os projetos. Criar uma fonte comum fora dos dois projetos Godot e copiar para ambos.

Estrutura sugerida:

```text
initial_project/shared_src/
  game_enums.gd
  net_keys.gd
  net_payloads.gd
  network_config.gd
initial_project/Client/shared/
  game_enums.gd
  net_keys.gd
  net_payloads.gd
  network_config.gd
initial_project/Server/shared/
  game_enums.gd
  net_keys.gd
  net_payloads.gd
  network_config.gd
```

Processo prático:

1. Editar apenas `initial_project/shared_src`.
2. Rodar um script simples para copiar para Client e Server.
3. Antes de testar, verificar se os arquivos copiados são idênticos.

Alternativa mais simples para curto prazo: duplicar manualmente, mas adicionar no topo de cada arquivo um comentário de alerta:

```gdscript
# Keep this file identical in Client/shared and Server/shared.
# Source of truth: initial_project/shared_src/net_keys.gd
```

Critério de pronto:

- Existe uma fonte de verdade para enums e chaves de rede.
- Toda alteração de contrato começa pelos arquivos compartilhados.
- O README ou este plano documenta o processo de cópia.

### 4. `WeaponData` E Registry De Armas

Problema atual: a arma é configurada em vários lugares.

| Dados | Local atual |
| --- | --- |
| Dano, precisão e projéteis | `Server/game/weapon_config.gd` |
| Cena visual | `Client/player/weapons/weapon_holder.gd` |
| Automática e cooldown | `Client/player/weapons/weapon.gd` e cenas das armas |
| SFX | `Client/player/weapons/weapon.gd` e `Client/game/audio_manager.gd` |
| Recoil e camera shake | `Client/player/local_weapon_holder.gd` |
| Botões da UI | `Client/ui/weapon_selection/weapon_selection_ui.gd` |

Recomendação: separar dados autoritativos de gameplay e dados de apresentação, mas usar o mesmo `WeaponId`.

Server:

```gdscript
class_name WeaponGameplayData
extends Resource

@export var id: GameEnums.WeaponId
@export var display_name: StringName
@export var damage: int
@export_range(0.0, 1.0) var accuracy := 1.0
@export var projectiles := 1
@export var shot_cooldown := 0.3
@export var max_ammo := 0
@export var uses_ammo := false
```

Client:

```gdscript
class_name WeaponPresentationData
extends Resource

@export var id: GameEnums.WeaponId
@export var display_name: StringName
@export var weapon_scene: PackedScene
@export var shoot_sfx: AudioStream
@export var shot_cooldown := 0.3
@export var is_automatic := false
@export var recoil_rotation_degrees := 15.0
@export var recoil_position_z := 0.05
@export var camera_shake_amount := 0.1
@export var pitch_randomness := 0.1
```

Registry:

```gdscript
class_name WeaponRegistry
extends Node

@export var weapons: Array[WeaponPresentationData] = []

var _by_id: Dictionary[int, WeaponPresentationData] = {}

func _ready() -> void:
	for weapon in weapons:
		_by_id[weapon.id] = weapon

func get_weapon(id: int) -> WeaponPresentationData:
	return _by_id.get(id)
```

Como isso resolve a sua observação sobre áudio:

- `Weapon.play_shoot_fx()` não precisa de `match weapon_id`.
- A arma recebe seu `WeaponPresentationData` ao instanciar.
- O SFX, pitch, recoil e shake ficam junto da configuração da arma.
- Para adicionar laser ou foguete, cria-se um `.tres` e uma cena, não um novo `match` espalhado.

Critério de pronto:
- `WeaponConfig.get_weapon_data()` no Server retorna `WeaponGameplayData`, não `Dictionary` livre.
- `WeaponHolder.instantiate_weapon()` consulta `WeaponRegistry`, não faz `match` em IDs.
- `AudioManager.play_sfx()` aceita `AudioStream` direto ou um `AudioEventData`, reduzindo dependência de enum para tiro.

### 5. DTOs Versionados Para RPCs Críticos

Problema atual: RPCs como `s_spawn_player(client_id, spawn_tform, team, player_name, weapon_id, auto_freeze)` dependem da ordem dos parâmetros. Se um lado mudar a ordem ou adicionar um campo, quebra.

Recomendação: para eventos críticos e pouco frequentes, trocar parâmetros longos por `Dictionary` versionado.

Exemplo:

```gdscript
static func make_spawn_player(
	client_id: int,
	spawn_tform: Transform3D,
	team: int,
	player_name: String,
	weapon_id: int,
	auto_freeze: bool
) -> Dictionary:
	return {
		NetKeys.VERSION: 1,
		"client_id": client_id,
		"spawn_tform": spawn_tform,
		NetKeys.TEAM: team,
		"player_name": player_name,
		NetKeys.WEAPON_ID: weapon_id,
		"auto_freeze": auto_freeze,
	}
```

Priorizar DTOs para:

| RPC | Motivo |
| --- | --- |
| `s_spawn_player` | Muitos parâmetros e campos semânticos |
| `s_end_match` | Hoje envia `client_data` interno |
| `s_spawn_pickup` | Vai crescer com arma, munição, powerup e cooldown |
| `s_update_hill_state` futuro | Novo modo precisa de estado claro |
| `s_set_platform_state` futuro | Plataformas quebradiças/móveis precisam de ID e estado |

Para `s_send_world_state`, manter `Dictionary` compacto por enquanto, mas centralizar chaves e validação mínima. Esse payload é frequente e deve ser tratado com cuidado de performance.

### 6. `MatchConfig` E `MapData`

Problema atual: regras e mapa estão hardcoded em `Server/server/lobby.gd` e `Client/server/lobby.gd`. Isso atrapalha novos modos e seleção de mapa.

Recomendação:

```gdscript
class_name MatchConfig
extends Resource

@export var mode: GameEnums.GameMode
@export var time_limit_sec := 300
@export var score_to_win := 2
@export var lives_per_player := 0
@export var max_players := 2
@export var map_id: StringName = &"farm"
```

```gdscript
class_name MapData
extends Resource

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var supports_team_deathmatch := true
@export var supports_king_of_the_hill := false
@export var supports_capture_the_flag := false
```

Como Client e Server têm cenas diferentes, cada projeto tem seu próprio `MapRegistry`, mas ambos usam o mesmo `map_id`.

Critério de pronto:

- Server não faz `load("res://maps/server_map_farm.tscn")` diretamente; usa `MapRegistry.get_map(config.map_id)`.
- Client não carrega `res://maps/map_farm.tscn` fixo; recebe `map_id` e resolve localmente.
- `MATCH_LENGTH_SEC` e `TEAM_SCORE_TO_WIN` deixam de ser constantes soltas do lobby e passam para `MatchConfig`.

### 7. Configs Para Pickups, Granadas E Powerups

Problema atual: pickup de vida cura `75`, cooldown está no script/cena, mesh do pickup está em `match` no Client, granada tem gameplay no Server e áudio no Client espalhados.

Recomendação:

| Config | Campos sugeridos | Uso |
| --- | --- | --- |
| `PickupData` | `type`, `amount`, `cooldown`, `client_mesh`, `ready_material`, `not_ready_material`, `pickup_sfx` | Vida, granada, munição, arma, powerup |
| `GrenadeData` | `lifetime`, `throw_impulse`, `damage_radius`, `max_damage`, `spawn_offset`, `throw_sfx`, `explode_sfx` | Granada atual e foguete futuro |
| `PowerupData` | `type`, `duration`, `multiplier`, `hud_icon`, `world_material` | Dano dobrado e velocidade |

Critério de pronto:

- `PickupTypes` não fica dentro do script `Pickup`; fica em `GameEnums`.
- Efeito de pickup é resolvido por `PickupRegistry`.
- Server decide efeito autoritativo; Client apenas usa a parte visual/audio da config.

### 8. Reduzir Strings De `call_group()`

Problema atual: grupos são usados como interface implícita. Isso é aceitável em Godot, mas precisa de constantes e documentação. Onde há só um alvo, referência direta/autoload é mais clara.

Exemplos atuais:

| Chamada | Problema |
| --- | --- |
| `call_group("Lobby", "local_shot_fired")` | String de grupo e método |
| `call_group("PlayerLocal", "set_procecess", true)` | Método com typo virou contrato |
| `call_group("LocalGameSceneManager", "change_scene", path)` | Há um único scene manager; autoload/referência seria mais claro |
| `call_group("MatchInfoUi", "update_score", ...)` | UI depende de grupo e método por string |

Plano pragmático:

1. Criar constantes para nomes de grupos e métodos chamados por grupo.
2. Manter grupos para componentes realmente múltiplos, como prompts, overlays e efeitos.
3. Trocar singletons de fato por autoloads ou referências tipadas, começando por scene manager e lobby local.
4. Renomear `set_procecess` para `set_processing_enabled` em um refactor pequeno e atualizar a chamada correspondente no mesmo commit.

Critério de pronto:

- Strings de grupos não aparecem inline.
- Métodos chamados por string estão documentados em um arquivo de interface ou foram substituídos por sinal/referência.

### 9. Tipagem, Warnings E Acessos Seguros

Problema atual: muitos métodos aceitam `Dictionary` livre, `weapon_id` como `int`, `team` como `int` e acessam propriedades dinâmicas. Isso reduz autocomplete e joga erros para runtime.

Plano gradual:

| Passo | Ação |
| --- | --- |
| 1 | Tipar retornos `-> void` em scripts novos e refactors |
| 2 | Tipar parâmetros de RPC e callbacks onde ainda não estiverem tipados |
| 3 | Tipar arrays/dictionaries locais, como `Array[Pickup]`, `Dictionary[int, PlayerRemote]` quando possível |
| 4 | Ativar warnings de declarações sem tipo e acesso inseguro em áreas novas |
| 5 | Usar `is`/casts explícitos em callbacks de física e `get_node()` |

Não tentar tipar tudo de uma vez. Começar por `shared`, `server/lobby.gd`, `client/server/lobby.gd`, configs e registries.

### 10. Scripts De Mapa E Spawn Points

Problema atual: o servidor busca `map.get_node("SpawnPoints")`, `map.get_node("Pickups")` e identifica time pelo prefixo do nome do spawn.

Recomendação:

```gdscript
class_name GameMap
extends Node3D

@export var spawn_points_root: Node3D
@export var pickups_root: Node3D
@export var objectives_root: Node3D
@export var special_platforms_root: Node3D
```

```gdscript
class_name PlayerSpawnPoint
extends Node3D

@export var team: GameEnums.Team
```

Benefício para novas features:

- Rei do Pedaço pode buscar `objectives_root`.
- Plataformas quebradiças/móveis podem ficar em `special_platforms_root`.
- CTF pode ter `FlagBase` com `@export var team`.
- Spawns não dependem de nomes `Blue...` e `Red...`.

### 11. IDs Explícitos Para Entidades De Rede

Problema atual: pickups e granadas usam `name` como chave de sincronização. Isso funciona no protótipo, mas fica frágil com plataformas, objetivos e objetos spawnados dinamicamente.

Recomendação:

```gdscript
class_name NetworkEntity
extends Node3D

@export var network_id: StringName
```

Para objetos dinâmicos, o servidor gera `network_id` explícito e envia ao cliente. O `Node.name` pode continuar igual para debug, mas deixa de ser o contrato.

Critério de pronto:

- RPCs recebem `network_id`, não `node.name` sem contexto.
- Cliente mantém dictionaries por `network_id`.
- Plataformas quebradiças e pickups usam o mesmo padrão.

### 12. Payload Próprio Para Fim De Partida

Problema atual: `s_end_match(end_client_data: Dictionary)` envia `client_data` inteiro, que é estrutura interna do servidor. A UI espera `display_name`, `kills`, `deaths` e `team`.

Recomendação:

```gdscript
{
	"v": 1,
	"blue_score": 2,
	"red_score": 1,
	"players": [
		{
			"client_id": 123,
			"display_name": "Alan",
			"team": GameEnums.Team.BLUE,
			"kills": 3,
			"deaths": 2,
		},
	],
}
```

Benefício:

- A UI deixa de depender de campos internos do lobby.
- O servidor pode mudar `client_data` sem quebrar tela final.
- Fica fácil adicionar vencedor, motivo da vitória e estatísticas por modo.

### 13. Pose, Bones E Animações

Problema atual: `Client/player/remote/player_remote.gd` e `Server/player/player_server_dummy.gd` repetem bones e escalares de rotação. Isso é perigoso porque o servidor usa dummy para hitbox/lag compensation e o cliente usa visual remoto.

Recomendação:

- Criar `CharacterRigConstants.gd` para nomes de bones e animações.
- Criar `CharacterPoseConfig.gd extends Resource` com escalares de pescoço, torso, abdômen e braço.
- Usar a mesma config nos dois projetos, copiada por `shared_src`.

Critério de pronto:

- Não há `skeleton.find_bone("Neck")` duplicado.
- `"Jump_Idle"` vira `AnimationNames.AIR`.
- O cálculo de pose pode continuar em cada script, mas usa os mesmos dados.

### 14. AudioManager Como Executor, Não Catálogo De Tudo

Problema atual: `AudioManager` já tem enums, mas também contém paths, `match`, bus string e resolve SFX de arma indiretamente. Há ainda um ponto para revisar: `set_music_volume(volume_linear)` chama `db_to_linear(volume_linear)` ao passar para `AudioServer.set_bus_volume_db()`, o que parece semanticamente invertido e merece verificação.

Recomendação:

- `AudioManager` deve tocar `AudioStream` ou `AudioEventData`.
- Catálogo de SFX genéricos pode ficar em `AudioLibrary`/Resource.
- SFX de arma fica em `WeaponPresentationData`.
- SFX de pickup fica em `PickupData`.
- SFX de granada fica em `GrenadeData`.
- Buses viram constantes `AudioBuses.SFX`, `AudioBuses.MUSIC`.

Exemplo:

```gdscript
class_name AudioEventData
extends Resource

@export var stream: AudioStream
@export var bus: StringName = &"SFX"
@export var volume_db := 0.0
@export var pitch_randomness := 0.0
@export var spatial := false
```

Assim `AudioManager` não precisa saber que `WeaponId.SHOTGUN` usa `shotgun_shot.ogg`; a arma sabe.

## Plano Incremental

### Fase 0: Regras Para Não Piorar

Aplicar imediatamente em código novo:

| Regra | Exemplo |
| --- | --- |
| Não criar nova chave string inline em payload de rede | Adicionar em `NetKeys` primeiro |
| Não criar novo ID inteiro solto | Adicionar em `GameEnums` primeiro |
| Não criar novo `match weapon_id` | Resolver via registry/config |
| Não criar novo `call_group()` com string literal | Usar constante ou sinal |
| Não acessar `Dictionary` recebido sem validar | Chamar validator ou `.get()` com fallback |

### Fase 1: Contratos E Enums Sem Mudar Gameplay

Tarefas:

1. Criar `shared/game_enums.gd`, `shared/net_keys.gd`, `shared/net_payloads.gd` em Client e Server.
2. Migrar `PickupTypes`, `Team`, `WeaponId`, `HitFxType` para `GameEnums`.
3. Trocar chaves de `player_state` e `world_state` por constantes.
4. Adicionar validators nos RPCs que recebem `Dictionary`.
5. Atualizar `04_referencias_tutoriais.md` ou este plano se alguma nova feature exigir payload novo.

Critério de pronto:

- O jogo deve funcionar igual antes e depois.
- Nenhum comportamento novo entra nessa fase.
- Teste manual mínimo: servidor + dois clientes, tiro, granada, pickup, fim de partida.

### Fase 2: WeaponData E PickupData

Tarefas:

1. Criar `WeaponGameplayData` no Server.
2. Criar `WeaponPresentationData` no Client.
3. Criar `WeaponRegistry` nos dois lados.
4. Migrar pistol, SMG e shotgun.
5. Mover SFX, cooldown, recoil e camera shake para config client-side.
6. Criar `PickupData` para vida e granada antes de adicionar munição/arma/powerup.

Critério de pronto:

- Ajustar dano/cooldown/SFX de uma arma exige alterar um `.tres` ou registry, não vários `match`.
- Adicionar nova arma exige criar config e cena, com pouca alteração em código.

### Fase 3: MatchConfig, MapData E Componentes De Mapa

Tarefas:

1. Criar `MatchConfig` no servidor.
2. Criar `MapData`/`MapRegistry` em Client e Server.
3. Criar `GameMap` com exports para spawns, pickups, objetivos e plataformas.
4. Criar `PlayerSpawnPoint` com `team` exportado.
5. Atualizar lobby para usar config e map registry.

Critério de pronto:

- Rei do Pedaço e plataformas especiais têm lugar claro no mapa.
- Cliente recebe `map_id` em vez de carregar farm fixo.

### Fase 4: Eventos, UI E Entidades De Rede

Tarefas:

1. Criar payload próprio para fim de partida.
2. Criar padrão de `network_id` para pickups, granadas e plataformas.
3. Substituir chamadas de grupo com um único alvo por referência/autoload.
4. Manter grupos apenas como interface intencional e documentada.

Critério de pronto:

- UI não depende de estrutura interna do lobby.
- Plataformas quebradiças e objetivos usam o mesmo padrão de ID dos pickups.

## Aplicação Direta Nas Novas Funcionalidades

| Funcionalidade nova | Refactors que mais ajudam |
| --- | --- |
| Pulo duplo | `InputActions`, `AnimationNames`, tipagem em `PlayerLocal` |
| Jump pad | `NetworkEntity`, payload `s_apply_jump_pad`, `GameMap.special_platforms_root` |
| Plataforma quebradiça | `NetworkEntity`, enum `PlatformState`, RPC DTO versionado, `GameMap.special_platforms_root` |
| Plataforma móvel | `MapData`, `NetworkEntity`, `PhysicsLayers`, config de trajetória |
| Munição | `WeaponGameplayData`, `WeaponPresentationData`, payload `s_update_ammo` |
| Pickup de arma | `WeaponId`, `PickupData`, `WeaponRegistry`, validator de pickup |
| Rei do Pedaço | `MatchConfig`, `GameMode`, `Team`, payload `HillState`, `GameMap.objectives_root` |
| Powerup de dano | `PickupData`, `PowerupData`, cálculo de dano centralizado no Server |
| Powerup de velocidade | `PowerupData`, payload de buff, validação server-side de velocidade |

## O Que Não Recomendo Fazer Agora

| Ideia | Por que evitar no curto prazo |
| --- | --- |
| Migrar tudo para `MultiplayerSynchronizer` | O projeto atual já tem snapshots, interpolação e lag compensation manuais; misturar modelos aumenta risco |
| Enviar `Resource` ou objetos customizados diretamente por RPC | RPC não serializa `Object`/`Callable`; transformar em `Dictionary` é inevitável para rede |
| Refactor big bang de todos os scripts | Alto risco de quebrar gameplay antes de adicionar features do TCC |
| Criar uma arquitetura genérica demais de eventos | Pode virar mais difícil que o problema original; usar sinais/autoloads só onde simplificar |
| Centralizar tudo em um único `Global.gd` | Troca strings soltas por um singleton gigante e difícil de manter |

## Referências Consultadas

| Tema | Referência | Aplicação |
| --- | --- | --- |
| Static typing | <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html> | Tipar scripts e entender limites de enums/dictionaries |
| Warning system | <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/warning_system.html> | Ativar avisos para acessos inseguros gradualmente |
| Resources | <https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html> | Usar `.tres` para dados de armas, pickups, mapas e configs |
| Exported properties | <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html> | Configurar Resources, enums e referências pelo Inspector |
| Autoloads | <https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html> | Registries e gerenciadores globais pontuais |
| Project organization | <https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html> | Organização por domínio e nomes `snake_case` |
| Scenes vs scripts | <https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html> | Usar cenas para entidades de jogo e scripts/resources para dados/contratos |
| Logic preferences | <https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html> | `preload`/`load`, inicialização e organização de recursos |
| Data preferences | <https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html> | Tradeoff entre `Dictionary`, `Array` e objetos tipados |
| Godot interfaces | <https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_interfaces.html> | Grupos como interfaces documentadas, casts e referências tipadas |
| Groups | <https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html> | Uso consciente de grupos e `call_group()` |
| High-level multiplayer | <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html> | Limites de RPC, confiabilidade, assinatura e serialização |

## Resultado Esperado

Depois dessas refatorações, adicionar uma feature nova deve seguir um fluxo mais previsível:

1. Definir IDs/enums no contrato compartilhado.
2. Definir dados em `Resource` quando for configuração de gameplay/visual/audio.
3. Definir payload versionado se houver rede.
4. Validar payload no endpoint que recebe.
5. Implementar regra no servidor e feedback no cliente.
6. Testar com checklist manual servidor + dois clientes.

O ganho principal é sair de um projeto que depende de memória e convenção informal para um projeto onde contratos, IDs e dados importantes têm nomes, tipos, validação e lugar claro.
