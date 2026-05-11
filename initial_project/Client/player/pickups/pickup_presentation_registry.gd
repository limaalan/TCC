class_name PickupPresentationRegistry
extends RefCounted

const HEALTH_DATA := preload("res://player/pickups/data/health_pickup_presentation.tres")
const GRENADE_DATA := preload("res://player/pickups/data/grenade_pickup_presentation.tres")

static var _data_by_type: Dictionary = {
	GameEnums.PickupType.HEALTH: HEALTH_DATA,
	GameEnums.PickupType.GRENADE: GRENADE_DATA,
}


static func get_pickup_data(pickup_type: int):
	var data = _data_by_type.get(pickup_type)
	if data == null:
		push_warning("Unknown pickup_type '%s'. Falling back to health pickup." % pickup_type)
		return HEALTH_DATA

	return data
