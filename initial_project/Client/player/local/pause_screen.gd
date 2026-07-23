extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var settings_screen = %SettingsScreen


func focus_default_control() -> void:
	resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if settings_screen.visible:
		return

	if visible and event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	get_tree().call_group(ClientNames.GROUP_PLAYER_LOCAL, ClientNames.METHOD_UNPAUSE)


func _on_exit_button_pressed() -> void:
	get_tree().call_group(ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER, ClientNames.METHOD_CHANGE_SCENE, "res://ui/main_menu/main_menu.tscn")
	get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_EXIT_GAME)


func _on_settings_button_pressed() -> void:
	settings_screen.open_screen(settings_button, false)
