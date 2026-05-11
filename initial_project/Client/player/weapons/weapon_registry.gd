class_name WeaponRegistry
extends RefCounted

const WeaponPresentationData = preload("res://player/weapons/weapon_presentation_data.gd")
const PISTOL_DATA = preload("res://player/weapons/data/pistol_presentation.tres")
const SMG_DATA = preload("res://player/weapons/data/smg_presentation.tres")
const SHOTGUN_DATA = preload("res://player/weapons/data/shotgun_presentation.tres")

static var _weapons_by_id: Dictionary = {
	GameEnums.WeaponId.PISTOL: PISTOL_DATA,
	GameEnums.WeaponId.SMG: SMG_DATA,
	GameEnums.WeaponId.SHOTGUN: SHOTGUN_DATA,
}


static func get_weapon(id: int) -> WeaponPresentationData:
	var data := _weapons_by_id.get(id) as WeaponPresentationData
	if data == null:
		push_warning("Unknown weapon id '%s'. Falling back to pistol." % id)
		return PISTOL_DATA as WeaponPresentationData

	return data
