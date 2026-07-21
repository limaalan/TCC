extends RefCounted

const NETWORK_FILE_KEY := "network"
const CLIENT_FPS_FILE_KEY := "client_fps"

const NETWORK_HEADER := [
	"timestamp_ms",
	"elapsed_sec",
	"players_count",
	"lobbies_count",
	"rtt_avg_ms",
	"rtt_max_ms",
	"rtt_variance_avg_ms",
	"packet_loss_avg_percent",
	"packet_loss_max_percent",
	"sent_kib_per_sec",
	"received_kib_per_sec",
	"sent_packets_per_sec",
	"received_packets_per_sec",
	"server_physics_process_ms",
	"server_physics_process_ms_sum",
]

const CLIENT_FPS_HEADER := [
	"timestamp_ms",
	"elapsed_sec",
	"players_count",
	"peer_id",
	"client_fps",
]

static func make_logger_headers() -> Dictionary:
	return {
		NETWORK_FILE_KEY: NETWORK_HEADER,
		CLIENT_FPS_FILE_KEY: CLIENT_FPS_HEADER,
	}

static func build_network_row(
	sample_timestamp_ms: int,
	elapsed_sec: float,
	players_count: int,
	lobbies_count: int,
	rtt_avg_ms,
	rtt_max_ms,
	rtt_variance_avg_ms,
	packet_loss_avg_percent,
	packet_loss_max_percent,
	sent_kib_per_sec: float,
	received_kib_per_sec: float,
	sent_packets_per_sec: float,
	received_packets_per_sec: float,
	server_physics_process_ms: float,
	server_physics_process_ms_sum: float
) -> Dictionary:
	return {
		"timestamp_ms": sample_timestamp_ms,
		"elapsed_sec": elapsed_sec,
		"players_count": players_count,
		"lobbies_count": lobbies_count,
		"rtt_avg_ms": rtt_avg_ms,
		"rtt_max_ms": rtt_max_ms,
		"rtt_variance_avg_ms": rtt_variance_avg_ms,
		"packet_loss_avg_percent": packet_loss_avg_percent,
		"packet_loss_max_percent": packet_loss_max_percent,
		"sent_kib_per_sec": sent_kib_per_sec,
		"received_kib_per_sec": received_kib_per_sec,
		"sent_packets_per_sec": sent_packets_per_sec,
		"received_packets_per_sec": received_packets_per_sec,
		"server_physics_process_ms": server_physics_process_ms,
		"server_physics_process_ms_sum": server_physics_process_ms_sum,
	}

static func build_client_fps_rows(
	sample_timestamp_ms: int,
	elapsed_sec: float,
	players_count: int,
	peer_ids: Array[int],
	client_fps_by_peer: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for peer_id in peer_ids:
		rows.append({
			"timestamp_ms": sample_timestamp_ms,
			"elapsed_sec": elapsed_sec,
			"players_count": players_count,
			"peer_id": peer_id,
			"client_fps": sanitize_float(client_fps_by_peer.get(peer_id, null)),
		})
	return rows

static func build_client_fps_payload(peer_ids: Array[int], client_fps_by_peer: Dictionary) -> Array[Dictionary]:
	var payload: Array[Dictionary] = []
	for peer_id in peer_ids:
		var client_fps = sanitize_float(client_fps_by_peer.get(peer_id, null))
		if client_fps == null:
			continue

		payload.append({
			"peer_id": peer_id,
			"fps": client_fps,
		})
	return payload

static func build_peer_payload(
	peer_id: int,
	rtt_ms: float,
	last_rtt_ms: float,
	rtt_variance_ms: float,
	packet_loss_percent: float,
	app_ping_ms,
	client_fps
) -> Dictionary:
	return {
		"peer_id": peer_id,
		"rtt_ms": rtt_ms,
		"last_rtt_ms": last_rtt_ms,
		"rtt_variance_ms": rtt_variance_ms,
		"packet_loss_percent": packet_loss_percent,
		"app_ping_ms": sanitize_float(app_ping_ms),
		"client_fps": sanitize_float(client_fps),
	}

static func average_or_null(values: Array[float]):
	if values.is_empty():
		return null

	var total := 0.0
	for value in values:
		total += value
	return total / values.size()

static func max_or_null(values: Array[float]):
	if values.is_empty():
		return null

	var max_value := values[0]
	for value in values:
		max_value = maxf(max_value, value)
	return max_value

static func sanitize_float(value):
	if value == null:
		return null

	var numeric := float(value)
	if is_nan(numeric) or is_inf(numeric):
		return null
	return numeric
