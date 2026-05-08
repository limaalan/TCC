extends Control


func _on_resume_button_pressed() -> void:
	get_tree().call_group(ClientNames.GROUP_PLAYER_LOCAL, ClientNames.METHOD_UNPAUSE)


func _on_exit_button_pressed() -> void:
	get_tree().call_group(ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER, ClientNames.METHOD_CHANGE_SCENE, "res://ui/main_menu/main_menu.tscn")
	get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_EXIT_GAME)
