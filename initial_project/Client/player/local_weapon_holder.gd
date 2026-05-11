extends WeaponHolder
class_name LocalWeaponHolder

const RECOIL_TWEEN_TIME = 0.2

var trigger_pressed := false
var is_on_cooldown := false
var recoil_tween:Tween

func _physics_process(delta: float) -> void:
	if (trigger_pressed and not is_on_cooldown):
		shoot()
		
func shoot()->void:
	if weapon == null or weapon.data == null:
		return

	var weapon_data: WeaponPresentationData = weapon.data

	if not weapon_data.is_automatic :
		trigger_pressed = false
	
	is_on_cooldown = true
	get_tree().create_timer(weapon_data.shot_cooldown).timeout.connect(on_cooldown_timer_timeout)
	weapon.play_shoot_fx(true)
	if recoil_tween != null:
		recoil_tween.kill() # faz voltar pro começo
		
	weapon.rotation_degrees.x = weapon_data.recoil_rotation_degrees
	weapon.position.z = weapon_data.recoil_position_z
	
	recoil_tween = create_tween().set_parallel()
	recoil_tween.tween_property(weapon, "rotation:x", 0.0, RECOIL_TWEEN_TIME)
	recoil_tween.tween_property(weapon, "position:z", 0.0, RECOIL_TWEEN_TIME)
	
	get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_LOCAL_SHOT_FIRED)
	get_tree().call_group(ClientNames.GROUP_CAMERA_SHAKE, ClientNames.METHOD_ADD_NOISE, weapon_data.camera_shake_amount)
	
func start_trigger_pressed()->void:
	trigger_pressed = true

func end_trigger_pressed()->void:
	trigger_pressed = false
		
func on_cooldown_timer_timeout()->void:
	is_on_cooldown = false
