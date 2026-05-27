class_name NetPayloads
extends RefCounted

const PLAYER_STATE_VERSION := 1
const SPAWN_PLAYER_VERSION := 1
const END_MATCH_VERSION := 1
const HILL_STATE_VERSION := 1
const MATCH_META_VERSION := 1
const OBJECTIVE_VISUAL_SPAWN_VERSION := 1


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


static func make_spawn_player(
	client_id: int,
	spawn_transform: Transform3D,
	team: int,
	display_name: String,
	weapon_id: int,
	auto_freeze: bool
) -> Dictionary:
	return {
		NetKeys.VERSION: SPAWN_PLAYER_VERSION,
		NetKeys.CLIENT_ID: client_id,
		NetKeys.SPAWN_TRANSFORM: spawn_transform,
		NetKeys.TEAM: team,
		NetKeys.DISPLAY_NAME: display_name,
		NetKeys.WEAPON_ID: weapon_id,
		NetKeys.AUTO_FREEZE: auto_freeze,
	}


static func is_spawn_player(data: Dictionary) -> bool:
	if not _has_exact_version(data, SPAWN_PLAYER_VERSION):
		return false

	if not data.has(NetKeys.CLIENT_ID) or not data[NetKeys.CLIENT_ID] is int:
		return false

	if not data.has(NetKeys.SPAWN_TRANSFORM) or not data[NetKeys.SPAWN_TRANSFORM] is Transform3D:
		return false

	if not data.has(NetKeys.TEAM) or not data[NetKeys.TEAM] is int:
		return false

	if not data.has(NetKeys.DISPLAY_NAME) or not data[NetKeys.DISPLAY_NAME] is String:
		return false

	if not data.has(NetKeys.WEAPON_ID) or not data[NetKeys.WEAPON_ID] is int:
		return false

	if not data.has(NetKeys.AUTO_FREEZE) or not data[NetKeys.AUTO_FREEZE] is bool:
		return false

	return true


static func make_end_match(blue_score: int, red_score: int, players: Array[Dictionary]) -> Dictionary:
	return {
		NetKeys.VERSION: END_MATCH_VERSION,
		NetKeys.BLUE_SCORE: blue_score,
		NetKeys.RED_SCORE: red_score,
		NetKeys.PLAYERS: players,
	}


static func is_end_match(data: Dictionary) -> bool:
	if not _has_exact_version(data, END_MATCH_VERSION):
		return false

	if not data.has(NetKeys.BLUE_SCORE) or not data[NetKeys.BLUE_SCORE] is int:
		return false

	if not data.has(NetKeys.RED_SCORE) or not data[NetKeys.RED_SCORE] is int:
		return false

	if not data.has(NetKeys.PLAYERS) or not data[NetKeys.PLAYERS] is Array:
		return false

	for player_data in data[NetKeys.PLAYERS]:
		if not is_end_match_player(player_data):
			return false

	return true


static func make_match_meta(mode: int, score_to_win: int) -> Dictionary:
	return {
		NetKeys.VERSION: MATCH_META_VERSION,
		NetKeys.MODE: mode,
		NetKeys.SCORE_TO_WIN: score_to_win,
	}


static func is_match_meta(data: Dictionary) -> bool:
	if not _has_exact_version(data, MATCH_META_VERSION):
		return false

	if not data.has(NetKeys.MODE) or not data[NetKeys.MODE] is int:
		return false

	if not data.has(NetKeys.SCORE_TO_WIN) or not data[NetKeys.SCORE_TO_WIN] is int:
		return false

	return true


static func make_objective_visual_spawn(
	objective_id: String,
	objective_type: int,
	pos: Vector3
) -> Dictionary:
	return {
		NetKeys.VERSION: OBJECTIVE_VISUAL_SPAWN_VERSION,
		NetKeys.OBJECTIVE_ID: objective_id,
		NetKeys.OBJECTIVE_TYPE: objective_type,
		NetKeys.POS: pos,
	}


static func is_objective_visual_spawn(data: Dictionary) -> bool:
	if not _has_exact_version(data, OBJECTIVE_VISUAL_SPAWN_VERSION):
		return false

	if not data.has(NetKeys.OBJECTIVE_ID):
		return false

	var objective_id: Variant = data[NetKeys.OBJECTIVE_ID]
	if not (objective_id is String or objective_id is StringName):
		return false

	if not data.has(NetKeys.OBJECTIVE_TYPE) or not data[NetKeys.OBJECTIVE_TYPE] is int:
		return false

	if not data.has(NetKeys.POS) or not data[NetKeys.POS] is Vector3:
		return false

	return true


static func make_hill_state(
	control_state: int,
	controlling_team: int,
	players_inside: Array[int]
) -> Dictionary:
	return {
		NetKeys.VERSION: HILL_STATE_VERSION,
		NetKeys.HILL_CONTROL_STATE: control_state,
		NetKeys.HILL_CONTROLLING_TEAM: controlling_team,
		NetKeys.HILL_PLAYERS_INSIDE: players_inside,
	}


static func is_hill_state(data: Dictionary) -> bool:
	if not _has_exact_version(data, HILL_STATE_VERSION):
		return false

	if not data.has(NetKeys.HILL_CONTROL_STATE) or not data[NetKeys.HILL_CONTROL_STATE] is int:
		return false

	if not data.has(NetKeys.HILL_CONTROLLING_TEAM) or not data[NetKeys.HILL_CONTROLLING_TEAM] is int:
		return false

	if not data.has(NetKeys.HILL_PLAYERS_INSIDE) or not data[NetKeys.HILL_PLAYERS_INSIDE] is Array:
		return false

	for client_id in data[NetKeys.HILL_PLAYERS_INSIDE]:
		if not (client_id is int):
			return false

	return true


static func is_end_match_player(data: Variant) -> bool:
	if not (data is Dictionary):
		return false

	var player_data: Dictionary = data

	if not player_data.has(NetKeys.CLIENT_ID) or not player_data[NetKeys.CLIENT_ID] is int:
		return false

	if not player_data.has(NetKeys.DISPLAY_NAME) or not player_data[NetKeys.DISPLAY_NAME] is String:
		return false

	if not player_data.has(NetKeys.TEAM) or not player_data[NetKeys.TEAM] is int:
		return false

	if not player_data.has(NetKeys.KILLS) or not player_data[NetKeys.KILLS] is int:
		return false

	if not player_data.has(NetKeys.DEATHS) or not player_data[NetKeys.DEATHS] is int:
		return false

	return true


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _has_exact_version(data: Dictionary, expected_version: int) -> bool:
	if not data.has(NetKeys.VERSION):
		return false

	if not _is_number(data[NetKeys.VERSION]):
		return false

	return int(data[NetKeys.VERSION]) == expected_version


static func _is_anim_value(value: Variant) -> bool:
	return value is String or value is StringName


static func _normalize_anim(anim: Variant) -> String:
	if anim is StringName:
		return String(anim)
	if anim is String:
		return anim
	return String(anim)
