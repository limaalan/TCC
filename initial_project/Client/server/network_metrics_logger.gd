extends RefCounted

const ENABLE_ARG := "--network-metrics"
const INTERVAL_ARG_PREFIX := "--network-metrics-interval-ms="
const LABEL_ARG_PREFIX := "--network-metrics-label="
const ENV_ENABLE := "TCC_NETWORK_METRICS"
const ENV_INTERVAL_MS := "TCC_NETWORK_METRICS_INTERVAL_MS"
const ENV_LABEL := "TCC_NETWORK_METRICS_LABEL"
const DEFAULT_INTERVAL_MS := 1000
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
	"sent_kbps",
	"received_kbps",
	"sent_packets_per_sec",
	"received_packets_per_sec",
	"app_ping_ms",
	"fps",
]

var enabled := false
var role := ""
var sample_interval_ms := DEFAULT_INTERVAL_MS
var output_path := ""
var last_sample_timestamp_ms := 0

func _init(p_role: String) -> void:
	role = p_role

func configure_from_args() -> void:
	var user_args := OS.get_cmdline_user_args()
	enabled = _has_enable_flag(user_args) or _has_enabled_environment()
	sample_interval_ms = max(_read_int_value(user_args, INTERVAL_ARG_PREFIX, ENV_INTERVAL_MS, DEFAULT_INTERVAL_MS), 1)

	if not enabled:
		return

	var metrics_dir := DirAccess.open("user://")
	if metrics_dir == null:
		printerr("Could not open user:// for network metrics output.")
		enabled = false
		return

	var dir_error := metrics_dir.make_dir_recursive(METRICS_DIR)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		printerr("Could not create metrics directory in user://.")
		enabled = false
		return

	var timestamp_sec := int(Time.get_unix_time_from_system())
	var label_suffix := _build_label_suffix(user_args)
	output_path = "user://%s/%s_metrics_%s%s.csv" % [METRICS_DIR, role, str(timestamp_sec), label_suffix]
	_write_header()
	print("Network metrics logging enabled for %s at %s" % [role, ProjectSettings.globalize_path(output_path)])

func is_enabled() -> bool:
	return enabled

func get_sample_interval_sec() -> float:
	return sample_interval_ms / 1000.0

func reset_sample_window(now_ms: int = -1) -> void:
	last_sample_timestamp_ms = now_ms if now_ms >= 0 else _now_ms()

func consume_elapsed_seconds(now_ms: int) -> float:
	if last_sample_timestamp_ms <= 0:
		last_sample_timestamp_ms = now_ms - sample_interval_ms

	var elapsed_ms := max(now_ms - last_sample_timestamp_ms, 1)
	last_sample_timestamp_ms = now_ms
	return elapsed_ms / 1000.0

func append_rows(rows: Array[Dictionary]) -> void:
	if not enabled or rows.is_empty():
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
		file.store_line(PackedStringArray(line_values).join(","))
	file.flush()

func _write_header() -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not create network metrics file at %s." % output_path)
		enabled = false
		return

	file.store_line(PackedStringArray(HEADER).join(","))
	file.flush()

func _has_enable_flag(user_args: PackedStringArray) -> bool:
	for arg in user_args:
		if arg == ENABLE_ARG:
			return true
	return false

func _has_enabled_environment() -> bool:
	if not OS.has_environment(ENV_ENABLE):
		return false
	var value := OS.get_environment(ENV_ENABLE).strip_edges().to_lower()
	return value == "1" or value == "true" or value == "yes"

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
