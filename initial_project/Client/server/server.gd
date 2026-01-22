extends Node
signal on_lobby_clients_updated(connected_clients:int, max_clients:int)
signal on_cant_connect_to_lobby()
signal on_lobby_locked

const PORT := 7777
const ADDRESS :="127.0.0.1"


var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	var error := peer.create_client(ADDRESS, PORT)
	if error != OK:
		print("Cliente falhou ao se conectar ao servidor")
		return
		
	multiplayer.multiplayer_peer  = peer;
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
func _on_connected_to_server()-> void:
	print ("conectou-se ao servidor")
		
		
func _on_connection_failed()-> void:
	print ("Falhou ao conectar-se ao servidor")
		
func try_connect_client_to_lobby()-> void:
	c_try_connect_client_to_lobby.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby()-> void :
	pass

@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(connected_clients:int, max_clients:int)->void:
	on_lobby_clients_updated.emit(connected_clients, max_clients)
	 

@rpc("authority", "call_remote", "reliable")
func s_client_cant_connect_to_lobby()-> void:
	on_cant_connect_to_lobby.emit()
	
	
func cancel_quick_play_search()->void:
	c_cancel_quick_play_search.rpc_id(1)
	
@rpc("any_peer", "call_remote", "reliable")
func c_cancel_quick_play_search()->void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name:String)->void:
	var lobby = Lobby.new()
	lobby.name = lobby_name
	add_child(lobby,true)
	on_lobby_locked.emit()
