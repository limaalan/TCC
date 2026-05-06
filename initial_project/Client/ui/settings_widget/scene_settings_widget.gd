extends VBoxContainer
@onready var audio_check_box: CheckBox = %AudioCheckBox
@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox

func _ready () ->void :
	audio_check_box.button_pressed = not SettingsManager.mute_enabled
	fullscreen_check_box.button_pressed = SettingsManager.fullscreen_enabled


func _on_audio_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_audio_mute(not toggled_on)


func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)
