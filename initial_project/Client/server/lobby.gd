extends Node3D
class_name Lobby
const INTERPOLATION_BUFFER_MS := 100 

var players:= {} # Dicionário dos jogadores chave:valor =  { id: PlayerScene } 
var world_state_buffer:Array[Dictionary] = []

func get_local_player()->PlayerLocal:
	return players.get(multiplayer.get_unique_id())
	
func get_remote_players()->Dictionary:
	var remote_players := {}
	for client_id in players.keys():
		if client_id == multiplayer.get_unique_id():
			continue
		var maybe_remote_player : PlayerRemote = players.get(client_id)
		if is_instance_valid(maybe_remote_player):
			remote_players[client_id] = maybe_remote_player
	
	return remote_players

func _ready()-> void:
	c_lock_client.rpc_id(1)
	set_physics_process(false)

	
func _physics_process(delta: float) -> void:
	send_player_state()
	handle_world_state()
	
func send_player_state()->void:
	if (get_local_player() == null):
		return
	c_send_player_state.rpc_id(1, create_player_data())
	
func create_player_data()->Dictionary:
	var local_player := get_local_player()
	var local_player_state := {
		"pos":local_player.position,
		"rot_y": local_player.rotation.y,
		"rot_x": local_player.head.rotation.x,
		"anim": local_player.current_anim
		}
	return local_player_state
	
func handle_world_state()->void:
	#ainda não inicializou , não tem playerState...
	if world_state_buffer.size()<2:
		return
		
	var target_render_unix_ms :int = floori(Time.get_unix_time_from_system() * 1000) - INTERPOLATION_BUFFER_MS - Server.clock_deviation_ms
	
	#Remove states recebidos do server que já passaram
	while world_state_buffer.size()>2 and target_render_unix_ms > world_state_buffer[1].t :
		world_state_buffer.pop_front()
		
	var lerp_weight = remap(target_render_unix_ms, world_state_buffer[0].t, world_state_buffer[1].t, 0, 1)
		
	var remote_players := get_remote_players()
	
	#Se algum dos states está faltando player_states ps
	if not world_state_buffer[0].has("ps") or not world_state_buffer[1 ].has("ps"):
		return
	
	for client_id in world_state_buffer[1].ps.keys():
		if not client_id in remote_players.keys():
			continue
			
		if not client_id in world_state_buffer[0].ps.keys():
			continue
		
		var remote_player :PlayerRemote = remote_players.get(client_id)
		
		remote_player.update_body_geometry(
			world_state_buffer[0].ps.get(client_id),
			world_state_buffer[1].ps.get(client_id),
			lerp_weight
		)
		
		
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(playerState:Dictionary)->void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map():#passar ID do mapa quando eu tiver vários mapas...
	var map = load("res://maps/map_farm.tscn").instantiate()
	map.name = "Map"
	map.ready.connect(map_ready)
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager","clear_scenes")

func map_ready()->void:
	c_map_ready.rpc_id(1) # manda pro server map ready
	
@rpc ("any_peer", "call_local", "reliable")
func c_map_ready()->void:
	pass
	
@rpc("authority", "call_remote", "reliable")
func s_start_match()->void:
	get_tree().call_group("PlayerLocal","set_procecess",true)
	set_physics_process(true)
	
@rpc ("authority", "call_remote", "reliable")
func s_spawn_player(client_id : int , spawn_tform :Transform3D , team:int , player_name : String)->void:
	var player : CharacterBody3D
	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
	else : 
		player = preload("res://player/remote/player_remote.tscn").instantiate()
		player.team = team
		player.display_name = player_name
	
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	
	players[client_id] = player
	
@rpc ("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_word_state:Dictionary)->void:
	world_state_buffer.append(new_word_state)
