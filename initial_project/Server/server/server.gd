extends Node
const PORT := 7777
const MAX_CLIENTS :=64
const MAX_LOBBIES:= 1 
const MAX_PLAYERS_PER_LOBBY :=2

var lobbies :Array[Lobby] = []
var idle_clients:Array[int]= []
var peer := ENetMultiplayerPeer.new()

func _ready() -> void: 
	var error := peer.create_server(PORT,MAX_CLIENTS)
	if error != OK:
		print("Falha ao iniciar server.")
		return
	print("Servidor iniciado.")
	
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	
	
func _on_peer_connected(id:int)-> void:
	print("cliend %d conectou-se" %id)
	idle_clients.append(id)

func _on_peer_disconnected(id:int)-> void:
	remove_client_from_lobby(id)
	
	idle_clients.erase(id)
	print("cliend %d desconectou-se do servidor" %id)
	
func remove_client_from_lobby(client_id:int)-> void:
	var maybe_lobby := get_lobby_from_client_id(client_id)
	if maybe_lobby:
		maybe_lobby.remove_client(client_id)
		
		lobby_clients_updated(maybe_lobby)
		
	if maybe_lobby.clients.is_empty():
		lobbies.erase(maybe_lobby)
		maybe_lobby.queue_free()
		print("cliend %d desconectou-se do lobby" %client_id)

	
func get_lobby_from_client_id(id:int)->Lobby:
	for lobby in lobbies :
		if lobby.clients.has(id):
			return lobby
	return null
	
@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby()-> void :
	var client_id := multiplayer.get_remote_sender_id()
	var maybe_lobby := get_non_full_lobby()

	if maybe_lobby:
		maybe_lobby.add_client(client_id)
		idle_clients.erase(client_id)
		print("Cliente %d conectou-se ao lobby %s" %[client_id, maybe_lobby.name])
		lobby_clients_updated(maybe_lobby)
		return
	s_client_cant_connect_to_lobby.rpc_id(client_id)
	
func get_non_full_lobby()->Lobby: #get or create
	for lobby in lobbies:
		print("Size:", lobby.clients.size())
		if lobby.clients.size() < MAX_PLAYERS_PER_LOBBY:
			return lobby
	if lobbies.size()< MAX_LOBBIES:
		print("Lobbies size:" , lobbies.size())
		var new_lobby := Lobby.new()
		lobbies.append(new_lobby)
		new_lobby.name = str(new_lobby.get_instance_id())
		add_child(new_lobby)
		return new_lobby
	print("Todas as salas estão cheias.")
	return null
	
func lobby_clients_updated(lobby: Lobby)->void:
	for client_id in lobby.clients:
		s_lobby_clients_updated.rpc_id(client_id, lobby.clients.size(), MAX_PLAYERS_PER_LOBBY)

@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(connected_clients:int, max_clients:int)->void:
	pass 

@rpc("authority", "call_remote", "reliable")
func s_client_cant_connect_to_lobby()-> void:
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func c_cancel_quick_play_search()->void:
	var client_id = multiplayer.get_remote_sender_id()
	remove_client_from_lobby(client_id)
