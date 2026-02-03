extends Node3D
class_name Weapon

@export var is_automatic := false
@export var shot_cooldown := 0.3

@onready var shoot_particles: GPUParticles3D = $Muzzle/ShootParticles
@onready var shoot_light: OmniLight3D = $Muzzle/ShootLight

func _ready()->void:
	shoot_light.hide()
	shoot_particles.finished.connect(shoot_light.hide) 
	#Quando a animação do flash terminar, também desliga a luz

func play_shoot_fx()->void:
	shoot_light.show()
	shoot_particles.emitting = true
