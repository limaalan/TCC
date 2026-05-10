extends Node3D
class_name Lobby
const INTERPOLATION_BUFFER_MS := 100 

var players:= {} # Dicionário dos jogadores chave:valor =  { id: PlayerScene } 
var world_state_buffer:Array[Dictionary] = []
var pickups := {}
var grenades := {}
var player_names_and_teams := {} # key player ID value outro dicionário com player name e Time

func get_local_player()->PlayerLocal:
	return players.get(multiplayer.get_unique_id())
	
func get_remote_players()->Dictionary:
	var remote_players := {}
	for client_id in players.keys():
		if client_id == multiplayer.get_unique_id():
			continue
		var maybe_remote_player = players.get(client_id)
		if is_instance_valid(maybe_remote_player) and maybe_remote_player is PlayerRemote:
			remote_players[client_id] = maybe_remote_player
	
	return remote_players

func _ready()-> void:
	add_to_group(ClientNames.GROUP_LOBBY)
	c_lock_client.rpc_id(1)
	set_physics_process(false)

func queue_free_child(node: Node) -> void:
	if node == null:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.queue_free()

func clear_loaded_map_runtime_state() -> void:
	var loaded_map := get_node_or_null("Map")
	if loaded_map != null:
		queue_free_child(loaded_map)

	for pickup in pickups.values():
		if is_instance_valid(pickup):
			queue_free_child(pickup)
	pickups.clear()

	for grenade_data in grenades.values():
		if grenade_data is Dictionary and is_instance_valid(grenade_data.get(NetKeys.INSTANCE)):
			queue_free_child(grenade_data.get(NetKeys.INSTANCE))
	grenades.clear()
	world_state_buffer.clear()

	
func _physics_process(delta: float) -> void:
	send_player_state()
	handle_world_state()
	
func send_player_state()->void:
	if (get_local_player() == null):
		return
	c_send_player_state.rpc_id(1, create_player_data())
	
func create_player_data()->Dictionary:
	var local_player := get_local_player()
	return NetPayloads.make_player_state(
		local_player.position,
		local_player.rotation.y,
		local_player.head.rotation.x,
		local_player.current_anim
	)
	
func handle_world_state()->void:
	#ainda não inicializou , não tem playerState...
	if world_state_buffer.size()<2:
		return
		
	var target_render_unix_ms :int = floori(Time.get_unix_time_from_system() * 1000) - INTERPOLATION_BUFFER_MS - Server.clock_deviation_ms
	
	#Remove states recebidos do server que já passaram
	while world_state_buffer.size()>2 and target_render_unix_ms > world_state_buffer[1][NetKeys.WORLD_TIME_MS] :
		world_state_buffer.pop_front()
		
	var lerp_weight = remap(target_render_unix_ms, world_state_buffer[0][NetKeys.WORLD_TIME_MS], world_state_buffer[1][NetKeys.WORLD_TIME_MS], 0, 1)
	if (world_state_buffer[0].has(NetKeys.WORLD_GRENADES) and world_state_buffer[1].has(NetKeys.WORLD_GRENADES)):
		handle_grenades(world_state_buffer[0][NetKeys.WORLD_GRENADES], world_state_buffer[1][NetKeys.WORLD_GRENADES], lerp_weight)
	var remote_players := get_remote_players()
	
	#Se algum dos states está faltando player_states ps
	if not world_state_buffer[0].has(NetKeys.WORLD_PLAYERS) or not world_state_buffer[1].has(NetKeys.WORLD_PLAYERS):
		return
	
	for client_id in world_state_buffer[1][NetKeys.WORLD_PLAYERS].keys():
		if not client_id in remote_players.keys():
			continue
			
		if not client_id in world_state_buffer[0][NetKeys.WORLD_PLAYERS].keys():
			continue
		
		if not is_instance_valid(players.get(client_id)):
			continue
		
		var remote_player :PlayerRemote = remote_players.get(client_id)
		
		remote_player.update_body_geometry(
			world_state_buffer[0][NetKeys.WORLD_PLAYERS].get(client_id),
			world_state_buffer[1][NetKeys.WORLD_PLAYERS].get(client_id),
			lerp_weight
		)
		
		
	
func handle_grenades(old_grenade_data:Dictionary, new_grenade_data:Dictionary, lerp_weight:float)->void:
	for grenade_name in new_grenade_data.keys():
		# checa se precisa criar granadas
		if not grenade_name in grenades.keys():
			var grenade:Grenade = preload("res://player/grenade/grenade.tscn").instantiate()
			grenades[grenade_name]= {NetKeys.INSTANCE: grenade, NetKeys.EXPLODED: false} #instância da granada e indicador de explodido
			grenade.name = grenade_name
			grenade.global_transform= new_grenade_data.get(grenade_name)[NetKeys.TRANSFORM]
			add_child(grenade , true)
	
	for grenade_name in old_grenade_data.keys():
		#explodindo a granada se não existe mais no buffer e não foi explodido ainda
		if not grenade_name in new_grenade_data.keys():
			if not grenade_name in grenades.keys(): 
				continue
			if not grenades.get(grenade_name)[NetKeys.EXPLODED]:
				explode_grenade(grenade_name)
			grenades.erase(grenade_name)
			continue
			
		if grenades.get(grenade_name)[NetKeys.EXPLODED]:
			continue
		#movendo as granadas
		var grenade:Grenade = grenades.get(grenade_name)[NetKeys.INSTANCE]
		grenade.lerp_tform(old_grenade_data.get(grenade_name), new_grenade_data.get(grenade_name), lerp_weight)
			
				
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(playerState:Dictionary)->void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map(map_id: StringName):
	var map_scene := MapRegistry.get_map_scene(map_id)
	if map_scene == null:
		push_warning("Failed to load client map for map_id '%s'. Skipping c_map_ready." % String(map_id))
		return

	clear_loaded_map_runtime_state()

	var map = map_scene.instantiate()
	map.name = "Map"
	map.ready.connect(map_ready.bind(map, map_id), CONNECT_ONE_SHOT)
	add_child(map, true)
	get_tree().call_group(ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER, ClientNames.METHOD_CLEAR_SCENES)
	AudioManager.play_music(AudioManager.MusicKeys.BattleMusic)


func map_ready(loaded_map: Node, map_id: StringName)->void:
	if loaded_map != get_node_or_null("Map"):
		push_warning("Ignoring stale ready signal for client map_id '%s'." % String(map_id))
		return
	c_map_ready.rpc_id(1) # manda pro server map ready
	
@rpc ("any_peer", "call_local", "reliable")
func c_map_ready()->void:
	pass
	
@rpc("authority", "call_remote", "reliable")
func s_start_match()->void:
	get_tree().call_group(ClientNames.GROUP_PLAYER_LOCAL, ClientNames.METHOD_UNFREEZE)
	set_physics_process(true)
	
@rpc ("authority", "call_remote", "reliable")
func s_spawn_player(spawn_data: Dictionary)->void:
	if not NetPayloads.is_spawn_player(spawn_data):
		push_warning("Invalid spawn_player payload")
		return

	var client_id: int = spawn_data[NetKeys.CLIENT_ID]
	var spawn_tform: Transform3D = spawn_data[NetKeys.SPAWN_TRANSFORM]
	var team: int = spawn_data[NetKeys.TEAM]
	var player_name: String = spawn_data[NetKeys.DISPLAY_NAME]
	var weapon_id: int = spawn_data[NetKeys.WEAPON_ID]
	var auto_freeze: bool = spawn_data[NetKeys.AUTO_FREEZE]
	var player : PlayerCharacter

	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
		player.auto_freeze = auto_freeze
	else : 
		player = preload("res://player/remote/player_remote.tscn").instantiate()
		player.display_name = player_name
	
	player.team = team
	player.weapon_id = weapon_id 
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	
	if players.has(client_id) and is_instance_valid(players[client_id]):
		players[client_id].queue_free()
		
	players[client_id] = player
	player_names_and_teams [client_id] = {NetKeys.DISPLAY_NAME: player_name, NetKeys.TEAM: team}
		
@rpc ("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_word_state:Dictionary)->void:
	world_state_buffer.append(new_word_state)
	
func weapon_selected(weapon_id:int)->void:
	c_weapon_selected.rpc_id(1, weapon_id)
@rpc ("any_peer", "call_remote", "reliable")
func c_weapon_selected(weapon_id:int)->void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_weapon_selection()->void:
	get_tree().call_group(ClientNames.GROUP_WEAPON_SELECTION_UI, ClientNames.METHOD_ACTIVATE)


func local_shot_fired()->void:
	c_shot_fired.rpc_id(1, floori(Time.get_unix_time_from_system()*1000) - Server.clock_deviation_ms, create_player_data())

@rpc ("any_peer", "call_remote", "unreliable")
func c_shot_fired(time_stamp:int , player_data:Dictionary)->void:
	pass
	
@rpc("authority", "call_remote", "unreliable")
func s_play_shoot_fx(target_client_id:int)->void:
	var remote_players := get_remote_players()
	if not target_client_id in remote_players:
		return
	remote_players[target_client_id].play_shoot_fx()

@rpc("authority", "call_remote", "unreliable")
func s_spawn_bullet_hit_fx(pos:Vector3, normal:Vector3, type : int):
	var bullet_hit_fx :Node3D 
	match type : 
		GameEnums.HitFxType.ENVIRONMENT:
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_environment.tscn").instantiate()
		GameEnums.HitFxType.PLAYER:
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_player.tscn").instantiate()
	var spawn_tform := Transform3D.IDENTITY
	
	if not normal.is_equal_approx(Vector3.UP) and not normal.is_equal_approx(Vector3.DOWN):
		spawn_tform = spawn_tform.looking_at(normal)
		spawn_tform = spawn_tform.rotated_local(Vector3.RIGHT , -PI / 2) #rotacionado 90° direita
	spawn_tform.origin = pos
	bullet_hit_fx.global_transform = spawn_tform
	add_child(bullet_hit_fx)
#Verificar porque não marca o chão com o sprite da bala

@rpc ("authority", "call_remote", "unreliable_ordered")
func s_update_health(target_client_id:int, current_health:int , max_health:int, changed_amount:int)->void:
	var maybe_player :PlayerCharacter = players.get(target_client_id)
	if is_instance_valid(maybe_player):
		maybe_player.update_health_bar(current_health, max_health, changed_amount)


@rpc("authority", "call_remote", "reliable")
func s_spawn_pickup(pickup_name:String, pickup_type:int , pos : Vector3)->void:
	var pickup :Pickup = preload("res://player/pickups/pickup.tscn").instantiate()
	pickup.name = pickup_name
	pickup.position = pos
	pickup.pickup_type = pickup_type
	add_child(pickup, true) # força o nome , pra garantir que é o que foi setado no pickup,nome, importate pois o nome deve bater entre server e cliente
	pickups[pickup_name] = pickup

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_started(pickup_name:String)->void:
	pickups.get(pickup_name).cooldown_started()
	

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_ended(pickup_name:String)->void:
	pickups.get(pickup_name).cooldown_ended()

@rpc("authority", "call_remote", "reliable")
func s_player_died(dead_player_id:int, killer_id:int)->void:
	if players.has(dead_player_id):
		players.get(dead_player_id).queue_free()
		players[dead_player_id] = null
		
	get_tree().call_group(
		ClientNames.GROUP_MATCH_INFO_UI,
		ClientNames.METHOD_SHOW_ELIMINATION_TEXT,
		killer_id,
		dead_player_id,
		player_names_and_teams.get(killer_id)[NetKeys.DISPLAY_NAME],
		player_names_and_teams.get(killer_id)[NetKeys.TEAM],
		player_names_and_teams.get(dead_player_id)[NetKeys.DISPLAY_NAME],
		player_names_and_teams.get(dead_player_id)[NetKeys.TEAM]
		

	)
	
	
@rpc("authority", "call_remote", "reliable")
func s_update_game_scores(blue_score:int , red_score : int):
	get_tree().call_group(ClientNames.GROUP_MATCH_INFO_UI, ClientNames.METHOD_UPDATE_SCORE, blue_score, red_score)
	
@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_match_time_left(time_left:int)->void:
	get_tree().call_group(ClientNames.GROUP_MATCH_INFO_UI, ClientNames.METHOD_UPDATE_MATCH_TIME_LEFT, time_left)


@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_hill_state(hill_state: Dictionary) -> void:
	if not NetPayloads.is_hill_state(hill_state):
		push_warning("Invalid hill_state payload")
		return

	get_tree().call_group(ClientNames.GROUP_MATCH_INFO_UI, ClientNames.METHOD_UPDATE_HILL_STATE, hill_state)

@rpc("authority","call_remote","reliable")
func s_end_match(end_match_data:Dictionary)->void:
	if not NetPayloads.is_end_match(end_match_data):
		push_warning("Invalid end_match payload")
		return

	get_tree().call_group(ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER, ClientNames.METHOD_CHANGE_SCENE, "res://ui/match_end_info/match_end_info_ui.tscn", end_match_data)
	queue_free()

func try_throw_grenade() ->void :
	c_try_throw_grenade.rpc_id(1,create_player_data())
@rpc("any_peer", 'call_remote', 'reliable')
func c_try_throw_grenade(player_state:Dictionary)->void:
	pass

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_grenades_left(grenades_left:int)->void:
	get_local_player().update_grenades_left(grenades_left)
	
@rpc("authority", "call_remote","reliable")
func s_explode_grenade(grenade_name:String)->void:
	pass
	
func explode_grenade(grenade_name :String)->void:
	if not grenade_name in grenades.keys(): return 
	var grenade:Grenade = grenades.get(grenade_name)[NetKeys.INSTANCE]
	if is_instance_valid(grenade):
		var explosion_fx :Node3D = preload("res://player/grenade/grenade_explosion_fx.tscn").instantiate()
		explosion_fx.global_transform = grenade.global_transform
		add_child(explosion_fx)
		grenade.queue_free()
		
	grenades[grenade_name][NetKeys.EXPLODED] = true
	
@rpc("authority", "call_remote","unreliable")
func s_play_pickup_fx(pickup_type:int)->void:
	match pickup_type:
		GameEnums.PickupType.HEALTH:
			AudioManager.play_sfx(AudioManager.SFXKeys.PickupHealth)
		GameEnums.PickupType.GRENADE:
			AudioManager.play_sfx(AudioManager.SFXKeys.PickupGrenade)
			
			
func exit_game ()->void :
	c_client_quit_match.rpc_id(1)
	queue_free()

@rpc("any_peer", "call_remote","reliable")
func c_client_quit_match ()->void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_delete_player(client_id:int)->void:
	if players.has(client_id):
		players.get(client_id).queue_free()
		players.erase(client_id)
