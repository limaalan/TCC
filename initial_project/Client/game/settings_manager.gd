extends Node

const NetworkConfig = preload("res://shared/network_config.gd")

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SETTINGS_PATH := "res://default_settings.cfg"
const PLAYER_NAME_MAX_LENGTH := 16

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

signal server_endpoint_changed(address: String, port: int)

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen_enabled := false
var player_name := ""
var server_address := ""
var server_port := NetworkConfig.DEFAULT_PORT


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


func set_player_name(value: String) -> void:
	player_name = value.strip_edges().left(PLAYER_NAME_MAX_LENGTH)
	save_settings()


func set_server_endpoint(address: String, port: int) -> bool:
	var normalized_address := address.strip_edges()
	if normalized_address.is_empty() or port <= 0 or port > 65535:
		return false

	server_address = normalized_address
	server_port = port
	save_settings()
	server_endpoint_changed.emit(server_address, server_port)
	return true


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
	var loaded_default_settings := false

	if error == ERR_FILE_NOT_FOUND:
		error = config.load(DEFAULT_SETTINGS_PATH)
		loaded_default_settings = true

	if error != OK:
		push_warning("Could not load settings: %s" % error_string(error))
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen", fullscreen_enabled))
	player_name = String(config.get_value("profile", "player_name", player_name)).strip_edges().left(PLAYER_NAME_MAX_LENGTH)
	server_address = String(config.get_value("network", "server_address", "")).strip_edges()
	server_port = NetworkConfig.sanitize_port(int(config.get_value("network", "server_port", server_port)))

	if loaded_default_settings:
		save_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen_enabled)
	config.set_value("profile", "player_name", player_name)
	config.set_value("network", "server_address", server_address)
	config.set_value("network", "server_port", server_port)

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))


func _apply_fullscreen_setting() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
