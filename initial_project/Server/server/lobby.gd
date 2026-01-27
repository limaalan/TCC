extends Node3D
class_name Lobby
enum {IDLE, LOCKED, GAME}
var status:= IDLE
# Este dicionário vai manter o estado de toda a partida ( tempo , pontuação ... )
# dentro da chave "ps" estão os valores dos player states
var world_state := {"ps":{}} 


var clients : Array[int] = []
var ready_clients: Array[int] =[]

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	for client_id in clients:
		s_send_world_state.rpc_id( client_id, world_state) 
		
@rpc ("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_word_state:Dictionary)->void:
	pass
	
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
	var map = load("res://maps/server_map_farm.tscn").instantiate()
	map.name="Map"
	add_child(map, true)  #força nome 
	
	for ready_client in ready_clients:
		s_start_loading_map.rpc_id(ready_client)
		
@rpc('authority', "call_remote", "reliable")
func s_start_loading_map():#passar ID do mapa quando eu tiver vários mapas...
	pass
	
@rpc ("any_peer", "call_local", "reliable")
func c_map_ready()->void:
	var client_id =  multiplayer.get_remote_sender_id()
	if !client_id in clients or client_id in ready_clients:
		return
	ready_clients.append(client_id)
	
	for client in clients :
		if client not in ready_clients:
			return
			
	spawn_players()
	await get_tree().create_timer(1).timeout
	
	for ready_client_id in ready_clients:
		s_start_match.rpc_id(ready_client_id)
		
	ready_clients.clear()
	set_physics_process(true)

func spawn_players()->void:
	var spawn_points := get_tree().get_nodes_in_group("SpawnPoints")
	var blue_spawn_points :Array[Node3D] = []
	var red_spawn_points :Array[Node3D] = []
	
	for spawn_point in spawn_points:
		if spawn_point.name.begins_with("Blue"):
			blue_spawn_points.append(spawn_point)
		elif  spawn_point.name.begins_with("Red"):
			red_spawn_points.append(spawn_point)
			
	ready_clients.shuffle() # embaralha array com os clientes prontos
	
	for i in ready_clients.size():
		var team := 0 
		var spawn_tform := Transform3D.IDENTITY
		if i%2 == 0 :
			team = 0 
			spawn_tform = blue_spawn_points[0].global_transform # utilizando o global pra garantir que vai ser pego certo independente da hierarquia
			blue_spawn_points.pop_front()
			
		else :
			team = 1
			spawn_tform = red_spawn_points[0].global_transform
			red_spawn_points.pop_front()
		var player :CharacterBody3D = preload("res://player/player_server.tscn").instantiate()
		player.name = str(ready_clients[i])
		player.global_transform = spawn_tform
		add_child(player, true)
		
		for ready_client_id in ready_clients :
			s_spawn_player.rpc_id(ready_client_id, ready_clients[i], spawn_tform, team)
			

@rpc ("authority", "call_remote", "reliable")
func s_spawn_player(client_id : int , spawn_tform :Transform3D , team:int)->void:
	pass
		 
@rpc("authority", "call_remote", "reliable")
func s_start_match()->void:
	pass
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(playerState:Dictionary)->void:
	#atribuindo ao state global dos jogadores o valor recebido por RPC das posições
	world_state.ps[multiplayer.get_remote_sender_id()] = playerState 
	
	
	
