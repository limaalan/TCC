extends Node3D
class_name Pickup

const NetworkEntity = preload("res://shared/network_entity.gd")
const DEFAULT_HEALTH_PICKUP_DATA := preload("res://player/pickups/data/health_pickup_data.tres")

@onready var cooldown_timer: Timer = $CooldownTimer

@export var data = DEFAULT_HEALTH_PICKUP_DATA
@export var network_id: StringName

var lobby:Lobby
var is_picked := false

func _ready() -> void:
	if data == null:
		push_warning("Pickup '%s' has no PickupData. Falling back to health pickup." % name)
		data = DEFAULT_HEALTH_PICKUP_DATA

	cooldown_timer.wait_time = data.cooldown_time


func has_network_id() -> bool:
	return NetworkEntity.is_valid_id(network_id)


func get_network_id() -> String:
	if not NetworkEntity.require_id(network_id, "Pickup '%s'" % name):
		return ""

	return NetworkEntity.to_wire(network_id)


func get_pickup_type() -> int:
	if data == null:
		return GameEnums.PickupType.HEALTH

	return data.pickup_type


func _on_body_entered(player: PlayerServerReal) -> void:
	if is_picked :
		return

	if data == null:
		return
	
	match data.pickup_type:
		GameEnums.PickupType.HEALTH:
			if player.current_health < player.MAX_HEALTH:
				player.change_health(data.amount)
				picked_up(player)
				
		GameEnums.PickupType.GRENADE:
			player.update_grenades_left(player.grenades_left + data.amount)
			picked_up(player)

		GameEnums.PickupType.AMMO:
			var client_id := player.name.to_int()
			if not lobby.client_data.has(client_id):
				return

			var weapon_id: int = lobby.client_data[client_id][NetKeys.WEAPON_ID]
			var before := player.get_weapon_ammo(weapon_id)
			var after := player.add_weapon_ammo(weapon_id, data.amount)

			if after > before:
				lobby.update_ammo(client_id, weapon_id, after)
				picked_up(player)

		_:
			push_warning("Unsupported pickup_type '%s' on pickup '%s'." % [data.pickup_type, name])

func picked_up(player:PlayerServerReal)->void:
	is_picked = true
	cooldown_timer.start()
	lobby.pickup_cooldown_started(get_network_id())
	lobby.play_pickup_fx(player.name.to_int(), data.pickup_type)

func _on_cooldown_timer_timeout() -> void:
	is_picked = false
	lobby.pickup_cooldown_ended(get_network_id())
