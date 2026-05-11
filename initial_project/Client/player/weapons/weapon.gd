extends Node3D
class_name Weapon

const WeaponPresentationData = preload("res://player/weapons/weapon_presentation_data.gd")

@onready var shoot_particles: GPUParticles3D = $Muzzle/ShootParticles
@onready var shoot_light: OmniLight3D = $Muzzle/ShootLight
var data: WeaponPresentationData


func setup(p_data: WeaponPresentationData) -> void:
	data = p_data

func _ready()->void:
	shoot_light.hide()
	shoot_particles.finished.connect(shoot_light.hide) 
	#Quando a animação do flash terminar, também desliga a luz

func play_shoot_fx(is_local := false )->void:
	if data == null:
		push_warning("Weapon has no presentation data.")
		return

	shoot_light.show()
	shoot_particles.emitting = true
			
	var audio_position = global_position if not is_local else Vector3.ZERO
	AudioManager.play_sfx(data.shoot_sfx , audio_position, data.pitch_randomness)
