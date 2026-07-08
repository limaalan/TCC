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

	var loaded_weapons: Array[WeaponDefinition] = []
	var weapons_by_id: Dictionary = {}
	var weapons_by_slot: Dictionary = {}

	for path in WEAPON_DEFINITION_PATHS:
		var weapon := _load_weapon_definition(path)
		if weapon == null:
			continue

		if weapons_by_id.has(weapon.id):
			push_warning("Duplicate WeaponDefinition id '%s' found at '%s'. Keeping the first entry." % [weapon.id, path])
			continue

		if weapons_by_slot.has(weapon.slot):
			push_warning("Duplicate WeaponDefinition slot '%s' found at '%s'. Keeping the first entry." % [weapon.slot, path])
			continue

		loaded_weapons.append(weapon)
		weapons_by_id[weapon.id] = weapon
		weapons_by_slot[weapon.slot] = weapon

	_weapons = loaded_weapons
	_weapons_by_id = weapons_by_id
	_weapons_by_slot = weapons_by_slot
	_is_loaded = true

	if _weapons.is_empty():
		push_error("WeaponCatalog failed to load any weapon definitions. Check exported resources and shared weapon data.")


static func _load_weapon_definition(path: String) -> WeaponDefinition:
	if not ResourceLoader.exists(path):
		push_warning("WeaponDefinition path does not exist: '%s'." % path)
		return null

	var resource := ResourceLoader.load(path) as Resource
	if resource == null:
		push_warning("Failed to load weapon resource from '%s'." % path)
		return null

	if not resource is WeaponDefinition:
		var script_path := _get_resource_script_path(resource)
		var extra_context := ""
		if not script_path.is_empty():
			extra_context = " (script: '%s')" % script_path

		push_warning("Resource at '%s' is not a WeaponDefinition. Got: %s%s" % [path, resource.get_class(), extra_context])
		return null

	return resource as WeaponDefinition


static func _get_resource_script_path(resource: Resource) -> String:
	var script := resource.get_script() as Script
	if script == null:
		return ""

	return script.resource_path


static func _get_fallback_weapon() -> WeaponDefinition:
	var pistol := _weapons_by_id.get(GameEnums.WeaponId.PISTOL) as WeaponDefinition
	if pistol != null:
		return pistol

	if _weapons.is_empty():
		return null

	return _weapons.front()


static func has_weapon(weapon_id: int) -> bool:
	_ensure_loaded()
	return _weapons_by_id.has(weapon_id)


static func get_weapon(weapon_id: int) -> WeaponDefinition:
	_ensure_loaded()

	var weapon := _weapons_by_id.get(weapon_id) as WeaponDefinition
	if weapon == null:
		var fallback_weapon := _get_fallback_weapon()
		if fallback_weapon == null:
			push_error("Unknown weapon_id '%s' requested, but WeaponCatalog has no loaded weapons." % weapon_id)
			return null

		push_warning("Unknown weapon_id '%s'. Falling back to weapon id '%s'." % [weapon_id, fallback_weapon.id])
		return fallback_weapon

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
