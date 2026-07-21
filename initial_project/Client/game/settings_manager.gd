extends Node

const SETTINGS_PATH := "user://settings.cfg"

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen_enabled := false


func _ready() -> void:
	load_settings()
	apply_audio_settings()
	_apply_fullscreen_setting()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	set_bus_volume(MASTER_BUS, master_volume)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	set_bus_volume(MUSIC_BUS, music_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	set_bus_volume(SFX_BUS, sfx_volume)
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen_enabled = enabled
	_apply_fullscreen_setting()
	save_settings()


func apply_audio_settings() -> void:
	set_bus_volume(MASTER_BUS, master_volume)
	set_bus_volume(MUSIC_BUS, music_volume)
	set_bus_volume(SFX_BUS, sfx_volume)


func set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return

	value = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, is_zero_approx(value))

	if value > 0.0:
		AudioServer.set_bus_volume_linear(bus_index, value)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_warning("Could not load settings: %s" % error_string(error))
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen", fullscreen_enabled))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen_enabled)

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))


func _apply_fullscreen_setting() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
