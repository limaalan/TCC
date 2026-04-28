extends Node3D

var particles: Array[GPUParticles3D] = []
var grenade_explosion_sfx_pitch_randomness = 0.1

func _ready()->void:
	for child in get_children():
		if child is GPUParticles3D:
			particles.append(child)
			child.finished.connect(particles_finished.bind(child))
			child.emitting=true
	AudioManager.play_sfx(AudioManager.SFXKeys.GrenadeExplode, global_position,grenade_explosion_sfx_pitch_randomness )

func particles_finished(particle: GPUParticles3D)->void:
	particles.erase(particle)
	
	if particles.is_empty():
		queue_free()
