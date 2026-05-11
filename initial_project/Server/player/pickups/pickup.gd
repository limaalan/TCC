extends Node3D
class_name Pickup

const NetworkEntity = preload("res://shared/network_entity.gd")

@onready var cooldown_timer: Timer = $CooldownTimer

@export var pickup_type:int = GameEnums.PickupType.HEALTH
@export var cooldown_time := 10.0
@export var network_id: StringName

var lobby:Lobby
var is_picked := false

func _ready() -> void:
	cooldown_timer.wait_time = cooldown_time


func has_network_id() -> bool:
	return NetworkEntity.is_valid_id(network_id)


func get_network_id() -> String:
	if not NetworkEntity.require_id(network_id, "Pickup '%s'" % name):
		return ""

	return NetworkEntity.to_wire(network_id)


func _on_body_entered(player: PlayerServerReal) -> void:
	if is_picked :
		return
	
	match pickup_type:
		GameEnums.PickupType.HEALTH:
			if player.current_health < player.MAX_HEALTH:
				player.change_health(75)
				picked_up(player)
				
		GameEnums.PickupType.GRENADE:
			player.update_grenades_left(player.grenades_left+1)
			picked_up(player)

func picked_up(player:PlayerServerReal)->void:
	is_picked = true
	cooldown_timer.start()
	lobby.pickup_cooldown_started(get_network_id())
	lobby.play_pickup_fx(player.name.to_int(), pickup_type)

func _on_cooldown_timer_timeout() -> void:
	is_picked = false
	lobby.pickup_cooldown_ended(get_network_id())
