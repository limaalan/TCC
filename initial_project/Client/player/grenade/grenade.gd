extends Node3D
class_name Grenade
var grenade_throw_sfx_pitch_randomness := 0.1
func _ready() -> void:
		AudioManager.play_sfx(AudioManager.SFXKeys.GrenadeThrow, global_position,grenade_throw_sfx_pitch_randomness )


func lerp_tform(old_data:Dictionary , new_data :Dictionary, lerp_weight:float)->void:
	transform = old_data[NetKeys.TRANSFORM].interpolate_with(new_data[NetKeys.TRANSFORM], lerp_weight)
