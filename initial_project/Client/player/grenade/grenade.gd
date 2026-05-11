extends Node3D
class_name Grenade

const NetworkEntity = preload("res://shared/network_entity.gd")

var grenade_throw_sfx_pitch_randomness := 0.1
var network_id: StringName

func _ready() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.GrenadeThrow, global_position, grenade_throw_sfx_pitch_randomness)


func set_network_id(value: String) -> void:
	network_id = StringName(value)


func get_network_id() -> String:
	return NetworkEntity.to_wire(network_id)


func lerp_tform(old_data:Dictionary , new_data :Dictionary, lerp_weight:float)->void:
	transform = old_data[NetKeys.TRANSFORM].interpolate_with(new_data[NetKeys.TRANSFORM], lerp_weight)
