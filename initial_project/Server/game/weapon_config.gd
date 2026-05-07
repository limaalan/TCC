class_name WeaponConfig

#Configuração das armas
const WEAPON_DATA := {
	GameEnums.WeaponId.PISTOL: {
		"name": "Pistol",
		"damage": 35, 
		"accuracy": 0.9,
		"projectiles": 1
	},
	GameEnums.WeaponId.SMG: {
		"name": "SMG",
		"damage": 20, 
		"accuracy": 0.7,
		"projectiles": 1
	},
	GameEnums.WeaponId.SHOTGUN: {
		"name": "Shotgun",
		"damage": 18, 
		"accuracy": 0.4,
		"projectiles": 6
	}
}

static func get_weapon_data(weapon_id) -> Dictionary:
	print("Getting", weapon_id,"DATA:", WEAPON_DATA.get(weapon_id) )
	return WEAPON_DATA.get(weapon_id)
