class_name NetPayloads
extends RefCounted

const PLAYER_STATE_VERSION := 1


static func make_player_state(pos: Vector3, rot_y: float, rot_x: float, anim: Variant) -> Dictionary:
	return {
		NetKeys.VERSION: PLAYER_STATE_VERSION,
		NetKeys.POS: pos,
		NetKeys.ROT_Y: rot_y,
		NetKeys.ROT_X: rot_x,
		NetKeys.ANIM: _normalize_anim(anim),
	}


static func is_player_state(data: Dictionary) -> bool:
	if not data.has(NetKeys.POS) or not data[NetKeys.POS] is Vector3:
		return false

	if not data.has(NetKeys.ROT_Y) or not _is_number(data[NetKeys.ROT_Y]):
		return false

	if not data.has(NetKeys.ROT_X) or not _is_number(data[NetKeys.ROT_X]):
		return false

	if not data.has(NetKeys.ANIM) or not _is_anim_value(data[NetKeys.ANIM]):
		return false

	if data.has(NetKeys.VERSION):
		if not _is_number(data[NetKeys.VERSION]):
			return false
		if int(data[NetKeys.VERSION]) != PLAYER_STATE_VERSION:
			return false

	return true


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _is_anim_value(value: Variant) -> bool:
	return value is String or value is StringName


static func _normalize_anim(anim: Variant) -> String:
	if anim is StringName:
		return String(anim)
	if anim is String:
		return anim
	return String(anim)
