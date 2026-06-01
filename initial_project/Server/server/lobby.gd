extends Node3D
class_name Lobby
enum {IDLE, LOCKED, GAME, FINISHED}
var status:= IDLE
var callable_when_clients_ready : Callable
var waiting_players_ready:= false
# Este dicionário vai manter o estado de toda a partida ( tempo , pontuação ... )
# dentro da chave WORLD_PLAYERS estão os valores dos player states
var current_world_state := {NetKeys.WORLD_PLAYERS: {}, NetKeys.WORLD_TIME_MS: 0.0, NetKeys.WORLD_GRENADES: {}} 
var previous_world_states :Array[Dictionary] = []
var pickups :Array[Pickup] = []
var spawn_points :Array[PlayerSpawnPoint] = []
var objectives: Array[Node3D] = []
var hill_zones: Array[HillZone] = []
var grenades:= {} # chave : id granada , valor ela mesmo
var next_grenade_network_sequence := 0

const WORLD_STATE_SEND_FRAME :=3
const WORLD_STATES_TO_REMEMBER := 60
const RAYCAST_CHECK_DISTANCE := 100
const PHYSICS_LAYER_EXACT = 16
const PHYSICS_LAYER_HITBOX = 4 
const MAX_SHOT_RANDOM_DEGREES = 5
const DEATH_COOLDOWN_LENGTH := 5
const FINISHED_LOBBY_DELETE_DELAY_SEC := 0.5
const BaseGameMode = preload("res://game_modes/base_game_mode.gd")
const HillZone = preload("res://game_modes/objectives/hill_zone.gd")
const KingOfTheHillMode = preload("res://game_modes/king_of_the_hill_mode.gd")
const NetworkEntity = preload("res://shared/network_entity.gd")
const TeamDeathmatchMode = preload("res://game_modes/team_deathmatch_mode.gd")
const WeaponGameplayData = preload("res://game/weapon_gameplay_data.gd")

@export var match_config: MatchConfig

var client_data : Dictionary = {}
var ready_clients: Array[int] =[]
var server_players := {}
var match_time_left := 0
var is_pending_delete := false
var current_game_mode: BaseGameMode

var match_timer := Timer.new()

func _ready() -> void:
	set_physics_process(false)
	if match_config == null:
		match_config = MatchConfig.new()
	match_time_left = match_config.time_limit_sec
	add_child(match_timer)
	match_timer.timeout.connect(match_timer_sec_passed)

func queue_free_child(node: Node) -> void:
	if node == null:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.queue_free()

func get_match_map_scene() -> PackedScene:
	return MapRegistry.get_map_scene(match_config.map_id)

func clear_loaded_map() -> void:
	spawn_points.clear()
	pickups.clear()
	objectives.clear()
	hill_zones.clear()
	var loaded_map := get_node_or_null("Map")
	if loaded_map != null:
		queue_free_child(loaded_map)


func collect_map_objectives(map: Node) -> void:
	objectives.clear()
	hill_zones.clear()

	if not map is GameMap:
		push_warning("Loaded map '%s' is not a GameMap. Objectives will not be collected." % map.name)
		return

	var game_map: GameMap = map
	for objective in game_map.get_objectives():
		objectives.append(objective)

		if objective is HillZone:
			var hill_zone: HillZone = objective
			hill_zone.setup(self)
			hill_zones.append(hill_zone)

	if match_config.mode == GameEnums.GameMode.KING_OF_THE_HILL and hill_zones.is_empty():
		push_warning("Loaded map '%s' does not have any HillZone objectives." % map.name)


func get_objectives() -> Array[Node3D]:
	return objectives


func get_hill_zones() -> Array[HillZone]:
	return hill_zones


func get_primary_hill_zone() -> HillZone:
	if hill_zones.is_empty():
		return null

	return hill_zones[0]


func remove_player_from_objectives(client_id: int) -> void:
	for hill_zone in hill_zones:
		hill_zone.clear_player(client_id)

func get_connected_clients()-> Array[int]:
	var connected_client_ids : Array[int] = []
	for client_id in client_data.keys():
		if client_data.get(client_id)[NetKeys.CONNECTED]:
			connected_client_ids.append(client_id)
	return connected_client_ids
	

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames()% WORLD_STATE_SEND_FRAME == 0:
		current_world_state[NetKeys.WORLD_TIME_MS] = floori(Time.get_unix_time_from_system()*1000)
		update_grenades_in_world_state()
		for client_id in get_connected_clients():
			s_send_world_state.rpc_id( client_id, current_world_state) 
			
	while previous_world_states.size() >= WORLD_STATES_TO_REMEMBER:
		previous_world_states.pop_back()
		
	for client_id in server_players.keys():
		if not current_world_state[NetKeys.WORLD_PLAYERS].has(client_id):
			continue
		current_world_state[NetKeys.WORLD_PLAYERS][client_id][NetKeys.ANIM_POS] = server_players.get(client_id).real.animation_player.current_animation_position
	
	previous_world_states.push_front(current_world_state.duplicate(true))

	if status == GAME and current_game_mode != null:
		current_game_mode.physics_process(delta)
	
func update_grenades_in_world_state()->void:
	for grenade_id in grenades.keys():
		current_world_state[NetKeys.WORLD_GRENADES][grenade_id] = {NetKeys.TRANSFORM: grenades.get(grenade_id).transform}


func make_grenade_network_id(owner_id: int) -> StringName:
	next_grenade_network_sequence += 1
	return NetworkEntity.make_dynamic_id(NetworkEntity.GRENADE_PREFIX, owner_id, next_grenade_network_sequence)

@rpc ("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_word_state:Dictionary)->void:
	pass
	
func add_client(id:int, player_name:String)->void:
	client_data[id] = {
		NetKeys.DISPLAY_NAME: player_name,
		NetKeys.CONNECTED: true,
		NetKeys.KILLS: 0,
		NetKeys.DEATHS: 0,
	}
	
func remove_client(id:int)->void:
	client_data.get(id)[NetKeys.CONNECTED] = false # funciona em dicionários e arrays também
	check_players_ready()
	maybe_delete_empty_lobby()
	delete_player(id)
	check_both_teams_are_connected()
	
func delete_player(client_id:int)->void:
	remove_player_from_objectives(client_id)

	if server_players.has(client_id):
		server_players.get(client_id).real.queue_free()
		server_players.get(client_id).dummy.queue_free()
		server_players.erase(client_id)
		
		for connected_client_id in get_connected_clients():
			s_delete_player.rpc_id(connected_client_id, client_id)
	
@rpc("authority", "call_remote", "reliable")
func s_delete_player(client_id:int)->void:
	pass
	
func maybe_delete_empty_lobby()->void:
	for data in client_data.values():
		if data[NetKeys.CONNECTED]: #pelo menos um player conectado , faz nada
			return 
	Server.delete_lobby(self) # não não sobrou ninguém, deleta esse lobby

func check_both_teams_are_connected()->void:
	if status != GAME:
		return

	if not has_current_game_mode():
		return

	if current_game_mode.should_end_after_disconnect():
		end_match()
	
@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	var client_id =  multiplayer.get_remote_sender_id()
	if !client_id in client_data.keys() or client_id in ready_clients:
		return
	ready_clients.append(client_id)
	
	waiting_players_ready = true
	check_players_ready(start_loading_map)

func check_players_ready(maybe_callable = null) ->void:
	if not waiting_players_ready:
		return
	for maybe_ready_client in get_connected_clients():
		if not maybe_ready_client in ready_clients:
			return
	
	if maybe_callable is Callable:
		callable_when_clients_ready = maybe_callable
	
	callable_when_clients_ready.call()
	ready_clients.clear()
	waiting_players_ready = false

func start_loading_map():
	var map_scene := get_match_map_scene()
	if map_scene == null:
		push_error("Failed to load server map for map_id '%s'. Match loading aborted." % String(match_config.map_id))
		return

	clear_loaded_map()

	var map = map_scene.instantiate()
	map.name="Map"
	add_child(map, true)  #força nome 
	
	var spawn_point_holder = map.get_node_or_null("SpawnPoints")
	if spawn_point_holder == null:
		push_warning("Loaded map '%s' is missing SpawnPoints node." % map.name)
	else:
		for maybe_spawn_point in spawn_point_holder.get_children() :
			if maybe_spawn_point is PlayerSpawnPoint:
				var spawn_point: PlayerSpawnPoint = maybe_spawn_point
				spawn_points.append(spawn_point)
			else:
				push_warning("Ignoring non-PlayerSpawnPoint in SpawnPoints: %s" % maybe_spawn_point.name)

	if spawn_points.is_empty():
		push_warning("Loaded map '%s' does not have any valid PlayerSpawnPoint nodes." % map.name)
	
	
	var pickup_ids := {}
	var pickup_holder = map.get_node_or_null("Pickups")
	if pickup_holder != null :
		for maybe_pickup in pickup_holder.get_children() :
			if maybe_pickup is Pickup:
				var pickup: Pickup = maybe_pickup
				if not pickup.has_network_id():
					push_error("Ignoring pickup '%s': missing network_id." % pickup.name)
					continue

				var pickup_id := pickup.get_network_id()
				if pickup_ids.has(pickup_id):
					push_error("Ignoring pickup '%s': duplicate network_id '%s'." % [pickup.name, pickup_id])
					continue

				pickup_ids[pickup_id] = true
				pickup.lobby = self
				pickups.append(pickup)

	collect_map_objectives(map)
	
	for ready_client in ready_clients:
		s_start_loading_map.rpc_id(ready_client, match_config.map_id)
		
@rpc('authority', "call_remote", "reliable")
func s_start_loading_map(map_id: StringName):
	pass
	
@rpc ("any_peer", "call_local", "reliable")
func c_map_ready()->void:
	var client_id =  multiplayer.get_remote_sender_id()
	if !client_id in client_data.keys() or client_id in ready_clients:
		return
	ready_clients.append(client_id)
	
	for pickup in pickups:
		s_spawn_pickup.rpc_id(client_id, pickup.get_network_id(), pickup.get_pickup_type(), pickup.position)

	send_objective_visuals_to_client(client_id)
	
	waiting_players_ready = true
	check_players_ready(start_weapon_selection)
	#spawn_players()
	#await get_tree().create_timer(1).timeout
	#
	#for ready_client_id in ready_clients:
		#s_start_match.rpc_id(ready_client_id)
		#
	#ready_clients.clear()
	#set_physics_process(true)


		
@rpc("authority", "call_remote", "reliable")
func s_spawn_pickup(network_id:String, pickup_type:int , pos : Vector3)->void:
	pass


func send_objective_visuals_to_client(client_id: int) -> void:
	if match_config.mode != GameEnums.GameMode.KING_OF_THE_HILL:
		return

	for objective in objectives:
		if not objective is HillZone:
			continue

		var hill_zone: HillZone = objective
		var objective_visual_spawn := hill_zone.make_visual_spawn_payload()
		if not NetPayloads.is_objective_visual_spawn(objective_visual_spawn):
			continue

		s_spawn_objective_visual.rpc_id(client_id, objective_visual_spawn)


@rpc("authority", "call_remote", "reliable")
func s_spawn_objective_visual(objective_visual_spawn: Dictionary) -> void:
	pass

func get_spawn_points_for_team(team: int) -> Array[PlayerSpawnPoint]:
	var result: Array[PlayerSpawnPoint] = []

	for spawn_point in spawn_points:
		if spawn_point.team == team:
			result.append(spawn_point)

	return result

func spawn_players()->void:
	var blue_spawn_points := get_spawn_points_for_team(GameEnums.Team.BLUE)
	var red_spawn_points := get_spawn_points_for_team(GameEnums.Team.RED)

	if blue_spawn_points.is_empty() or red_spawn_points.is_empty():
		push_error("Cannot spawn players: missing blue or red spawn points.")
		return

	var required_blue_spawn_points := 0
	var required_red_spawn_points := 0
	for i in ready_clients.size():
		if i % 2 == 0:
			required_blue_spawn_points += 1
		else:
			required_red_spawn_points += 1

	if blue_spawn_points.size() < required_blue_spawn_points or red_spawn_points.size() < required_red_spawn_points:
		push_error(
			"Cannot spawn players: expected %s blue and %s red spawn points, found %s blue and %s red."
			% [required_blue_spawn_points, required_red_spawn_points, blue_spawn_points.size(), red_spawn_points.size()]
		)
		return
			
	ready_clients.shuffle() # embaralha array com os clientes prontos
	
	for i in ready_clients.size():
		var team := GameEnums.Team.BLUE
		var spawn_tform := Transform3D.IDENTITY
		if i%2 == 0 :
			team = GameEnums.Team.BLUE
			spawn_tform = blue_spawn_points[0].global_transform # utilizando o global pra garantir que vai ser pego certo independente da hierarquia
			blue_spawn_points.pop_front()
			
		else :
			team = GameEnums.Team.RED
			spawn_tform = red_spawn_points[0].global_transform
			red_spawn_points.pop_front()
	
		spawn_server_player(ready_clients[i], spawn_tform, team)
		var spawn_payload := make_spawn_player_payload(ready_clients[i], spawn_tform, team, true)
		
		for ready_client_id in ready_clients :
				s_spawn_player.rpc_id(ready_client_id, spawn_payload)
			
func spawn_server_player (client_id : int, spawn_tform : Transform3D, team:int)->void:
	var server_player_real := preload("res://player/player_server_real.tscn").instantiate()
	var server_player_dummy := preload("res://player/player_server_dummy.tscn").instantiate()

	server_player_real.name = str(client_id)
	server_player_dummy.name = str(client_id)+"_dummy"
	server_player_real.lobby = self
	server_player_dummy.id = client_id

	server_player_real.global_transform = spawn_tform
	add_child(server_player_real, true)
	add_child(server_player_dummy, true)
	
	server_players[client_id] = {}
	server_players[client_id].real = server_player_real
	server_players[client_id].dummy = server_player_dummy
	
	client_data[client_id][NetKeys.TEAM] = team


@rpc ("authority", "call_remote", "reliable")
func s_spawn_player(spawn_data: Dictionary)->void:
	pass


func make_spawn_player_payload(client_id: int, spawn_tform: Transform3D, team: int, auto_freeze: bool) -> Dictionary:
	return NetPayloads.make_spawn_player(
		client_id,
		spawn_tform,
		team,
		client_data.get(client_id)[NetKeys.DISPLAY_NAME],
		client_data.get(client_id)[NetKeys.WEAPON_ID],
		auto_freeze
	)
		 
@rpc("authority", "call_remote", "reliable")
func s_start_match()->void:
	pass
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(playerState:Dictionary)->void:
	var client_id := multiplayer.get_remote_sender_id()
	if not server_players.has(client_id):
		return

	if not NetPayloads.is_player_state(playerState):
		push_warning("Invalid player_state payload from client %s" % client_id)
		return
	
	#atribuindo ao state global dos jogadores o valor recebido por RPC das posições
	current_world_state[NetKeys.WORLD_PLAYERS][client_id] = playerState 
	server_players.get(client_id).real.position = playerState[NetKeys.POS]
	server_players.get(client_id).real.rotation.y = playerState[NetKeys.ROT_Y]
	server_players.get(client_id).real.set_anim(playerState[NetKeys.ANIM]) 
	
	
	
@rpc ("any_peer", "call_remote", "reliable")
func c_weapon_selected(weapon_id:int)->void:
	
	var client_id =  multiplayer.get_remote_sender_id()
	if !client_id in client_data.keys() or client_id in ready_clients:
		return
	client_data[client_id][NetKeys.WEAPON_ID] = weapon_id

	if status == GAME:
		respawn_player(client_id)
		return

	ready_clients.append(client_id)
	waiting_players_ready = true
	check_players_ready(start_match)
	
func start_match()->void:
	status = GAME
	match_time_left = match_config.time_limit_sec

	if not setup_game_mode():
		end_match()
		return

	update_match_meta(make_match_meta_payload())
	current_game_mode.start_match()
	

	await get_tree().create_timer(1).timeout

	if status != GAME:
		return
	
	for ready_client_id in get_connected_clients():
		s_start_match.rpc_id(ready_client_id)
		
	set_physics_process(true)
	match_timer.start()
	update_match_time_left()

func setup_game_mode() -> bool:
	current_game_mode = null

	match match_config.mode:
		GameEnums.GameMode.TEAM_DEATHMATCH:
			current_game_mode = TeamDeathmatchMode.new(self)
			return true

		GameEnums.GameMode.KING_OF_THE_HILL:
			current_game_mode = KingOfTheHillMode.new(self)
			return true

		GameEnums.GameMode.CAPTURE_THE_FLAG:
			push_error("CAPTURE_THE_FLAG is out of scope.")
			return false

		_:
			push_error("Unsupported game mode: %s" % match_config.mode)
			return false


func make_match_meta_payload() -> Dictionary:
	return NetPayloads.make_match_meta(match_config.mode, match_config.score_to_win)


func update_match_meta(match_meta: Dictionary) -> void:
	if not NetPayloads.is_match_meta(match_meta):
		push_warning("Invalid match_meta payload")
		return

	for client_id in get_connected_clients():
		s_update_match_meta.rpc_id(client_id, match_meta)


@rpc("authority", "call_remote", "reliable")
func s_update_match_meta(match_meta: Dictionary) -> void:
	pass


func has_current_game_mode() -> bool:
	if current_game_mode == null:
		push_error("Current game mode is not initialized.")
		return false

	return true
	

	
func respawn_player(respawn_client_id:int)->void:
	var team:int = client_data.get(respawn_client_id)[NetKeys.TEAM]
	var possible_spawn_points := get_spawn_points_for_team(team)

	if possible_spawn_points.is_empty():
		push_error("Cannot respawn player %s: no spawn points for team %s." % [respawn_client_id, team])
		return
	
	var spawn_point = possible_spawn_points.pick_random()
	var spawn_tform: Transform3D = spawn_point.global_transform
	
	#spawn para o server
	spawn_server_player(respawn_client_id, spawn_tform, team)
	var spawn_payload := make_spawn_player_payload(respawn_client_id, spawn_tform, team, false)
	
	#spawn para os jogadores
	for client_id in get_connected_clients() :
			s_spawn_player.rpc_id(client_id, spawn_payload)

func start_weapon_selection()->void:
	for ready_client in get_connected_clients():
		s_start_weapon_selection.rpc_id(ready_client)
@rpc("authority", "call_remote", "reliable")
func s_start_weapon_selection()->void:
	pass
	
@rpc ("any_peer", "call_remote", "unreliable")
func c_shot_fired(time_stamp:int , player_data:Dictionary)->void:
	var sender_id:= multiplayer.get_remote_sender_id()
	if not server_players.has(sender_id):
		return

	if not NetPayloads.is_player_state(player_data):
		push_warning("Invalid shot payload from client %s" % sender_id)
		return

	for client_id in get_connected_clients()	:
		if client_id != sender_id:
			s_play_shoot_fx.rpc_id(client_id,sender_id )

	calculate_shot_results(sender_id, time_stamp, player_data)
		
func calculate_shot_results(shooter_id: int , time_stamp : int, player_data:Dictionary)->void:
	var target_time := time_stamp - 100 # 100 ms é o delay de buffer , está setado no cliente também
	var target_world_state: Dictionary = {}
	
	for world_state in previous_world_states:
		if world_state.get(NetKeys.WORLD_TIME_MS, 0) < target_time:
			target_world_state = world_state
			break
	
	if target_world_state.is_empty() or previous_world_states.is_empty():
		return

	var target_world_players: Dictionary = target_world_state.get(NetKeys.WORLD_PLAYERS, {})
	var current_world_players: Dictionary = previous_world_states[0].get(NetKeys.WORLD_PLAYERS, {})
	if target_world_players.is_empty() or current_world_players.is_empty():
		return
	
	for client_id in target_world_players.keys():
		if not client_id in server_players.keys() :
			continue

		if not client_id in current_world_players.keys(): # Testa se o player está vivo 
			continue
			
		if client_id == shooter_id:
				
			server_players.get(client_id).dummy.update_body_geometry(player_data)
			continue
		
		var target_player_state: Dictionary = target_world_players.get(client_id, {})
		if not target_player_state.is_empty():
			server_players.get(client_id).dummy.update_body_geometry(target_player_state)
	
	await get_tree().physics_frame # aguarda 1 frame do calculo de física para atualizar os modelos
	
	if not shooter_id in server_players.keys():
		return
		
	var weapon_id: int = client_data.get(shooter_id)[NetKeys.WEAPON_ID]
	var weapon_data: WeaponGameplayData = WeaponConfig.get_weapon_data(weapon_id)
	# Faz o raycast a partir da cabeça do atirador
	var space_state := get_world_3d().direct_space_state
	var shooter_dummy: ServerPlayerDummy = server_players.get(shooter_id).dummy
	var ray_params:= PhysicsRayQueryParameters3D.new()
	var head_tform := shooter_dummy.head.global_transform

	ray_params.from = shooter_dummy.head.global_position
	ray_params.collide_with_areas = true
	ray_params.exclude = shooter_dummy.hitboxes
	ray_params.collision_mask = PHYSICS_LAYER_EXACT + PHYSICS_LAYER_HITBOX

	for i in weapon_data.projectiles: #shotgun 6 projéteis = 6 ray casts, cada um com precisão aleatória
		var rand_rot:float = deg_to_rad(randf() * (1 - weapon_data.accuracy ) * MAX_SHOT_RANDOM_DEGREES )
		var shoot_tform:= head_tform.rotated_local(Vector3.FORWARD , randf() * PI *2)
		shoot_tform = shoot_tform.rotated_local(Vector3.UP, rand_rot) 
		print("Calculating shot ",i , rand_rot, shoot_tform )
		ray_params.to = ray_params.from + shoot_tform.basis.z * (RAYCAST_CHECK_DISTANCE*-1) #-1 pois eixo Z negativo é pra frente nesse caso
		
		var result: = space_state.intersect_ray(ray_params)
		if result.is_empty() : 
			continue
		
		if result.collider is HitBox:
			var hurt_client_id = result.collider.player.id
			if not server_players.has(hurt_client_id):
				continue
				
			if client_data.get(shooter_id)[NetKeys.TEAM] == client_data.get(hurt_client_id)[NetKeys.TEAM]:
				continue
			
			#Cálculo do dano causado pela arma
			var hurt_server_player :PlayerServerReal = server_players.get(hurt_client_id).real
			var base_damage = -weapon_data.damage * result.collider.damage_multiplayer
			
			#TODO mover cálculo do dano pra outra função, utilizar Curve ou Gradiente , também dá pra configurar isso por tipo de arma
			var damage_falloff_start := 10 
			var damage_falloff_end := 20 
			var damage_max_falloff := 0.4
			var distance = ray_params.from.distance_to(result.position)
			var damage_falloff_multiplier = remap(distance, damage_falloff_start, damage_falloff_end, 1 , damage_max_falloff)
			damage_falloff_multiplier = clampf(damage_falloff_multiplier, damage_max_falloff, 1) # valor fica entra 0.4 e 1
			var damage_dealt = base_damage*damage_falloff_multiplier

			hurt_server_player.change_health(damage_dealt, shooter_id)
			
			print (result.collider.player.name + "Foi acertado!")
			spawn_bullet_hit_fx(result.position - global_position, result.normal, GameEnums.HitFxType.PLAYER)
		else :
			spawn_bullet_hit_fx(result.position - global_position, result.normal, GameEnums.HitFxType.ENVIRONMENT)
	
	
func spawn_bullet_hit_fx(pos:Vector3, normal:Vector3, type : int)->void:
	for client_id in get_connected_clients(): # pega os clientes do lobby
		s_spawn_bullet_hit_fx.rpc_id(client_id, pos, normal, type)
		
@rpc("authority", "call_remote", "unreliable")
func s_spawn_bullet_hit_fx(pos:Vector3, normal:Vector3, type : int):
	pass
	
		
@rpc("authority", "call_remote", "unreliable")
func s_play_shoot_fx(target_client_id:int)->void:
	pass

func update_health(target_client_id:int, current_health:int , max_health:int, changed_amount:int)->void:
	for client_id in get_connected_clients():
		s_update_health.rpc_id(client_id, target_client_id , current_health, max_health, changed_amount)	

@rpc ("authority", "call_remote", "unreliable_ordered")
func s_update_health(target_client_id:int, current_health:int , max_health:int, changed_amount:int)->void:
	pass

func pickup_cooldown_started(network_id :String )->void:
	if network_id.is_empty():
		return

	for client_id in get_connected_clients():
		s_pickup_cooldown_started.rpc_id(client_id, network_id)

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_started(network_id:String)->void:
	pass

func pickup_cooldown_ended (network_id :String)->void:
	if network_id.is_empty():
		return

	for client_id in get_connected_clients():
		s_pickup_cooldown_ended.rpc_id(client_id, network_id)

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_ended(network_id:String)->void:
	pass

func player_died(dead_player_id : int, killer_id:int)->void:
	if not server_players.has(dead_player_id):
		return

	remove_player_from_objectives(dead_player_id)
		
	server_players.get(dead_player_id).real.queue_free()
	server_players.get(dead_player_id).dummy.queue_free()
	server_players.erase(dead_player_id)
	current_world_state[NetKeys.WORLD_PLAYERS].erase(dead_player_id)
	
	for client_id in get_connected_clients():
		s_player_died.rpc_id(client_id, dead_player_id, killer_id)

	if has_current_game_mode():
		current_game_mode.handle_player_death(dead_player_id, killer_id)

	if status != GAME:
		return
		
	await get_tree().create_timer(DEATH_COOLDOWN_LENGTH).timeout

	if status != GAME:
		return

	s_start_weapon_selection.rpc_id(dead_player_id)
		
@rpc("authority", "call_remote", "reliable")
func s_player_died(dead_player_id:int, killer_id:int)->void:
	pass

func update_game_scores()->void:
	if not has_current_game_mode():
		return

	current_game_mode.update_scores()


func update_hill_state(hill_state: Dictionary) -> void:
	for client_id in get_connected_clients():
		s_update_hill_state.rpc_id(client_id, hill_state)
 
@rpc("authority", "call_remote", "reliable")
func s_update_game_scores(blue_score:int , red_score : int):
	pass


@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_hill_state(hill_state: Dictionary) -> void:
	pass

func match_timer_sec_passed()->void:
	match_time_left -= 1
	update_match_time_left()
	if match_time_left <= 0:
		if has_current_game_mode():
			current_game_mode.on_match_timer_finished()
		else:
			end_match()

func update_match_time_left()->void:
	for client_id in get_connected_clients():
		s_update_match_time_left.rpc_id(client_id, match_time_left)
	
@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_match_time_left(time_left:int)->void:
	pass 

func end_match()->void:
	if status == FINISHED:
		return

	status = FINISHED
	match_timer.stop()
	set_physics_process(false)
	var end_match_payload := make_end_match_payload()
	
	for client_id in get_connected_clients():
		s_end_match.rpc_id(client_id, end_match_payload)

	delete_lobby_after_delay()
	
@rpc("authority","call_remote","reliable")
func s_end_match(end_match_data:Dictionary)->void:
	pass


func make_end_match_payload() -> Dictionary:
	if not has_current_game_mode():
		return NetPayloads.make_end_match(0, 0, [])

	return current_game_mode.make_end_match_payload()

func make_end_match_players_payload() -> Array[Dictionary]:
	var players: Array[Dictionary] = []

	for client_id in client_data.keys():
		var data: Dictionary = client_data[client_id]
		if not data.has(NetKeys.TEAM):
			continue

		players.append({
			NetKeys.CLIENT_ID: client_id,
			NetKeys.DISPLAY_NAME: data[NetKeys.DISPLAY_NAME],
			NetKeys.TEAM: data[NetKeys.TEAM],
			NetKeys.KILLS: data[NetKeys.KILLS],
			NetKeys.DEATHS: data[NetKeys.DEATHS],
		})

	return players

@rpc("any_peer", 'call_remote', 'reliable')
func c_try_throw_grenade(player_state:Dictionary)->void:
	var client_id := multiplayer.get_remote_sender_id()
	if not server_players.has(client_id):
		return

	if not NetPayloads.is_player_state(player_state):
		push_warning("Invalid grenade payload from client %s" % client_id)
		return
	
	var player :PlayerServerReal = server_players.get(client_id).real
	
	if player.grenades_left <= 0 : return 
	
	player.update_grenades_left(player.grenades_left-1)
	
	var grenade :Grenade = preload("res://player/grenade/grenade.tscn").instantiate()
	var direction := Vector3.FORWARD
	direction = direction.rotated(Vector3.RIGHT, player_state[NetKeys.ROT_X])
	direction = direction.rotated(Vector3.UP, player_state[NetKeys.ROT_Y])
	
	grenade.set_data(self, direction, player)
	grenade.position = player_state[NetKeys.POS] + Vector3.UP * 1.2
	
	var grenade_network_id := make_grenade_network_id(client_id)
	grenade.set_network_id(grenade_network_id)
	grenade.name = "Grenade_%s" % NetworkEntity.to_wire(grenade_network_id)
	add_child(grenade,true)
	grenades[NetworkEntity.to_wire(grenade_network_id)] = grenade

func update_grenades_left(client_id:int , amount:int)->void:
	s_update_grenades_left.rpc_id(client_id, amount)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_grenades_left(grenades_left:int)->void:
	pass

func grenade_exploded(grenade:Grenade)->void:
	var grenade_id := grenade.get_network_id()
	if grenade_id.is_empty():
		return

	grenades.erase(grenade_id)
	current_world_state[NetKeys.WORLD_GRENADES].erase(grenade_id)
	grenade.queue_free()
	
	for client_id in get_connected_clients():
		s_explode_grenade.rpc_id(client_id, grenade_id)
	pass

@rpc("authority", "call_remote","reliable")
func s_explode_grenade(grenade_id:String)->void:
	pass

func play_pickup_fx(client_id: int, pickup_type:int)->void:
	s_play_pickup_fx.rpc_id(client_id, pickup_type)
@rpc("authority", "call_remote","unreliable")
func s_play_pickup_fx(pickup_type:int)->void:
	pass
	
@rpc("any_peer", "call_remote","reliable")
func c_client_quit_match ()->void:
	var client_id = multiplayer.get_remote_sender_id()
	remove_client(client_id)
	current_world_state[NetKeys.WORLD_PLAYERS].erase(client_id)


func delete_lobby_after_delay() -> void:
	if is_pending_delete:
		return

	is_pending_delete = true
	await get_tree().create_timer(FINISHED_LOBBY_DELETE_DELAY_SEC).timeout
	if is_inside_tree():
		Server.delete_lobby(self)
