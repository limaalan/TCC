extends Node3D
class_name WeaponHolder

var weapon:Weapon 

func instantiate_weapon(weaponId:int)->void:
	match weaponId:
		0: # Pistol
			weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: #SMG
			weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: #Shotgun
			weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		
	weapon.weapon_id = weaponId
	add_child(weapon)
