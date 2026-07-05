extends Control
const NAME_SAVE_PATH :='user://player_name.dat'
const NAME_MAX_LEN = 16
const MatchPresetRegistry = preload("res://shared/match_preset_registry.gd")
const ServerLocator = preload("res://server/server_locator.gd")

@onready var match_mode_option_button: OptionButton = %MatchModeOptionButton
@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit

func _ready()->void:
	if (FileAccess.file_exists(NAME_SAVE_PATH)):
		var file = FileAccess.open(NAME_SAVE_PATH,FileAccess.READ)
		player_name_line_edit.text = file.get_as_text().left(NAME_MAX_LEN)

	setup_match_mode_options()
	AudioManager.play_music(AudioManager.MusicKeys.MenuMusic)

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

	var file = FileAccess.open(NAME_SAVE_PATH,FileAccess.WRITE)
	file.store_string(player_name)

	var server := ServerLocator.get_server(get_tree())
	if server == null:
		push_warning("Server autoload is disabled.")
		return

	server.try_connect_client_to_lobby(player_name, match_preset_id)
	$QuickPlayConnectionUI.activate(match_mode_label)
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
