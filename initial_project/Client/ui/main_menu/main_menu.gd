extends Control
const MatchPresetRegistry = preload("res://shared/match_preset_registry.gd")
const ServerLocator = preload("res://server/server_locator.gd")

@onready var match_mode_option_button: OptionButton = %MatchModeOptionButton
@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit
@onready var server_warning_label: Label = %ServerWarningLabel
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_screen = %SettingsScreen
@onready var quick_play_connection_ui = $QuickPlayConnectionUI

func _ready()->void:
	player_name_line_edit.text = SettingsManager.player_name
	_update_server_warning()
	SettingsManager.server_endpoint_changed.connect(_on_server_endpoint_changed)
	quick_play_connection_ui.active_changed.connect(_on_quick_play_active_changed)

	setup_match_mode_options()
	AudioManager.play_music(AudioManager.MusicKeys.MenuMusic)
	play_button.call_deferred("grab_focus")

func setup_match_mode_options() -> void:
	match_mode_option_button.clear()

	match_mode_option_button.add_item(MatchPresetRegistry.get_display_name(MatchPresetRegistry.TDM_HIGHRISE))
	match_mode_option_button.set_item_metadata(0, MatchPresetRegistry.TDM_HIGHRISE)

	match_mode_option_button.add_item(MatchPresetRegistry.get_display_name(MatchPresetRegistry.KOTH_HIGHRISE))
	match_mode_option_button.set_item_metadata(1, MatchPresetRegistry.KOTH_HIGHRISE)

	match_mode_option_button.select(0)

func _on_play_button_pressed() -> void:
	var player_name = player_name_line_edit.text
	if (player_name.is_empty()):
		player_name = "Player" + str(randi() % 1000)

	var selected_index := match_mode_option_button.selected
	if selected_index < 0:
		push_warning("Select a game mode before entering queue.")
		return

	var match_preset_id: StringName = match_mode_option_button.get_item_metadata(selected_index)
	var match_mode_label := MatchPresetRegistry.get_display_name(match_preset_id)

	SettingsManager.set_player_name(player_name)

	var server := ServerLocator.get_server(get_tree())
	if server == null:
		push_warning("Server autoload is disabled.")
		return

	server.try_connect_client_to_lobby(player_name, match_preset_id)
	quick_play_connection_ui.activate(match_mode_label)
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	settings_screen.open_screen(settings_button, true)


func _on_server_endpoint_changed(_address: String, _port: int) -> void:
	_update_server_warning()


func _update_server_warning() -> void:
	server_warning_label.visible = SettingsManager.server_address.strip_edges().is_empty()


func _on_quick_play_active_changed(is_active: bool) -> void:
	var menu_controls: Array[Control] = [
		match_mode_option_button,
		player_name_line_edit,
		play_button,
		exit_button,
		settings_button,
	]

	for control in menu_controls:
		control.focus_mode = Control.FOCUS_NONE if is_active else Control.FOCUS_ALL

	match_mode_option_button.disabled = is_active
	play_button.disabled = is_active
	exit_button.disabled = is_active
	settings_button.disabled = is_active
	player_name_line_edit.editable = not is_active

	if not is_active:
		play_button.call_deferred("grab_focus")
