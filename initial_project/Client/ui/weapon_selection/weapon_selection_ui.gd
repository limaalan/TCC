extends Control
@onready var auto_select_timer: Timer = $AutoSelectTimer

func activate() ->void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	auto_select_timer.start()

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
