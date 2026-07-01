extends Node
const NetworkConfig = preload("res://shared/network_config.gd")
const NetworkMetricsLogger = preload("res://server/network_metrics_logger.gd")
const MAX_CLIENTS :=64
const MAX_LOBBIES:= 1
const MAX_PLAYERS_PER_LOBBY :=2
const DISTANCE_BETWEEN_LOBBIES = 100

var lobbies :Array[Lobby] = []
var idle_clients:Array[int]= []
var lobby_spots : Array[Lobby] = []
var peer := ENetMultiplayerPeer.new()
var metrics_logger := NetworkMetricsLogger.new("server")
var metrics_timer := Timer.new()
var latest_app_ping_by_peer: Dictionary = {}

func _ready() -> void:
	var port := NetworkConfig.get_server_port()
	var error := peer.create_server(port,MAX_CLIENTS)
	if error != OK:
		print("Falha ao iniciar server na porta %s." % port)
		return
	print("Servidor iniciado na porta %s." % port)

	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)

	lobby_spots.resize(MAX_LOBBIES)
	_setup_metrics_logging()

func _on_peer_connected(id:int)-> void:
	print("cliend %d conectou-se" %id)
	idle_clients.append(id)

func _on_peer_disconnected(id:int)-> void:
	remove_client_from_lobby(id)
	latest_app_ping_by_peer.erase(id)

	idle_clients.erase(id)
	print("cliend %d desconectou-se do servidor" %id)

func remove_client_from_lobby(client_id:int)-> void:
	var maybe_lobby := get_lobby_from_client_id(client_id)
	if maybe_lobby:
		maybe_lobby.remove_client(client_id)
		if is_instance_valid(maybe_lobby):
			lobby_clients_updated(maybe_lobby)

	print("cliend %d desconectou-se do lobby" %client_id)

func get_lobby_from_client_id(id:int)->Lobby:
	for lobby in lobbies :
		if lobby.client_data.keys().has(id):
			return lobby
	return null

func get_connected_peer_ids() -> Array[int]:
	var connected_peer_ids: Array[int] = []
	for lobby in lobbies:
		connected_peer_ids.append_array(lobby.get_connected_clients())
	return connected_peer_ids

func _setup_metrics_logging() -> void:
	metrics_logger.configure_from_args()
	if not metrics_logger.is_enabled():
		return

	metrics_timer.wait_time = metrics_logger.get_sample_interval_sec()
	metrics_timer.one_shot = false
	add_child(metrics_timer)
	metrics_logger.reset_sample_window()
	metrics_timer.timeout.connect(_on_metrics_timer_timeout)
	metrics_timer.start()

func _packet_loss_percent(peer_ref: ENetPacketPeer) -> float:
	return 100.0 * peer_ref.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS) / ENetPacketPeer.PACKET_LOSS_SCALE

func _on_metrics_timer_timeout() -> void:
	if not metrics_logger.is_enabled():
		return

	var host := peer.host
	if host == null:
		return

	var sample_timestamp_ms := floori(Time.get_unix_time_from_system() * 1000)
	var elapsed_sec := metrics_logger.consume_elapsed_seconds(sample_timestamp_ms)
	var sent_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	var sent_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
	var received_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	var received_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS)
	var connected_peer_ids := get_connected_peer_ids()
	if connected_peer_ids.is_empty():
		return

	var rows: Array[Dictionary] = []
	var players_count := connected_peer_ids.size()
	for peer_id in connected_peer_ids:
		var peer_ref := peer.get_peer(peer_id)
		if peer_ref == null or not peer_ref.is_active():
			continue

		rows.append({
			"timestamp_ms": sample_timestamp_ms,
			"role": "server",
			"players_count": players_count,
			"peer_id": peer_id,
			"rtt_ms": peer_ref.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME),
			"last_rtt_ms": peer_ref.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME),
			"rtt_variance": peer_ref.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME_VARIANCE),
			"packet_loss_percent": _packet_loss_percent(peer_ref),
			"sent_kbps": sent_bytes / 1024.0 / elapsed_sec,
			"received_kbps": received_bytes / 1024.0 / elapsed_sec,
			"sent_packets_per_sec": sent_packets / elapsed_sec,
			"received_packets_per_sec": received_packets / elapsed_sec,
			"app_ping_ms": latest_app_ping_by_peer.get(peer_id, null),
			"fps": null,
		})

	metrics_logger.append_rows(rows)

#Associa um lobby a uma coordenada 3d
func update_lobby_spots() ->void:
	for lobby in lobbies:
		if lobby in lobby_spots:
			continue
		for i in lobby_spots.size():
			if lobby_spots[i] == null :
				lobby_spots[i] = lobby
				lobby.global_position.y = DISTANCE_BETWEEN_LOBBIES*i
				break

	for i in lobby_spots.size():
		if lobby_spots[i] != null and lobby_spots[i] not  in lobbies:
			lobby_spots[i] = null

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby(player_name:String)-> void :
	var client_id := multiplayer.get_remote_sender_id()
	var maybe_lobby := get_non_full_lobby()

	if maybe_lobby:
		maybe_lobby.add_client(client_id,player_name)
		idle_clients.erase(client_id)
		lobby_clients_updated(maybe_lobby)
		if maybe_lobby.client_data.keys().size() >= MAX_PLAYERS_PER_LOBBY:
			lock_lobby(maybe_lobby)

		print("Cliente %d conectou-se ao lobby %s" %[client_id, maybe_lobby.name])
		return
	s_client_cant_connect_to_lobby.rpc_id(client_id)

func lock_lobby(lobby:Lobby)->void:
	lobby.status = Lobby.LOCKED
	create_lobby_on_clients(lobby)

func create_lobby_on_clients(lobby:Lobby)->void:
	for lobby_client_id in lobby.client_data.keys():
		s_create_lobby_on_clients.rpc_id(lobby_client_id, lobby.name)
@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name:String)->void:
	pass

func get_non_full_lobby()->Lobby: #get or create
	for lobby in lobbies:
		if lobby.status != Lobby.IDLE:
			continue
		print("Size:", lobby.client_data.keys().size())
		if lobby.client_data.keys().size() < MAX_PLAYERS_PER_LOBBY:

			return lobby
	if lobbies.size()< MAX_LOBBIES:
		print("Lobbies size:" , lobbies.size())
		var new_lobby := Lobby.new()
		lobbies.append(new_lobby)
		new_lobby.name = str(new_lobby.get_instance_id())
		add_child(new_lobby)
		update_lobby_spots()
		return new_lobby
	print("Todas as salas estao cheias.")
	return null

func lobby_clients_updated(lobby: Lobby)->void:
	for client_id in lobby.get_connected_clients():
		s_lobby_clients_updated.rpc_id(client_id, lobby.client_data.keys().size(), MAX_PLAYERS_PER_LOBBY)

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

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func c_get_server_clock_time(client_clock_time:int)->void:
	s_return_server_clock_time.rpc_id(multiplayer.get_remote_sender_id(), floori(Time.get_unix_time_from_system()*1000),client_clock_time )

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_report_app_ping(app_ping_ms: float) -> void:
	var client_id := multiplayer.get_remote_sender_id()
	latest_app_ping_by_peer[client_id] = app_ping_ms

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func s_return_server_clock_time(server_clock_time:int, old_client_clock_time:int)->void:
	pass

func delete_lobby(lobby:Lobby)->void:
	lobbies.erase(lobby)
	update_lobby_spots()
	lobby.queue_free()
