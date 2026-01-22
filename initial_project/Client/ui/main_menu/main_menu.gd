extends Control



func _on_play_button_pressed() -> void:
	Server.try_connect_client_to_lobby()
	$QuickPlayConnectionUI.activate()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
