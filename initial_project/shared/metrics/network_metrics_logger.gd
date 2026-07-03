extends RefCounted

const LEGACY_ENABLE_ARG := "--network-metrics"
const ENABLE_ARG := "--metrics"
const RECORD_ARG := "--record-metrics"
const STREAM_ARG := "--stream-metrics"
const LEGACY_INTERVAL_ARG_PREFIX := "--network-metrics-interval-ms="
const INTERVAL_ARG_PREFIX := "--metrics-interval="
const LABEL_ARG_PREFIX := "--network-metrics-label="
const STREAM_HOST_ARG_PREFIX := "--metrics-stream-host="
const STREAM_PORT_ARG_PREFIX := "--metrics-stream-port="
const ENV_ENABLE := "TCC_NETWORK_METRICS"
const ENV_INTERVAL_MS := "TCC_NETWORK_METRICS_INTERVAL_MS"
const ENV_LABEL := "TCC_NETWORK_METRICS_LABEL"
const ENV_RECORD := "TCC_RECORD_METRICS"
const ENV_STREAM := "TCC_STREAM_METRICS"
const ENV_STREAM_HOST := "TCC_METRICS_STREAM_HOST"
const ENV_STREAM_PORT := "TCC_METRICS_STREAM_PORT"
const DEFAULT_INTERVAL_MS := 1000
const DEFAULT_STREAM_HOST := "127.0.0.1"
const DEFAULT_STREAM_PORT := 8765
const METRICS_DIR := "network_metrics"
const HEADER := [
	"timestamp_ms",
	"role",
	"players_count",
	"peer_id",
	"rtt_ms",
	"last_rtt_ms",
	"rtt_variance",
	"packet_loss_percent",
	"sent_kib_per_sec",
	"received_kib_per_sec",
	"sent_packets_per_sec",
	"received_packets_per_sec",
	"server_physics_process_ms",
	"app_ping_ms",
	"fps",
]

var enabled := false
var record_enabled := false
var stream_enabled := false
var role := ""
var sample_interval_ms := DEFAULT_INTERVAL_MS
var output_path := ""
var last_sample_timestamp_ms := 0
var stream_host := DEFAULT_STREAM_HOST
var stream_port := DEFAULT_STREAM_PORT
var udp_stream_peer := PacketPeerUDP.new()

func _init(p_role: String) -> void:
	role = p_role

func configure_from_args() -> void:
	var user_args := OS.get_cmdline_user_args()
	var legacy_enabled := _has_flag(user_args, LEGACY_ENABLE_ARG) or _has_enabled_environment(ENV_ENABLE)
	var metrics_enabled := legacy_enabled or _has_flag(user_args, ENABLE_ARG)

	record_enabled = legacy_enabled
	record_enabled = record_enabled or metrics_enabled
	record_enabled = record_enabled or _has_flag(user_args, RECORD_ARG)
	record_enabled = record_enabled or _has_enabled_environment(ENV_RECORD)

	stream_enabled = _has_flag(user_args, STREAM_ARG) or _has_enabled_environment(ENV_STREAM)
	sample_interval_ms = _read_sample_interval_ms(user_args)
	stream_host = _read_string_value(user_args, STREAM_HOST_ARG_PREFIX, ENV_STREAM_HOST, DEFAULT_STREAM_HOST)
	stream_port = _sanitize_port(_read_int_value(user_args, STREAM_PORT_ARG_PREFIX, ENV_STREAM_PORT, DEFAULT_STREAM_PORT), DEFAULT_STREAM_PORT)

	if record_enabled:
		_configure_csv_output(user_args)

	if stream_enabled:
		_configure_udp_stream()

	enabled = record_enabled or stream_enabled
	if enabled:
		print("Network metrics enabled for %s." % role)

func is_enabled() -> bool:
	return enabled

func get_sample_interval_sec() -> float:
	return sample_interval_ms / 1000.0

func reset_sample_window(now_ms: int = -1) -> void:
	last_sample_timestamp_ms = now_ms if now_ms >= 0 else _now_ms()

func consume_elapsed_seconds(now_ms: int) -> float:
	if last_sample_timestamp_ms <= 0:
		last_sample_timestamp_ms = now_ms - sample_interval_ms

	var elapsed_ms: int = maxi(now_ms - last_sample_timestamp_ms, 1)
	last_sample_timestamp_ms = now_ms
	return elapsed_ms / 1000.0

func append_rows(rows: Array[Dictionary]) -> void:
	if not record_enabled or rows.is_empty():
		return

	var file := FileAccess.open(output_path, FileAccess.READ_WRITE)
	if file == null:
		printerr("Could not append network metrics to %s." % output_path)
		return

	file.seek_end()
	for row in rows:
		var line_values: Array[String] = []
		for column in HEADER:
			line_values.append(_escape_csv(_format_value(row.get(column, ""))))
		file.store_line(",".join(line_values))
	file.flush()

func stream_sample(sample: Dictionary) -> void:
	if not stream_enabled or sample.is_empty():
		return

	var packet := JSON.stringify(sample).to_utf8_buffer()
	var error := udp_stream_peer.put_packet(packet)
	if error != OK:
		push_warning("Failed to send network metrics UDP packet: %s" % error)

func _configure_csv_output(user_args: PackedStringArray) -> void:
	var metrics_dir := DirAccess.open("user://")
	if metrics_dir == null:
		printerr("Could not open user:// for network metrics output.")
		record_enabled = false
		return

	var dir_error := metrics_dir.make_dir_recursive(METRICS_DIR)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		printerr("Could not create metrics directory in user://.")
		record_enabled = false
		return

	var timestamp_sec := int(Time.get_unix_time_from_system())
	var label_suffix := _build_label_suffix(user_args)
	output_path = "user://%s/%s_metrics_%s%s.csv" % [METRICS_DIR, role, str(timestamp_sec), label_suffix]
	_write_header()
	if record_enabled:
		print("Network metrics CSV enabled for %s at %s" % [role, ProjectSettings.globalize_path(output_path)])

func _configure_udp_stream() -> void:
	var error := udp_stream_peer.set_dest_address(stream_host, stream_port)
	if error != OK:
		push_warning("Failed to configure network metrics UDP stream to %s:%s." % [stream_host, stream_port])
		stream_enabled = false
		return

	print("Network metrics UDP stream enabled for %s at %s:%s" % [role, stream_host, stream_port])

func _write_header() -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not create network metrics file at %s." % output_path)
		record_enabled = false
		return

	file.store_line(",".join(HEADER))
	file.flush()

func _has_flag(user_args: PackedStringArray, flag: String) -> bool:
	for arg in user_args:
		if arg == flag:
			return true
	return false

func _has_enabled_environment(key: String) -> bool:
	if not OS.has_environment(key):
		return false

	var value := OS.get_environment(key).strip_edges().to_lower()
	return value == "1" or value == "true" or value == "yes"

func _read_sample_interval_ms(user_args: PackedStringArray) -> int:
	for arg in user_args:
		if arg.begins_with(LEGACY_INTERVAL_ARG_PREFIX):
			return max(int(arg.trim_prefix(LEGACY_INTERVAL_ARG_PREFIX)), 1)

		if arg.begins_with(INTERVAL_ARG_PREFIX):
			var interval_sec := maxf(arg.trim_prefix(INTERVAL_ARG_PREFIX).to_float(), 0.001)
			return max(int(interval_sec * 1000.0), 1)

	if OS.has_environment(ENV_INTERVAL_MS):
		return max(int(OS.get_environment(ENV_INTERVAL_MS)), 1)

	return DEFAULT_INTERVAL_MS

func _read_int_value(user_args: PackedStringArray, prefix: String, environment_key: String, fallback: int) -> int:
	for arg in user_args:
		if arg.begins_with(prefix):
			return int(arg.trim_prefix(prefix))
	if OS.has_environment(environment_key):
		return int(OS.get_environment(environment_key))
	return fallback

func _build_label_suffix(user_args: PackedStringArray) -> String:
	var raw_label := _read_string_value(user_args, LABEL_ARG_PREFIX, ENV_LABEL, "")
	if raw_label.is_empty():
		return ""
	return "_" + _sanitize_label(raw_label)

func _read_string_value(user_args: PackedStringArray, prefix: String, environment_key: String, fallback: String) -> String:
	for arg in user_args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	if OS.has_environment(environment_key):
		return OS.get_environment(environment_key)
	return fallback

func _sanitize_label(raw_label: String) -> String:
	var sanitized := ""
	for character in raw_label:
		var unicode_value := character.unicode_at(0)
		var is_letter := unicode_value >= 65 and unicode_value <= 90
		is_letter = is_letter or (unicode_value >= 97 and unicode_value <= 122)
		var is_number := unicode_value >= 48 and unicode_value <= 57
		if is_letter or is_number or character == "_" or character == "-":
			sanitized += character
		else:
			sanitized += "_"
	return sanitized.strip_edges()

func _sanitize_port(port: int, fallback: int) -> int:
	if port <= 0 or port > 65535:
		push_warning("Invalid network metrics port %s. Using default %s." % [port, fallback])
		return fallback
	return port

func _format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return ""
		TYPE_FLOAT:
			if is_nan(value) or is_inf(value):
				return ""
			return String.num(float(value), 3)
		_:
			return str(value)

func _escape_csv(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value

func _now_ms() -> int:
	return floori(Time.get_unix_time_from_system() * 1000)
