extends Node3D
class_name Lobby

func _ready()-> void:
	c_lock_client.rpc_id(1)

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
	
@rpc ("authority", "call_remote", "reliable")
func s_spawn_player(client_id : int , spawn_tform :Transform3D , team:int)->void:
	var player : CharacterBody3D
	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
	else : 
		player = preload("res://player/remote/player_remote.tscn").instantiate()
	
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	
	pass
