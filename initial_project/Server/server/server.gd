extends Node
const NetworkConfig = preload("res://shared/network_config.gd")
const MatchPresetRegistry = preload("res://shared/match_preset_registry.gd")
const Lobby = preload("res://server/lobby.gd")
const ServerMetricsCollector = preload("res://server/server_metrics_collector.gd")
const MAX_CLIENTS :=64
const MAX_LOBBIES:= 2
const MAX_PLAYERS_PER_LOBBY :=4
const DISTANCE_BETWEEN_LOBBIES = 100

var lobbies :Array[Lobby] = []
var idle_clients:Array[int]= []
var lobby_spots : Array[Lobby] = []
var peer := ENetMultiplayerPeer.new()
var metrics_collector := ServerMetricsCollector.new()
var latest_app_ping_by_peer: Dictionary = {}
var latest_client_fps_by_peer: Dictionary = {}

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
	add_child(metrics_collector)
	metrics_collector.setup(self, peer)

func _on_peer_connected(id:int)-> void:
	print("cliend %d conectou-se" %id)
	idle_clients.append(id)

func _on_peer_disconnected(id:int)-> void:
	remove_client_from_lobby(id)
	latest_app_ping_by_peer.erase(id)
	latest_client_fps_by_peer.erase(id)

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
	var disconnected_lobby: Lobby = null
	for lobby in lobbies :
		if not lobby.client_data.keys().has(id):
			continue

		if lobby.client_data.get(id)[NetKeys.CONNECTED]:
			return lobby

		disconnected_lobby = lobby
	return disconnected_lobby

func get_lobby_player_peer_ids() -> Array[int]:
	var connected_peer_ids: Array[int] = []
	for lobby in lobbies:
		connected_peer_ids.append_array(lobby.get_connected_clients())
	return connected_peer_ids

func get_lobbies_count() -> int:
	return lobbies.size()

func get_server_physics_summary() -> Dictionary:
	var max_physics_process_ms := 0.0
	var sum_physics_process_ms := 0.0
	for lobby in lobbies:
		var lobby_physics_process_ms := lobby.get_last_physics_process_ms()
		max_physics_process_ms = maxf(max_physics_process_ms, lobby_physics_process_ms)
		sum_physics_process_ms += lobby_physics_process_ms

	return {
		"max": max_physics_process_ms,
		"sum": sum_physics_process_ms,
	}

func get_server_physics_process_ms() -> float:
	return float(get_server_physics_summary().get("max", 0.0))

func get_app_ping_by_peer() -> Dictionary:
	return latest_app_ping_by_peer.duplicate()

func get_client_fps_by_peer() -> Dictionary:
	return latest_client_fps_by_peer.duplicate()

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
		if lobby_spots[i] != null and lobby_spots[i] not in lobbies:
			lobby_spots[i] = null

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby(player_name: String, match_preset_id: StringName)-> void :
	var client_id := multiplayer.get_remote_sender_id()

	if not MatchPresetRegistry.is_valid_preset_id(match_preset_id):
		push_warning("Client %s requested invalid match preset '%s'." % [client_id, String(match_preset_id)])
		s_client_cant_connect_to_lobby.rpc_id(client_id)
		return

	var maybe_lobby := get_non_full_lobby(match_preset_id)

	if maybe_lobby:
		maybe_lobby.add_client(client_id,player_name)
		idle_clients.erase(client_id)
		lobby_clients_updated(maybe_lobby)
		if maybe_lobby.get_connected_clients().size() >= maybe_lobby.match_config.max_players:
			lock_lobby(maybe_lobby)

		print("Cliente %d conectou-se ao lobby %s (%s)" %[client_id, maybe_lobby.name, String(match_preset_id)])
		return
	s_client_cant_connect_to_lobby.rpc_id(client_id)

func lock_lobby(lobby:Lobby)->void:
	lobby.status = Lobby.LOCKED
	create_lobby_on_clients(lobby)

func create_lobby_on_clients(lobby:Lobby)->void:
	for lobby_client_id in lobby.get_connected_clients():
		s_create_lobby_on_clients.rpc_id(lobby_client_id, lobby.name)

@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name:String)->void:
	pass

func get_non_full_lobby(match_preset_id: StringName)->Lobby:
	for lobby in lobbies:
		if lobby.status != Lobby.IDLE:
			continue

		if lobby.match_preset_id != match_preset_id:
			continue

		print("Size:", lobby.get_connected_clients().size())
		if lobby.get_connected_clients().size() < lobby.match_config.max_players:
			return lobby
	if lobbies.size()< MAX_LOBBIES:
		print("Lobbies size:" , lobbies.size())
		return create_lobby(match_preset_id)
	print("Todas as salas estao cheias.")
	return null

func create_lobby(match_preset_id: StringName) -> Lobby:
	var new_lobby := Lobby.new()
	new_lobby.match_preset_id = match_preset_id
	new_lobby.match_config = MatchPresetRegistry.make_match_config(match_preset_id)
	new_lobby.name = "%s_%s" % [String(match_preset_id), str(new_lobby.get_instance_id())]

	lobbies.append(new_lobby)
	add_child(new_lobby)
	update_lobby_spots()

	print(
		"Lobby criado: %s | preset=%s | mode=%s | map=%s | max_players=%s"
		% [
			new_lobby.name,
			String(match_preset_id),
			str(new_lobby.match_config.mode),
			String(new_lobby.match_config.map_id),
			new_lobby.match_config.max_players
		]
	)

	return new_lobby

func lobby_clients_updated(lobby: Lobby)->void:
	var connected_clients := lobby.get_connected_clients().size()
	var max_clients := lobby.match_config.max_players

	for client_id in lobby.get_connected_clients():
		s_lobby_clients_updated.rpc_id(client_id, connected_clients, max_clients)

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

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_report_client_fps(fps: float) -> void:
	var client_id := multiplayer.get_remote_sender_id()

	if is_nan(fps) or is_inf(fps):
		return

	latest_client_fps_by_peer[client_id] = clampf(fps, 0.0, 1000.0)

@rpc("any_peer", "call_remote", "unreliable_ordered" )
func s_return_server_clock_time(server_clock_time:int, old_client_clock_time:int)->void:
	pass

func delete_lobby(lobby:Lobby)->void:
	lobbies.erase(lobby)
	update_lobby_spots()
	lobby.queue_free()
