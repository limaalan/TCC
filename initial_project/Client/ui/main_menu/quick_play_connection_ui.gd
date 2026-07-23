extends Control
const ServerLocator = preload("res://server/server_locator.gd")

@onready var status_label: Label = %StatusLabel
@onready var close_button: Button = %CloseButton
@onready var cancel_button: Button = %CancelButton
var selected_mode_label := ""


func _enter_tree() -> void:
	hide()
	var server := ServerLocator.get_server(get_tree())
	if server == null:
		return

	server.on_lobby_clients_updated.connect(on_lobby_clients_updated)
	server.on_cant_connect_to_lobby.connect(on_cant_connect_to_lobby)
	server.on_lobby_locked.connect(on_lobby_locked)


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


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
		status_label.text = "Você não está conectado ao servidor. Tente novamente."
	show()
	(close_button if close_button.visible else cancel_button).call_deferred("grab_focus")

func on_lobby_clients_updated(connected_clients:int, max_clients:int)-> void:
	if selected_mode_label.is_empty():
		status_label.text = "Procurando por jogador: %d/%d" % [connected_clients, max_clients]
	else:
		status_label.text = "Procurando jogadores para %s: %d/%d" % [selected_mode_label, connected_clients, max_clients]

func on_cant_connect_to_lobby()->void:
	status_label.text = "Não foi possível conectar-se ao lobby."
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


func _apply_responsive_layout() -> void:
	var viewport_width := get_viewport_rect().size.x
	var content_width := clampf(viewport_width * 0.72, 280.0, 560.0)
	var status_font_size := clampi(roundi(viewport_width * 0.035), 20, 28)
	var button_width := clampf(viewport_width * 0.3, 180.0, 240.0)
	var button_font_size := clampi(roundi(viewport_width * 0.028), 18, 22)

	status_label.custom_minimum_size = Vector2(content_width, 72.0)
	status_label.add_theme_font_size_override("font_size", status_font_size)

	for button in [close_button, cancel_button]:
		button.custom_minimum_size = Vector2(button_width, 48.0)
		button.add_theme_font_size_override("font_size", button_font_size)
