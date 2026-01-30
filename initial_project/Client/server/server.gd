extends Node
signal on_lobby_clients_updated(connected_clients:int, max_clients:int)
signal on_cant_connect_to_lobby()
signal on_lobby_locked

const PORT := 7777
const ADDRESS :="127.0.0.1"

@onready var clock_sync_timer: Timer = $ClockSyncTimer
var clock_deviation_ms:= 0
const CLOCK_DEVIATION_CALC_WEIGHT= 0.5

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
	clock_sync_timer.start()
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


func _on_clock_sync_timer_timeout() -> void:
	c_get_server_clock_time.rpc_id(1, floori(Time.get_unix_time_from_system()*1000))
	
#cliente mandando seu relógio
@rpc("any_peer", "call_remote", "unreliable_ordered" )
func c_get_server_clock_time(client_clock_time:int)->void:
	pass
	
#ativando quando o server manda o tempo atual
@rpc("any_peer", "call_remote", "unreliable_ordered" )
func s_return_server_clock_time(server_clock_time:int, old_client_clock_time:int)->void:
	var local_time_when_server_sent_time = (floori(Time.get_unix_time_from_system()*1000)+old_client_clock_time)/2
	clock_deviation_ms = lerp(clock_deviation_ms, local_time_when_server_sent_time - server_clock_time,CLOCK_DEVIATION_CALC_WEIGHT)
	
	
	
	
