extends Node

const DEFAULT_REPORT_INTERVAL_SEC := 0.25

var server_node: Node = null
var report_timer := Timer.new()

func setup(p_server_node: Node, interval_sec: float = DEFAULT_REPORT_INTERVAL_SEC) -> void:
	server_node = p_server_node
	report_timer.wait_time = maxf(interval_sec, 0.05)
	report_timer.one_shot = false
	add_child(report_timer)
	report_timer.timeout.connect(_on_report_timer_timeout)

func start() -> void:
	report_timer.start()
	_on_report_timer_timeout()

func stop() -> void:
	report_timer.stop()

func _on_report_timer_timeout() -> void:
	if server_node == null:
		return

	if not server_node.has_method("is_connected_to_server"):
		return

	if not server_node.is_connected_to_server():
		return

	var fps := float(Engine.get_frames_per_second())
	if is_nan(fps) or is_inf(fps):
		return

	server_node.send_client_fps(fps)
