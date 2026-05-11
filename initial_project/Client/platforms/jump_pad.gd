extends Area3D
class_name JumpPad

@export var vertical_velocity := 10.0
@export var horizontal_velocity := 0.0
@export var use_forward_direction := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is PlayerLocal:
		return

	var player: PlayerLocal = body
	var launch_direction := -global_transform.basis.z if use_forward_direction else Vector3.ZERO
	player.apply_jump_pad_impulse(vertical_velocity, horizontal_velocity, launch_direction)
