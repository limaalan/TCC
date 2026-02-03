extends CharacterBody3D
class_name PlayerCharacter

@export var weapon_holder:WeaponHolder

var team:int
var weapon_id:int

func _ready()->void:
	instantiate_weapon()


func instantiate_weapon()->void:
	if weapon_holder == null :
		print("No weapon holder found on ", self)
		return
	weapon_holder.instantiate_weapon(weapon_id)
