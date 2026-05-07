extends Node3D
class_name WeaponHolder

var weapon:Weapon 

func instantiate_weapon(weaponId:int)->void:
	match weaponId:
		GameEnums.WeaponId.PISTOL:
			weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		GameEnums.WeaponId.SMG:
			weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		GameEnums.WeaponId.SHOTGUN:
			weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		
	weapon.weapon_id = weaponId
	add_child(weapon)
