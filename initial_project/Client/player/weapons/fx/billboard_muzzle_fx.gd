extends WeaponMuzzleFx
class_name BillboardMuzzleFx

@onready var particles: GPUParticles3D = $Particles


func play() -> void:
	particles.restart()
