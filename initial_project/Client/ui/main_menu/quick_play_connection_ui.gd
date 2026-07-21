extends Control
const ServerLocator = preload("res://server/server_locator.gd")

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton
var selected_mode_label := ""

func _enter_tree() -> void:
	hide()
	var server := ServerLocator.get_server(get_tree())
	if server == null:
		return

	server.on_lobby_clients_updated.connect(on_lobby_clients_updated)
	server.on_cant_connect_to_lobby.connect(on_cant_connect_to_lobby)
	server.on_lobby_locked.connect(on_lobby_locked)

func activate(mode_label: String = "")->void:
	selected_mode_label = mode_label

	var server := ServerLocator.get_server(get_tree())
	if server != null and server.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		close_button.hide()
		cancel_button.show()
		if selected_mode_label.is_empty():
			status_label.text = "Conectando-se ao lobby..."
		else:
			status_label.text = "Conectando-se ao lobby de %s..." % selected_mode_label
	else : 
		close_button.show()
		cancel_button.hide()
		status_label.text = "Voce nao esta conectado ao servidor, tente novamente."
	show()
	(close_button if close_button.visible else cancel_button).call_deferred("grab_focus")

func on_lobby_clients_updated(connected_clients:int, max_clients:int)-> void:
	if selected_mode_label.is_empty():
		status_label.text = "Procurando por jogador: %d/%d" % [connected_clients, max_clients]
	else:
		status_label.text = "Procurando jogadores para %s: %d/%d" % [selected_mode_label, connected_clients, max_clients]

func on_cant_connect_to_lobby()->void:
	status_label.text = "Nao foi possivel conectar-se ao lobby."
	cancel_button.hide()
	close_button.show()
	close_button.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		return

	if cancel_button.visible:
		_on_cancel_button_pressed()
	elif close_button.visible:
		_on_close_button_pressed()
	get_viewport().set_input_as_handled()

func _on_close_button_pressed() -> void:
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_cancel_button_pressed() -> void:
	selected_mode_label = ""
	hide()
	var server := ServerLocator.get_server(get_tree())
	if server != null:
		server.cancel_quick_play_search()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func on_lobby_locked()->void:
	selected_mode_label = ""
	status_label.text="Jogo iniciando..."
	cancel_button.hide()
	close_button.hide()
