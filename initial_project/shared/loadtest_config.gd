extends RefCounted
## Opt-in settings for the one-room experiment, using the existing Highrise spawns.

const MIN_PLAYERS := 2
const MAX_PLAYERS := 64
const DEFAULT_DURATION := 900
const DEFAULT_SCORE := 10000
const DEFAULT_AMMO := 10000
const MAX_INTEGER := "2147483647"
const PLAYERS_ARG := "--loadtest-players"
const DURATION_ARG := "--loadtest-duration"
const SCORE_ARG := "--loadtest-score"
const AMMO_ARG := "--loadtest-ammo"


static func parse(arguments: PackedStringArray) -> Dictionary:
	var values := {}
	for argument in arguments:
		if not argument.begins_with("--loadtest-"):
			continue
		var key := argument.get_slice("=", 0)
		if key not in [PLAYERS_ARG, DURATION_ARG, SCORE_ARG, AMMO_ARG]:
			return _failure("Unknown experimental option: %s" % key)
		if not argument.contains("="):
			return _failure("%s requires =INTEGER" % key)
		if values.has(key):
			return _failure("Repeated experimental option: %s" % key)
		var text := argument.substr(key.length() + 1)
		if not _is_positive_integer(text):
			return _failure("%s requires an integer between 1 and %s" % [key, MAX_INTEGER])
		values[key] = text.to_int()

	if values.is_empty():
		return {"ok": true, "enabled": false, "error": ""}
	if not values.has(PLAYERS_ARG):
		return _failure("--loadtest-players is required to enable experimental match settings")
	var players: int = values[PLAYERS_ARG]
	if players < MIN_PLAYERS or players > MAX_PLAYERS:
		return _failure("--loadtest-players must be 2..64; experimental matches reuse existing spawn points")
	return {
		"ok": true,
		"enabled": true,
		"error": "",
		"players": players,
		"duration": values.get(DURATION_ARG, DEFAULT_DURATION),
		"score": values.get(SCORE_ARG, DEFAULT_SCORE),
		"ammo": values.get(AMMO_ARG, DEFAULT_AMMO),
	}


static func _is_positive_integer(text: String) -> bool:
	if text.is_empty():
		return false
	for index in text.length():
		var character := text.unicode_at(index)
		if character < 48 or character > 57:
			return false
	# Compare before conversion so oversized input cannot wrap to an accepted value.
	var significant := text.trim_prefix("0")
	while significant.begins_with("0"):
		significant = significant.substr(1)
	if significant.is_empty():
		return false
	if significant.length() > MAX_INTEGER.length():
		return false
	if significant.length() == MAX_INTEGER.length() and significant > MAX_INTEGER:
		return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "enabled": false, "error": message}
