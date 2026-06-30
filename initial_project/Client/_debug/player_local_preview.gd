extends CharacterBody3D

@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 4.0
@export var max_jumps := 2
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005

@onready var head: Node3D = $Head

var is_paused := false
var is_grounded := true
var is_sprinting := false
var jumps_used := 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	move()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_paused:
		look_around(event.relative)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		is_paused = not is_paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED


func can_jump() -> bool:
	return jumps_used < max_jumps


func jump() -> void:
	velocity.y = jump_velocity
	jumps_used += 1


func reset_jumps() -> void:
	jumps_used = 0


func move() -> void:
	if is_paused:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var input_dir := Input.get_vector(
		ClientNames.INPUT_MOVE_LEFT,
		ClientNames.INPUT_MOVE_RIGHT,
		ClientNames.INPUT_MOVE_FORWARD,
		ClientNames.INPUT_MOVE_BACKWARD
	)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		is_sprinting = Input.is_action_pressed(ClientNames.INPUT_SPRINT)
		if not is_grounded:
			is_grounded = true
			reset_jumps()
		else:
			reset_jumps()
	else:
		velocity.y -= gravity
		if is_grounded:
			is_grounded = false

	if Input.is_action_just_pressed(ClientNames.INPUT_JUMP) and can_jump():
		jump()

	var speed := normal_speed if not is_sprinting else sprint_speed
	velocity.z = direction.z * speed
	velocity.x = direction.x * speed

	move_and_slide()


func look_around(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -PI / 2, PI / 2)
