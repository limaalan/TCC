extends Node

var _application_has_focus := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_sync_focus_from_window")


func _process(_delta: float) -> void:
	_sync_focus_from_window()


func accepts_input() -> bool:
	return _application_has_focus


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_set_application_focus(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_set_application_focus(false)


func _input(event: InputEvent) -> void:
	if _application_has_focus:
		return

	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()


func _set_application_focus(has_focus: bool) -> void:
	if _application_has_focus == has_focus:
		return

	_application_has_focus = has_focus
	_apply_gui_input_state()


func _sync_focus_from_window() -> void:
	var window := get_window()
	if not is_instance_valid(window):
		return

	_set_application_focus(window.has_focus())


func _apply_gui_input_state() -> void:
	get_viewport().gui_disable_input = not _application_has_focus
