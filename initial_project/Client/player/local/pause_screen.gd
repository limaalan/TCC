extends Control


func _on_resume_button_pressed() -> void:
	get_tree().call_group("PlayerLocal", "unpause")


func _on_exit_button_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
	get_tree().call_group("Lobby", "exit_game")
