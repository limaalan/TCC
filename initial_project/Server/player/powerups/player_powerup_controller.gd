class_name PlayerPowerupController
extends RefCounted

const KEY_DAMAGE_MULTIPLIER := "damage_multiplier"
const KEY_FIRE_RATE_COOLDOWN_MULTIPLIER := "fire_rate_cooldown_multiplier"

var player: PlayerServerReal
var active_powerups: Dictionary = {}
var powerup_tokens: Dictionary = {}


func _init(p_player: PlayerServerReal) -> void:
	player = p_player


func apply_powerup(effect: PowerupEffectData) -> void:
	if effect == null:
		return

	var token := Time.get_ticks_msec()
	active_powerups[effect.powerup_type] = {
		KEY_DAMAGE_MULTIPLIER: effect.damage_multiplier,
		KEY_FIRE_RATE_COOLDOWN_MULTIPLIER: effect.fire_rate_cooldown_multiplier,
	}
	powerup_tokens[effect.powerup_type] = token

	if is_instance_valid(player) and player.lobby != null:
		player.lobby.player_powerup_started(
			player.name.to_int(),
			effect.powerup_type,
			effect.duration_sec,
			effect.damage_multiplier,
			effect.fire_rate_cooldown_multiplier
		)

	_wait_and_clear(effect.powerup_type, effect.duration_sec, token)


func clear_powerup(powerup_type: int) -> void:
	if not active_powerups.has(powerup_type):
		return

	active_powerups.erase(powerup_type)
	powerup_tokens.erase(powerup_type)

	if is_instance_valid(player) and player.lobby != null:
		player.lobby.player_powerup_ended(player.name.to_int(), powerup_type)


func clear_all_powerups() -> void:
	var powerup_types := active_powerups.keys()
	for powerup_type in powerup_types:
		if is_instance_valid(player) and player.lobby != null:
			player.lobby.player_powerup_ended(player.name.to_int(), powerup_type)

	active_powerups.clear()
	powerup_tokens.clear()


func get_damage_multiplier() -> float:
	if not active_powerups.has(GameEnums.PowerupType.DAMAGE):
		return 1.0

	return float(active_powerups[GameEnums.PowerupType.DAMAGE][KEY_DAMAGE_MULTIPLIER])


func _wait_and_clear(powerup_type: int, duration_sec: float, token: int) -> void:
	await player.get_tree().create_timer(duration_sec).timeout

	if not is_instance_valid(player):
		return

	if powerup_tokens.get(powerup_type) != token:
		return

	clear_powerup(powerup_type)
