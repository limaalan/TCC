class_name WeaponConfig
extends RefCounted

const WeaponCatalog = preload("res://shared/weapons/weapon_catalog.gd")
const WeaponDefinition = preload("res://shared/weapons/weapon_definition.gd")


static func get_weapon_data(weapon_id: int) -> WeaponDefinition:
	return WeaponCatalog.get_weapon(weapon_id)


static func is_valid_weapon_id(weapon_id: int) -> bool:
	return WeaponCatalog.has_weapon(weapon_id)


static func get_weapon_by_slot(slot: int) -> WeaponDefinition:
	return WeaponCatalog.get_weapon_by_slot(slot)


static func get_all_weapon_ids() -> Array:
	return WeaponCatalog.get_all_weapon_ids()
