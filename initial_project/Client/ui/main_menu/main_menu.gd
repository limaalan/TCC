extends Control
const NAME_SAVE_PATH :='user://player_name.dat'
const NAME_MAX_LEN = 16

@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit

func _ready()->void:
	if (FileAccess.file_exists(NAME_SAVE_PATH)):
		var file = FileAccess.open(NAME_SAVE_PATH,FileAccess.READ)
		player_name_line_edit.text = file.get_as_text().left(NAME_MAX_LEN)
	
	AudioManager.play_music(AudioManager.MusicKeys.MenuMusic)

func _on_play_button_pressed() -> void:
	var player_name = player_name_line_edit.text
	if (player_name.is_empty()):
		player_name = "Player" + str(randi() % 1000)
		
	var file = FileAccess.open(NAME_SAVE_PATH,FileAccess.WRITE)
	file.store_string(player_name)
	
	Server.try_connect_client_to_lobby(player_name)
	$QuickPlayConnectionUI.activate()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
