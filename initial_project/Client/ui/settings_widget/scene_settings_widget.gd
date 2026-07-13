extends VBoxContainer

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var music_volume_value_label: Label = %MusicVolumeValueLabel
@onready var sfx_volume_value_label: Label = %SfxVolumeValueLabel
@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox


func _ready() -> void:
	master_volume_slider.set_value_no_signal(SettingsManager.master_volume * 100.0)
	music_volume_slider.set_value_no_signal(SettingsManager.music_volume * 100.0)
	sfx_volume_slider.set_value_no_signal(SettingsManager.sfx_volume * 100.0)
	fullscreen_check_box.set_pressed_no_signal(SettingsManager.fullscreen_enabled)

	_update_volume_label(master_volume_value_label, master_volume_slider.value)
	_update_volume_label(music_volume_value_label, music_volume_slider.value)
	_update_volume_label(sfx_volume_value_label, sfx_volume_slider.value)


func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
	_update_volume_label(master_volume_value_label, value)


func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)
	_update_volume_label(music_volume_value_label, value)


func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_update_volume_label(sfx_volume_value_label, value)


func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)


func _update_volume_label(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value)
