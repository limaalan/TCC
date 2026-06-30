class_name PickupPresentationRegistry
extends RefCounted

const HEALTH_DATA := preload("res://player/pickups/data/health_pickup_presentation.tres")
const GRENADE_DATA := preload("res://player/pickups/data/grenade_pickup_presentation.tres")
const AMMO_DATA := preload("res://player/pickups/data/ammo_pickup_presentation.tres")
const DAMAGE_POWERUP_DATA := preload("res://player/pickups/data/damage_powerup_pickup_presentation.tres")
const FIRE_RATE_POWERUP_DATA := preload("res://player/pickups/data/fire_rate_powerup_pickup_presentation.tres")

static var _data_by_type: Dictionary = {
	GameEnums.PickupType.HEALTH: HEALTH_DATA,
	GameEnums.PickupType.GRENADE: GRENADE_DATA,
	GameEnums.PickupType.AMMO: AMMO_DATA,
}

static var _powerup_data_by_type: Dictionary = {
	GameEnums.PowerupType.DAMAGE: DAMAGE_POWERUP_DATA,
	GameEnums.PowerupType.FIRE_RATE: FIRE_RATE_POWERUP_DATA,
}

static func get_pickup_data(pickup_type: int, pickup_subtype: int = -1):
	if pickup_type == GameEnums.PickupType.POWERUP:
		var powerup_data = _powerup_data_by_type.get(pickup_subtype)
		if powerup_data == null:
			push_warning("Unknown powerup pickup_subtype '%s'. Falling back to damage powerup." % pickup_subtype)
			return DAMAGE_POWERUP_DATA

		return powerup_data

	var data = _data_by_type.get(pickup_type)
	if data == null:
		push_warning("Unknown pickup_type '%s'. Falling back to health pickup." % pickup_type)
		return HEALTH_DATA

	return data
