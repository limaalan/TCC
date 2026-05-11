class_name NetworkEntity
extends RefCounted

const GRENADE_PREFIX := &"grenade"


static func is_valid_id(network_id: StringName) -> bool:
	return not String(network_id).is_empty()


static func require_id(network_id: StringName, context: String) -> bool:
	if is_valid_id(network_id):
		return true

	push_error("%s is missing network_id." % context)
	return false


static func to_wire(network_id: StringName) -> String:
	return String(network_id)


static func make_dynamic_id(prefix: StringName, owner_id: int, sequence: int) -> StringName:
	return StringName("%s_%s_%s" % [String(prefix), owner_id, sequence])
