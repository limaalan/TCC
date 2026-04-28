extends Control
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

func _enter_tree() -> void:
	hide()
	Server.on_lobby_clients_updated.connect(on_lobby_clients_updated)
	Server.on_cant_connect_to_lobby.connect(on_cant_connect_to_lobby)
	Server.on_lobby_locked.connect(on_lobby_locked)
	
func activate()->void:
	if Server.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		close_button.hide()
		cancel_button.show()
		status_label.text = "Conectando-se ao lobby..."
	else : 
		close_button.show()
		cancel_button.hide()
		status_label.text = "Você não está conectado ao servidor, tente novamente."
	show()
	
func on_lobby_clients_updated(connected_clients:int, max_clients:int)-> void:
	status_label.text = "Procurando por jogador: %d/%d" % [connected_clients, max_clients]
	
func on_cant_connect_to_lobby()->void:
	status_label.text = "Não foi possível conectar-se ao lobby."
	cancel_button.hide()
	close_button.show()	


func _on_close_button_pressed() -> void:
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)


func _on_cancel_button_pressed() -> void:
	hide()
	Server.cancel_quick_play_search()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func on_lobby_locked()->void:
	status_label.text="Jogo Iniciando..."
	cancel_button.hide()
	close_button.hide()
