extends Control

const KEYBOARD_MOUSE_BINDINGS := [
	["Mover", "[W] [A] [S] [D]"],
	["Mirar", "[Mover mouse]"],
	["Atirar", "[Mouse 1]"],
	["Correr", "[Shift]"],
	["Pular", "[Espaço]"],
	["Granada", "[Q]"],
	["Trocar armas", "[1] [2] [3]"],
	["Pausar", "[Esc]"],
]

const CONTROLLER_BINDINGS := [
	["Mover", "[LS]"],
	["Mirar", "[RS]"],
	["Correr", "[L3]"],
	["Atirar", "[RT] / [RB]"],
	["Granada", "[LB] / [B]"],
	["Pular", "[A]"],
	["Trocar armas", "[DPad ← / →]"],
	["Pausar", "[Menu]"],
]

@onready var tabs: TabContainer = %Tabs
@onready var keyboard_bindings: VBoxContainer = %KeyboardBindings
@onready var controller_bindings: VBoxContainer = %ControllerBindings
@onready var back_button: Button = %BackButton

var _return_focus: Control
var _keycap_style := StyleBoxFlat.new()


func _ready() -> void:
	_configure_keycap_style()
	_populate_bindings(keyboard_bindings, KEYBOARD_MOUSE_BINDINGS)
	_populate_bindings(controller_bindings, CONTROLLER_BINDINGS)
	tabs.set_tab_title(0, "Teclado e mouse")
	tabs.set_tab_title(1, "Controle")
	hide()


func open_screen(return_focus: Control = null) -> void:
	_return_focus = return_focus
	tabs.current_tab = 1 if not Input.get_connected_joypads().is_empty() else 0
	show()
	tabs.get_tab_bar().call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		_close_screen()
		get_viewport().set_input_as_handled()


func _on_back_button_pressed() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
	_close_screen()


func _close_screen() -> void:
	hide()

	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.call_deferred("grab_focus")


func _populate_bindings(container: VBoxContainer, bindings: Array) -> void:
	for binding in bindings:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 31.0
		row.add_theme_constant_override("separation", 8)
		container.add_child(row)

		var action_label := Label.new()
		action_label.text = binding[0]
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(action_label)

		var input_label := Label.new()
		input_label.text = binding[1]
		input_label.custom_minimum_size = Vector2(122, 27)
		input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		input_label.add_theme_stylebox_override("normal", _keycap_style)
		row.add_child(input_label)


func _configure_keycap_style() -> void:
	_keycap_style.bg_color = Color(0.11, 0.12, 0.14, 1.0)
	_keycap_style.border_color = Color(0.48, 0.5, 0.55, 1.0)
	_keycap_style.set_border_width_all(1)
	_keycap_style.set_corner_radius_all(4)
	_keycap_style.content_margin_left = 8.0
	_keycap_style.content_margin_right = 8.0
