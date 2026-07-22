extends Node

var _window_has_focus := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var window := get_window()
	_window_has_focus = window.has_focus()
	window.focus_entered.connect(_on_window_focus_entered)
	window.focus_exited.connect(_on_window_focus_exited)
	_apply_gui_input_state()


func accepts_input() -> bool:
	return _window_has_focus


func _input(event: InputEvent) -> void:
	if _window_has_focus:
		return

	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()


func _on_window_focus_entered() -> void:
	_window_has_focus = true
	_apply_gui_input_state()


func _on_window_focus_exited() -> void:
	_window_has_focus = false
	_apply_gui_input_state()


func _apply_gui_input_state() -> void:
	get_viewport().gui_disable_input = not _window_has_focus
