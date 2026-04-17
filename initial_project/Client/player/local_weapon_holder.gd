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
	if not weapon.is_automatic :
		trigger_pressed = false
	
	is_on_cooldown = true
	get_tree().create_timer(weapon.shot_cooldown).timeout.connect(on_cooldown_timer_timeout)
	weapon.play_shoot_fx()
	if recoil_tween != null:
		recoil_tween.kill() # faz voltar pro começo
		
	weapon.rotation_degrees.x = 15
	weapon.position.z = 0.05
	
	recoil_tween = create_tween().set_parallel()
	recoil_tween.tween_property(weapon, "rotation:x", 0.0, RECOIL_TWEEN_TIME)
	recoil_tween.tween_property(weapon, "position:z", 0.0, RECOIL_TWEEN_TIME)
	
	get_tree().call_group("Lobby", "local_shot_fired")
	get_tree().call_group("CameraShakeComponent", "add_noise", 0.1)
	
func start_trigger_pressed()->void:
	trigger_pressed = true

func end_trigger_pressed()->void:
	trigger_pressed = false
		
func on_cooldown_timer_timeout()->void:
	is_on_cooldown = false
