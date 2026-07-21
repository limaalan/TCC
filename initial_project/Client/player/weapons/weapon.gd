extends Node3D
class_name Weapon

const WeaponPresentationData = preload("res://player/weapons/weapon_presentation_data.gd")

@onready var muzzle: Node3D = $Muzzle
var data: WeaponPresentationData
var muzzle_fx: WeaponMuzzleFx


func setup(p_data: WeaponPresentationData) -> void:
	data = p_data

func _ready() -> void:
	instantiate_muzzle_fx()

func instantiate_muzzle_fx() -> void:
	if data == null or data.muzzle_fx_scene == null:
		push_warning("Weapon has no muzzle FX scene configured.")
		return

	var fx_instance := data.muzzle_fx_scene.instantiate()
	if not fx_instance is WeaponMuzzleFx:
		push_error("Muzzle FX scene for weapon '%s' must inherit WeaponMuzzleFx." % data.id)
		fx_instance.queue_free()
		return

	muzzle_fx = fx_instance as WeaponMuzzleFx
	muzzle.add_child(muzzle_fx)

func play_shoot_fx(is_local := false )->void:
	if data == null:
		push_warning("Weapon has no presentation data.")
		return

	if muzzle_fx != null:
		muzzle_fx.play()
			
	var audio_position = global_position if not is_local else Vector3.ZERO
	AudioManager.play_sfx(data.shoot_sfx , audio_position, data.pitch_randomness)
