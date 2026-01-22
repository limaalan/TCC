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
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager","clear_scenes")
	
