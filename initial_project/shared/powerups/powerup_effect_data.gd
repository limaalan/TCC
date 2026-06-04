class_name PowerupEffectData
extends RefCounted

var powerup_type: int = GameEnums.PowerupType.DAMAGE
var duration_sec := 10.0
var damage_multiplier := 1.0
var fire_rate_cooldown_multiplier := 1.0


static func from_pickup_data(data: Resource) -> PowerupEffectData:
	var effect := PowerupEffectData.new()
	if data == null:
		return effect

	effect.powerup_type = int(data.get("powerup_type"))
	effect.duration_sec = float(data.get("duration_sec"))
	effect.damage_multiplier = float(data.get("damage_multiplier"))
	effect.fire_rate_cooldown_multiplier = float(data.get("fire_rate_cooldown_multiplier"))
	return effect
