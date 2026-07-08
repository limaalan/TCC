extends Node

const NetworkMetricsLogger = preload("res://shared/metrics/network_metrics_logger.gd")
const NetworkMetricsSampleUtils = preload("res://shared/metrics/network_metrics_sample_utils.gd")

var server: Node = null
var peer: ENetMultiplayerPeer = null
var metrics_logger := NetworkMetricsLogger.new("server")
var metrics_timer := Timer.new()

func setup(p_server: Node, p_peer: ENetMultiplayerPeer) -> void:
	server = p_server
	peer = p_peer
	metrics_logger.configure_from_args(NetworkMetricsSampleUtils.make_logger_headers())
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
	if not metrics_logger.is_enabled() or peer == null:
		return

	var host := peer.host
	if host == null:
		return

	var sample_timestamp_ms := floori(Time.get_unix_time_from_system() * 1000)
	var elapsed_sec := metrics_logger.consume_elapsed_seconds(sample_timestamp_ms)
	var lobby_player_peer_ids := _get_lobby_player_peer_ids()
	lobby_player_peer_ids.sort()

	var sent_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	var sent_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
	var received_bytes := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	var received_packets := host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS)
	var players_count := lobby_player_peer_ids.size()
	var lobbies_count := _get_lobbies_count()
	var server_physics_summary := _get_server_physics_summary()
	var latest_app_ping_by_peer := _get_app_ping_by_peer()
	var latest_client_fps_by_peer := _get_client_fps_by_peer()
	var sent_kib_per_sec := sent_bytes / 1024.0 / elapsed_sec
	var received_kib_per_sec := received_bytes / 1024.0 / elapsed_sec
	var sent_packets_per_sec := sent_packets / elapsed_sec
	var received_packets_per_sec := received_packets / elapsed_sec
	var peers_payload: Array[Dictionary] = []
	var active_peer_ids: Array[int] = []
	var rtt_values: Array[float] = []
	var rtt_variance_values: Array[float] = []
	var packet_loss_values: Array[float] = []

	for peer_id in lobby_player_peer_ids:
		var peer_ref := peer.get_peer(peer_id)
		if peer_ref == null or not peer_ref.is_active():
			continue

		var rtt_ms := float(peer_ref.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
		var last_rtt_ms := float(peer_ref.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME))
		var rtt_variance_ms := float(peer_ref.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME_VARIANCE))
		var packet_loss_percent := _packet_loss_percent(peer_ref)
		var client_fps = NetworkMetricsSampleUtils.sanitize_float(
			latest_client_fps_by_peer.get(peer_id, null)
		)

		active_peer_ids.append(peer_id)
		rtt_values.append(rtt_ms)
		rtt_variance_values.append(rtt_variance_ms)
		packet_loss_values.append(packet_loss_percent)
		peers_payload.append(
			NetworkMetricsSampleUtils.build_peer_payload(
				peer_id,
				rtt_ms,
				last_rtt_ms,
				rtt_variance_ms,
				packet_loss_percent,
				latest_app_ping_by_peer.get(peer_id, null),
				client_fps
			)
		)

	var rtt_avg_ms = NetworkMetricsSampleUtils.average_or_null(rtt_values)
	var rtt_max_ms = NetworkMetricsSampleUtils.max_or_null(rtt_values)
	var rtt_variance_avg_ms = NetworkMetricsSampleUtils.average_or_null(rtt_variance_values)
	var packet_loss_avg_percent = NetworkMetricsSampleUtils.average_or_null(packet_loss_values)
	var packet_loss_max_percent = NetworkMetricsSampleUtils.max_or_null(packet_loss_values)
	var server_physics_process_ms := float(server_physics_summary.get("max", 0.0))
	var server_physics_process_ms_sum := float(server_physics_summary.get("sum", 0.0))
	var network_row := NetworkMetricsSampleUtils.build_network_row(
		sample_timestamp_ms,
		elapsed_sec,
		players_count,
		lobbies_count,
		rtt_avg_ms,
		rtt_max_ms,
		rtt_variance_avg_ms,
		packet_loss_avg_percent,
		packet_loss_max_percent,
		sent_kib_per_sec,
		received_kib_per_sec,
		sent_packets_per_sec,
		received_packets_per_sec,
		server_physics_process_ms,
		server_physics_process_ms_sum
	)
	var client_fps_rows := NetworkMetricsSampleUtils.build_client_fps_rows(
		sample_timestamp_ms,
		elapsed_sec,
		players_count,
		active_peer_ids,
		latest_client_fps_by_peer
	)

	metrics_logger.append_rows(NetworkMetricsSampleUtils.NETWORK_FILE_KEY, [network_row])
	metrics_logger.append_rows(NetworkMetricsSampleUtils.CLIENT_FPS_FILE_KEY, client_fps_rows)
	metrics_logger.stream_sample({
		"schema_version": 2,
		"source": "godot_server",
		"role": "server",
		"timestamp_ms": sample_timestamp_ms,
		"elapsed_sec": elapsed_sec,
		"server_pid": OS.get_process_id(),
		"players_count": players_count,
		"lobbies_count": lobbies_count,
		"rtt_avg_ms": rtt_avg_ms,
		"rtt_max_ms": rtt_max_ms,
		"rtt_variance_avg_ms": rtt_variance_avg_ms,
		"packet_loss_avg_percent": packet_loss_avg_percent,
		"packet_loss_max_percent": packet_loss_max_percent,
		"server_physics_process_ms": server_physics_process_ms,
		"server_physics_process_ms_sum": server_physics_process_ms_sum,
		"sent_kib_per_sec": sent_kib_per_sec,
		"received_kib_per_sec": received_kib_per_sec,
		"sent_packets_per_sec": sent_packets_per_sec,
		"received_packets_per_sec": received_packets_per_sec,
		"peers": peers_payload,
		"client_fps": NetworkMetricsSampleUtils.build_client_fps_payload(
			active_peer_ids,
			latest_client_fps_by_peer
		),
	})

func _get_lobby_player_peer_ids() -> Array[int]:
	if server != null and server.has_method("get_lobby_player_peer_ids"):
		return server.get_lobby_player_peer_ids()
	return []

func _get_lobbies_count() -> int:
	if server != null and server.has_method("get_lobbies_count"):
		return server.get_lobbies_count()
	return 0

func _get_server_physics_summary() -> Dictionary:
	if server != null and server.has_method("get_server_physics_summary"):
		return server.get_server_physics_summary()
	return {
		"max": 0.0,
		"sum": 0.0,
	}

func _get_app_ping_by_peer() -> Dictionary:
	if server != null and server.has_method("get_app_ping_by_peer"):
		return server.get_app_ping_by_peer()
	return {}

func _get_client_fps_by_peer() -> Dictionary:
	if server != null and server.has_method("get_client_fps_by_peer"):
		return server.get_client_fps_by_peer()
	return {}
