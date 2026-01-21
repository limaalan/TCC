extends Node3D
class_name Lobby
enum {IDLE, LOCKED, GAME}
var status:= IDLE

var clients : Array[int] = []
var ready_clients: Array[int] =[]

func add_client(id:int)->void: 
	clients.append(id)
	
func remove_client(id:int)->void:
	clients.erase(id)

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	var client_id =  multiplayer.get_remote_sender_id()
	if !client_id in clients or client_id in ready_clients:
		return
	ready_clients.append(client_id)
	
	for client in clients :
		if client not in ready_clients:
			return
	start_loading_map()
	
	ready_clients.clear()

func start_loading_map():
	var map = Node3D.new()
	map.name="Map"
	add_child(map, true)  #força nome 
	
	for ready_client in ready_clients:
		s_start_loading_map.rpc_id(ready_client)
		
@rpc('authority', "call_remote", "reliable")
func s_start_loading_map():#passar ID do mapa quando eu tiver vários mapas...
	pass
	
	
	
	
	
