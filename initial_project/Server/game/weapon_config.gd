class_name WeaponConfig
extends RefCounted

const WeaponGameplayData = preload("res://game/weapon_gameplay_data.gd")

static var _weapon_data_by_id: Dictionary = {}


static func get_weapon_data(weapon_id: int) -> WeaponGameplayData:
	_ensure_loaded()

	var data := _weapon_data_by_id.get(weapon_id) as WeaponGameplayData
	if data == null:
		push_warning("Unknown weapon_id '%s'. Falling back to pistol." % weapon_id)
		return _weapon_data_by_id.get(GameEnums.WeaponId.PISTOL) as WeaponGameplayData

	return data


static func _ensure_loaded() -> void:
	if not _weapon_data_by_id.is_empty():
		return

	_weapon_data_by_id = {
		GameEnums.WeaponId.PISTOL: WeaponGameplayData.create(
			GameEnums.WeaponId.PISTOL,
			"Pistol",
			35,
			0.9,
			1
		),
		GameEnums.WeaponId.SMG: WeaponGameplayData.create(
			GameEnums.WeaponId.SMG,
			"SMG",
			20,
			0.7,
			1
		),
		GameEnums.WeaponId.SHOTGUN: WeaponGameplayData.create(
			GameEnums.WeaponId.SHOTGUN,
			"Shotgun",
			18,
			0.4,
			6
		),
	}
