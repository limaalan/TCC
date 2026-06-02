extends WeaponHolder
class_name LocalWeaponHolder

const RECOIL_TWEEN_TIME = 0.2
const WeaponCatalog = preload("res://shared/weapons/weapon_catalog.gd")

var trigger_pressed := false
var is_on_cooldown := false
var recoil_tween: Tween


func _physics_process(delta: float) -> void:
	if trigger_pressed and not is_on_cooldown:
		shoot()


func shoot() -> void:
	if weapon == null or weapon.data == null:
		return

	var presentation_data: WeaponPresentationData = weapon.data
	var weapon_definition := WeaponCatalog.get_weapon(presentation_data.id)
	var local_player := get_local_player()
	if local_player == null:
		return

	if not weapon_definition.is_automatic:
		trigger_pressed = false

	if not local_player.try_spend_current_weapon_ammo():
		trigger_pressed = false
		return

	is_on_cooldown = true
	get_tree().create_timer(weapon_definition.shot_cooldown).timeout.connect(on_cooldown_timer_timeout)
	weapon.play_shoot_fx(true)
	if recoil_tween != null:
		recoil_tween.kill()

	weapon.rotation_degrees.x = presentation_data.recoil_rotation_degrees
	weapon.position.z = presentation_data.recoil_position_z

	recoil_tween = create_tween().set_parallel()
	recoil_tween.tween_property(weapon, "rotation:x", 0.0, RECOIL_TWEEN_TIME)
	recoil_tween.tween_property(weapon, "position:z", 0.0, RECOIL_TWEEN_TIME)

	get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_LOCAL_SHOT_FIRED)
	get_tree().call_group(ClientNames.GROUP_CAMERA_SHAKE, ClientNames.METHOD_ADD_NOISE, presentation_data.camera_shake_amount)


func start_trigger_pressed() -> void:
	trigger_pressed = true


func end_trigger_pressed() -> void:
	trigger_pressed = false


func on_cooldown_timer_timeout() -> void:
	is_on_cooldown = false


func reset_fire_state() -> void:
	trigger_pressed = false
	is_on_cooldown = false


func get_local_player() -> PlayerLocal:
	var parent_node := get_parent()
	if parent_node == null:
		return null

	return parent_node.get_parent() as PlayerLocal
