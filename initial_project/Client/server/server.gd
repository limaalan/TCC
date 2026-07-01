extends Node
const NetworkConfig = preload("res://shared/network_config.gd")
const NetworkMetricsLogger = preload("res://server/network_metrics_logger.gd")
const Lobby = preload("res://server/lobby.gd")
signal on_lobby_clients_updated(connected_clients:int, max_clients:int)
signal on_cant_connect_to_lobby()
signal on_lobby_locked

@onready var clock_sync_timer: Timer = $ClockSyncTimer
var clock_deviation_ms:= 0
const CLOCK_DEVIATION_CALC_WEIGHT= 0.5

var peer := ENetMultiplayerPeer.new()
var metrics_logger := NetworkMetricsLogger.new("client")
var metrics_timer := Timer.new()
var latest_app_ping_ms := -1.0
var last_known_players_count := 0

func _ready() -> void:
	var server_address := NetworkConfig.get_server_address()
	var server_port := NetworkConfig.get_server_port()
	var error := peer.create_client(server_address, server_port)
	if error != OK:
		print("Cliente falhou ao conectar em %s:%s" % [server_address, server_port])
		return
	print("Cliente tentando conectar em %s:%s" % [server_address, server_port])

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_setup_metrics_logging()

func _on_connected_to_server()-> void:
	clock_sync_timer.start()
	if metrics_logger.is_enabled():
		metrics_logger.reset_sample_window()
		metrics_timer.start()
	print ("conectou-se ao servidor")

func _on_connection_failed()-> void:
	metrics_timer.stop()
	print ("Falhou ao conectar-se ao servidor")

func _on_server_disconnected() -> void:
	metrics_timer.stop()
	last_known_players_count = 0
	latest_app_ping_ms = -1.0
	print("Servidor desconectado")

func _setup_metrics_logging() -> void:
	metrics_logger.configure_from_args()
	if not metrics_logger.is_enabled():
		return

	metrics_timer.wait_time = metrics_logger.get_sample_interval_sec()
	metrics_timer.one_shot = false
	add_child(metrics_timer)
	metrics_timer.timeout.connect(_on_metrics_timer_timeout)

func _packet_loss_percent(peer_ref: ENetPacketPeer) -> float:
	return 100.0 * peer_ref.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS) / ENetPacketPeer.PACKET_LOSS_SCALE

func _get_current_players_count() -> int:
	var lobby_nodes := get_tree().get_nodes_in_group(ClientNames.GROUP_LOBBY)
	if not lobby_nodes.is_empty():
		var lobby_node := lobby_nodes[0]
		if lobby_node is Lobby and lobby_node.players.size() > 0:
			return lobby_node.players.size()

	return last_known_players_count

func _on_metrics_timer_timeout() -> void:
	if not metrics_logger.is_enabled():
		return

	var host := peer.host
	var server_peer := peer.get_peer(1)
	if host == null or server_peer == null or not server_peer.is_active():
		return

	var sample_timestamp_ms := floori(Time.get_unix_time_from_system() * 1000)
	var elapsed_sec := metrics_logger.consume_elapsed_seconds(sample_timestamp_ms)
	var sent_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	var sent_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
	var received_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	var received_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS)
	var rows: Array[Dictionary] = []
	rows.append({
		"timestamp_ms": sample_timestamp_ms,
		"role": "client",
		"players_count": _get_current_players_count(),
		"peer_id": 1,
		"rtt_ms": server_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME),
		"last_rtt_ms": server_peer.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME),
		"rtt_variance": server_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME_VARIANCE),
		"packet_loss_percent": _packet_loss_percent(server_peer),
		"sent_kbps": sent_bytes / 1024.0 / elapsed_sec,
		"received_kbps": received_bytes / 1024.0 / elapsed_sec,
		"sent_packets_per_sec": sent_packets / elapsed_sec,
		"received_packets_per_sec": received_packets / elapsed_sec,
		"app_ping_ms": latest_app_ping_ms if latest_app_ping_ms >= 0.0 else null,
		"fps": Engine.get_frames_per_second(),
	})
	metrics_logger.append_rows(rows)

func try_connect_client_to_lobby(player_name:String)-> void:
	c_try_connect_client_to_lobby.rpc_id(1,player_name)

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby(player_name:String)-> void :
	pass

@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name:String)->void:
	var lobby = Lobby.new()
	lobby.name = lobby_name
	add_child(lobby,true)
	on_lobby_locked.emit()

@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(connected_clients:int, max_clients:int)->void:
	last_known_players_count = connected_clients
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
	c_get_server_clock_time.rpc_id(1, floori(Time.get_unix_time_from_system()*1000))

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func c_get_server_clock_time(client_clock_time:int)->void:
	pass

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_report_app_ping(app_ping_ms: float) -> void:
	pass

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func s_return_server_clock_time(server_clock_time:int, old_client_clock_time:int)->void:
	var current_time_ms := floori(Time.get_unix_time_from_system() * 1000)
	var local_time_when_server_sent_time = (current_time_ms + old_client_clock_time) / 2
	clock_deviation_ms = lerp(clock_deviation_ms, local_time_when_server_sent_time - server_clock_time,CLOCK_DEVIATION_CALC_WEIGHT)
	latest_app_ping_ms = maxf(current_time_ms - old_client_clock_time, 0.0)
	c_report_app_ping.rpc_id(1, latest_app_ping_ms)
