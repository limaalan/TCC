extends Node3D
class_name WeaponHolder

const WeaponPresentationData = preload("res://player/weapons/weapon_presentation_data.gd")
const WeaponRegistry = preload("res://player/weapons/weapon_registry.gd")

var weapon:Weapon 

func instantiate_weapon(weapon_id:int)->void:
	if weapon != null and is_instance_valid(weapon):
		weapon.queue_free()
		weapon = null

	var weapon_data: WeaponPresentationData = WeaponRegistry.get_weapon(weapon_id)
	var weapon_instance := weapon_data.weapon_scene.instantiate() as Weapon
	if weapon_instance == null:
		push_error("Weapon scene for weapon_id '%s' did not instantiate a Weapon." % weapon_id)
		return

	weapon = weapon_instance
	weapon.setup(weapon_data)
	add_child(weapon)
