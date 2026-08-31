extends Control

const UiIconMask = preload("res://ui/shared/icon_mask.gd")
const CONTROLLER_ICON = preload("res://ui/shared/icons/console-controller.png")
const BACK_ICON = preload("res://ui/shared/icons/go-back-arrow.png")
const SAVE_ICON = preload("res://ui/shared/icons/save.png")
const CYAN := Color("4EC5FF")
const SAVE_ICON_COLOR := Color.WHITE

signal closed

@onready var settings_widget = %SettingsWidget
@onready var validation_label: Label = %ValidationLabel
@onready var controls_button: Button = %ControlsButton
@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton
@onready var controls_screen = %ControlsScreen

var _return_focus: Control


func _ready() -> void:
	controls_button.icon = UiIconMask.tint(CONTROLLER_ICON, CYAN, 22)
	back_button.icon = UiIconMask.tint(BACK_ICON, CYAN, 22)
	save_button.icon = UiIconMask.tint(SAVE_ICON, SAVE_ICON_COLOR, 22)
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
