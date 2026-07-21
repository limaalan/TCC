extends Control

const WeaponRegistry = preload("res://player/weapons/weapon_registry.gd")

@onready var auto_select_timer: Timer = $AutoSelectTimer
@onready var pistol_icon: TextureRect = %PistolIcon
@onready var pistol_label: Label = %PistolLabel
@onready var smg_icon: TextureRect = %SMGIcon
@onready var smg_label: Label = %SMGLabel
@onready var shotgun_icon: TextureRect = %ShotgunIcon
@onready var shotgun_label: Label = %ShotgunLabel
@onready var pistol_button: Button = $BackGroundTexture/HBoxContainer/PistolPanel/PistolButton


func _ready() -> void:
	setup_weapon_card(GameEnums.WeaponId.PISTOL, pistol_icon, pistol_label)
	setup_weapon_card(GameEnums.WeaponId.SMG, smg_icon, smg_label)
	setup_weapon_card(GameEnums.WeaponId.SHOTGUN, shotgun_icon, shotgun_label)

func activate() ->void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	pistol_button.call_deferred("grab_focus")
	auto_select_timer.start()


func setup_weapon_card(weapon_id: int, icon: TextureRect, label: Label) -> void:
	var data := WeaponRegistry.get_weapon(weapon_id)
	icon.texture = data.selection_icon
	label.text = String(data.display_name)

func _on_pistol_button_pressed() -> void:
	weapon_selected(GameEnums.WeaponId.PISTOL)


func _on_smg_button_pressed() -> void:
	weapon_selected(GameEnums.WeaponId.SMG)


func _on_shotgun_button_pressed() -> void:
	weapon_selected(GameEnums.WeaponId.SHOTGUN)
	
func weapon_selected(weapon_id:int)->void:
	auto_select_timer.stop()
	get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_WEAPON_SELECTED, weapon_id)
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_auto_select_timer_timeout() -> void:
	weapon_selected(GameEnums.WeaponId.PISTOL)
