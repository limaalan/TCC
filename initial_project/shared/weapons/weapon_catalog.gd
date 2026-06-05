class_name WeaponCatalog
extends RefCounted

const WeaponDefinition = preload("res://shared/weapons/weapon_definition.gd")
const WEAPON_DEFINITION_PATHS := [
	"res://shared/weapons/data/pistol_definition.tres",
	"res://shared/weapons/data/smg_definition.tres",
	"res://shared/weapons/data/shotgun_definition.tres",
]

static var _weapons: Array[WeaponDefinition] = []
static var _weapons_by_id: Dictionary = {}
static var _weapons_by_slot: Dictionary = {}
static var _is_loaded := false


static func _ensure_loaded() -> void:
	if _is_loaded:
		return

	_is_loaded = true
	_weapons.clear()
	_weapons_by_id.clear()
	_weapons_by_slot.clear()

	for path in WEAPON_DEFINITION_PATHS:
		var weapon := ResourceLoader.load(path, "WeaponDefinition") as WeaponDefinition
		if weapon == null:
			push_warning("Failed to load WeaponDefinition from '%s'." % path)
			continue

		_weapons.append(weapon)
		_weapons_by_id[weapon.id] = weapon
		_weapons_by_slot[weapon.slot] = weapon


static func has_weapon(weapon_id: int) -> bool:
	_ensure_loaded()
	return _weapons_by_id.has(weapon_id)


static func get_weapon(weapon_id: int) -> WeaponDefinition:
	_ensure_loaded()

	var weapon := _weapons_by_id.get(weapon_id) as WeaponDefinition
	if weapon == null:
		push_warning("Unknown weapon_id '%s'. Falling back to pistol." % weapon_id)
		return _weapons_by_id.get(GameEnums.WeaponId.PISTOL, _weapons.front()) as WeaponDefinition

	return weapon


static func get_weapon_by_slot(slot: int) -> WeaponDefinition:
	_ensure_loaded()
	return _weapons_by_slot.get(slot) as WeaponDefinition


static func get_all_weapons() -> Array[WeaponDefinition]:
	_ensure_loaded()
	return _weapons.duplicate()


static func get_all_weapon_ids() -> Array:
	_ensure_loaded()
	return _weapons_by_id.keys()
