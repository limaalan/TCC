extends Control

signal closed

@onready var settings_widget = %SettingsWidget
@onready var validation_label: Label = %ValidationLabel
@onready var controls_button: Button = %ControlsButton
@onready var controls_screen = %ControlsScreen

var _return_focus: Control


func _ready() -> void:
	hide()


func open_screen(return_focus: Control = null, show_network_settings := true) -> void:
	_return_focus = return_focus
	settings_widget.set_network_settings_visible(show_network_settings)
	settings_widget.refresh_from_settings()
	validation_label.text = ""
	show()
	settings_widget.call_deferred("focus_default_control")


func _unhandled_input(event: InputEvent) -> void:
	if controls_screen.visible:
		return

	if visible and event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		_close_screen()
		get_viewport().set_input_as_handled()


func _on_save_button_pressed() -> void:
	if not settings_widget.apply_pending_settings():
		validation_label.text = "Informe um endereço e uma porta válidos."
		return

	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
	_close_screen()


func _on_back_button_pressed() -> void:
	settings_widget.refresh_from_settings()
	_close_screen()


func _on_controls_button_pressed() -> void:
	controls_screen.open_screen(controls_button)


func _close_screen() -> void:
	hide()
	closed.emit()

	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.call_deferred("grab_focus")
