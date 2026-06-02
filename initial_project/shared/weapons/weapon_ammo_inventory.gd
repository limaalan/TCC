class_name WeaponAmmoInventory
extends RefCounted

const WeaponCatalog = preload("res://shared/weapons/weapon_catalog.gd")

var ammo_by_weapon_id: Dictionary = {}


func clear_all_ammo() -> void:
	ammo_by_weapon_id.clear()

	for weapon in WeaponCatalog.get_all_weapons():
		ammo_by_weapon_id[weapon.id] = 0


func setup_spawn_ammo(selected_weapon_id: int) -> void:
	clear_all_ammo()

	var selected_weapon := WeaponCatalog.get_weapon(selected_weapon_id)
	ammo_by_weapon_id[selected_weapon.id] = selected_weapon.start_ammo


func get_ammo(weapon_id: int) -> int:
	return ammo_by_weapon_id.get(weapon_id, 0)


func set_ammo(weapon_id: int, amount: int) -> void:
	var weapon := WeaponCatalog.get_weapon(weapon_id)
	ammo_by_weapon_id[weapon_id] = clampi(amount, 0, weapon.max_ammo)


func can_spend_for_shot(weapon_id: int) -> bool:
	var weapon := WeaponCatalog.get_weapon(weapon_id)
	return get_ammo(weapon_id) >= weapon.ammo_per_shot


func spend_for_shot(weapon_id: int) -> bool:
	if not can_spend_for_shot(weapon_id):
		return false

	var weapon := WeaponCatalog.get_weapon(weapon_id)
	ammo_by_weapon_id[weapon_id] -= weapon.ammo_per_shot
	return true


func add_ammo(weapon_id: int, amount: int) -> int:
	var weapon := WeaponCatalog.get_weapon(weapon_id)
	var current := get_ammo(weapon_id)
	var updated := clampi(current + amount, 0, weapon.max_ammo)

	ammo_by_weapon_id[weapon_id] = updated
	return updated


func make_snapshot() -> Dictionary:
	return ammo_by_weapon_id.duplicate()


func apply_snapshot(snapshot: Dictionary) -> void:
	clear_all_ammo()

	for weapon_id in snapshot.keys():
		set_ammo(int(weapon_id), int(snapshot[weapon_id]))
