extends Node

var _application_has_focus := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_application_has_focus = get_window().has_focus()
	_apply_gui_input_state()


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
	_application_has_focus = has_focus
	_apply_gui_input_state()


func _apply_gui_input_state() -> void:
	get_viewport().gui_disable_input = not _application_has_focus
