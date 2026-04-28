extends Node3D
class_name Weapon

@export var is_automatic := false
@export var shot_cooldown := 0.3

@onready var shoot_particles: GPUParticles3D = $Muzzle/ShootParticles
@onready var shoot_light: OmniLight3D = $Muzzle/ShootLight
const weapon_sfx_pitch_randomness = 0.1
var weapon_id : int

func _ready()->void:
	shoot_light.hide()
	shoot_particles.finished.connect(shoot_light.hide) 
	#Quando a animação do flash terminar, também desliga a luz

func play_shoot_fx(is_local := false )->void:
	shoot_light.show()
	shoot_particles.emitting = true
	
	var sfx_key:AudioManager.SFXKeys
	
	match weapon_id :
		0:
			sfx_key = AudioManager.SFXKeys.ShootPistol
		1:
			sfx_key = AudioManager.SFXKeys.ShootSMG
		2:
			sfx_key = AudioManager.SFXKeys.ShootShotgun
			
	var audio_position = global_position if not is_local else Vector3.ZERO
	AudioManager.play_sfx(sfx_key , audio_position, weapon_sfx_pitch_randomness)
