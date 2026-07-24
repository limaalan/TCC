extends Node
const Lobby = preload("res://server/lobby.gd")
const ClientMetricsReporter = preload("res://server/client_metrics_reporter.gd")
signal on_lobby_clients_updated(connected_clients:int, max_clients:int)
signal on_cant_connect_to_lobby()
signal on_lobby_locked

@onready var clock_sync_timer: Timer = $ClockSyncTimer
var clock_deviation_ms:= 0
const CLOCK_DEVIATION_CALC_WEIGHT= 0.5

var peer := ENetMultiplayerPeer.new()
var metrics_reporter := ClientMetricsReporter.new()
var latest_app_ping_ms := -1.0

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	add_child(metrics_reporter)
	metrics_reporter.setup(self)
	SettingsManager.server_endpoint_changed.connect(_on_server_endpoint_changed)
	call_deferred("_connect_using_saved_settings")


func reconnect_to_server(server_address: String, server_port: int) -> void:
	clock_sync_timer.stop()
	metrics_reporter.stop()
	latest_app_ping_ms = -1.0

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(server_address, server_port)
	if error != OK:
		print("Cliente falhou ao conectar em %s:%s" % [server_address, server_port])
		return

	multiplayer.multiplayer_peer = peer
	print("Cliente tentando conectar em %s:%s" % [server_address, server_port])


func _connect_using_saved_settings() -> void:
	var server_address := SettingsManager.server_address.strip_edges()
	if server_address.is_empty():
		push_warning("Nenhum servidor configurado. Defina o endereço nas configurações do cliente.")
		return

	reconnect_to_server(server_address, SettingsManager.server_port)


func _on_server_endpoint_changed(_address: String, _port: int) -> void:
	_connect_using_saved_settings()

func _on_connected_to_server()-> void:
	clock_sync_timer.start()
	metrics_reporter.start()
	print ("conectou-se ao servidor")

func _on_connection_failed()-> void:
	clock_sync_timer.stop()
	metrics_reporter.stop()
	print ("Falhou ao conectar-se ao servidor")

func _on_server_disconnected() -> void:
	clock_sync_timer.stop()
	metrics_reporter.stop()
	latest_app_ping_ms = -1.0
	print("Servidor desconectado")

func is_connected_to_server() -> bool:
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func send_client_fps(fps: float) -> void:
	if not is_connected_to_server():
		return

	c_report_client_fps.rpc_id(1, fps)

func try_connect_client_to_lobby(player_name: String, match_preset_id: StringName)-> void:
	if not is_connected_to_server():
		on_cant_connect_to_lobby.emit()
		return

	c_try_connect_client_to_lobby.rpc_id(1, player_name, match_preset_id)

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby(player_name: String, match_preset_id: StringName)-> void :
	pass

@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name:String)->void:
	var lobby = Lobby.new()
	lobby.name = lobby_name
	add_child(lobby,true)
	on_lobby_locked.emit()

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

func _on_clock_sync_timer_timeout() -> void:
	if not is_connected_to_server():
		return

	c_get_server_clock_time.rpc_id(1, floori(Time.get_unix_time_from_system()*1000))

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func c_get_server_clock_time(client_clock_time:int)->void:
	pass

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_report_app_ping(app_ping_ms: float) -> void:
	pass

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_report_client_fps(fps: float) -> void:
	pass

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func s_return_server_clock_time(server_clock_time:int, old_client_clock_time:int)->void:
	var current_time_ms := floori(Time.get_unix_time_from_system() * 1000)
	var local_time_when_server_sent_time = (current_time_ms + old_client_clock_time) / 2
	clock_deviation_ms = lerp(clock_deviation_ms, local_time_when_server_sent_time - server_clock_time,CLOCK_DEVIATION_CALC_WEIGHT)
	latest_app_ping_ms = maxf(current_time_ms - old_client_clock_time, 0.0)
	c_report_app_ping.rpc_id(1, latest_app_ping_ms)
