extends VBoxContainer

const UiIconMask = preload("res://ui/shared/icon_mask.gd")
const SPEAKER_ICON = preload("res://ui/shared/icons/speaker.png")
const ORANGE := Color("FFB814")

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var music_volume_value_label: Label = %MusicVolumeValueLabel
@onready var sfx_volume_value_label: Label = %SfxVolumeValueLabel
@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox
@onready var network_settings_container: VBoxContainer = %NetworkSettingsContainer
@onready var server_address_line_edit: LineEdit = %ServerAddressLineEdit
@onready var server_port_line_edit: LineEdit = %ServerPortLineEdit
@onready var speaker_icon: TextureRect = %SpeakerIcon


func _ready() -> void:
	speaker_icon.texture = UiIconMask.tint(SPEAKER_ICON, ORANGE, 28)
	refresh_from_settings()


func refresh_from_settings() -> void:
	master_volume_slider.set_value_no_signal(SettingsManager.master_volume * 100.0)
	music_volume_slider.set_value_no_signal(SettingsManager.music_volume * 100.0)
	sfx_volume_slider.set_value_no_signal(SettingsManager.sfx_volume * 100.0)
	fullscreen_check_box.set_pressed_no_signal(SettingsManager.fullscreen_enabled)
	server_address_line_edit.text = SettingsManager.server_address
	server_port_line_edit.text = str(SettingsManager.server_port)

	_update_volume_label(master_volume_value_label, master_volume_slider.value)
	_update_volume_label(music_volume_value_label, music_volume_slider.value)
	_update_volume_label(sfx_volume_value_label, sfx_volume_slider.value)


func set_network_settings_visible(is_visible: bool) -> void:
	network_settings_container.visible = is_visible


func focus_default_control() -> void:
	if network_settings_container.visible:
		server_address_line_edit.grab_focus()
	else:
		master_volume_slider.grab_focus()


func apply_pending_settings() -> bool:
	if not network_settings_container.visible:
		return true

	var port_text := server_port_line_edit.text.strip_edges()
	if not port_text.is_valid_int():
		return false

	return SettingsManager.set_server_endpoint(
		server_address_line_edit.text,
		port_text.to_int()
	)


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
