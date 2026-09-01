extends PlayerCharacter
class_name PlayerLocal

const IDLE_ANIM := ClientNames.ANIM_IDLE
const AIR_ANIM := ClientNames.ANIM_AIR
const WALK_ANIM := ClientNames.ANIM_WALK_SHOOT
const RUN_ANIM := ClientNames.ANIM_RUN_SHOOT
const FOOTSTEP_SFX_WALK_INTERVAL := 0.5
const FOOTSTEP_SFX_RUN_INTERVAL := 0.37
const FOOTSTEP_SFX_PITCH_RANDOM := 0.2
const WeaponAmmoInventory = preload("res://shared/weapons/weapon_ammo_inventory.gd")
const WeaponCatalog = preload("res://shared/weapons/weapon_catalog.gd")
const PowerupStatusItemScene = preload("res://ui/hud/powerup_status_item.tscn")
const BLUE_TEAM_INDICATOR := preload("res://ui/hud/icons/team_indicator_blue.png")
const RED_TEAM_INDICATOR := preload("res://ui/hud/icons/team_indicator_red.png")
const RESUME_CONFLICT_ACTIONS: Array[StringName] = [
	ClientNames.INPUT_JUMP,
	ClientNames.INPUT_SHOOT,
	ClientNames.INPUT_THROW_GRENADE,
]

@export var grenade_amount_label: Label
@export var ammo_amount_label: Label
@export var powerup_status_container: HBoxContainer
@export var team_indicator: TextureRect
@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 4.0
@export var max_jumps := 2
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005
@export var gamepad_look_sensitivity := 2.5

@onready var head: Node3D = $Head
@onready var foot_step_timer: Timer = $FootStepTimer
@onready var pause_screen: Control = $PauseScreen

var auto_freeze := false
var is_frozen := false
var is_paused := false
var is_grounded := true
var is_sprinting := false
var jumps_used := 0
var current_anim: String
var nearby_grenades: Array[Grenade] = []
var ammo_inventory := WeaponAmmoInventory.new()
var blocked_actions_after_resume := {}
var powerup_status_items: Dictionary = {}


func _ready() -> void:
	super()
	ammo_inventory.clear_all_ammo()
	update_ammo_ui()
	update_team_indicator()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if auto_freeze:
		freeze()

	pause_screen.hide()


func update_team_indicator() -> void:
	if team_indicator == null:
		return

	team_indicator.texture = BLUE_TEAM_INDICATOR if team == GameEnums.Team.BLUE else RED_TEAM_INDICATOR


func pause() -> void:
	set_processing_enabled(false)
	is_paused = true
	pause_screen.show()
	pause_screen.call_deferred("focus_default_control")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func unpause() -> void:
	_block_pressed_gameplay_actions()
	if not is_frozen:
		set_processing_enabled(true)
	is_paused = false
	pause_screen.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func freeze() -> void:
	set_processing_enabled(false)
	is_frozen = true


func unfreeze() -> void:
	if not is_paused:
		set_processing_enabled(true)
	is_frozen = false


func set_processing_enabled(enabled: bool) -> void:
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)


func _physics_process(delta: float) -> void:
	handle_gamepad_look(delta)
	move()
	choose_anim()
	check_shoot_input()
	check_weapon_switch_input()
	check_throw_grenade_input()
	show_nearby_grenades()


func check_shoot_input() -> void:
	if not GamepadFocusGuard.accepts_input():
		weapon_holder.end_trigger_pressed()
		return

	if _is_action_blocked_after_resume(ClientNames.INPUT_SHOOT):
		weapon_holder.end_trigger_pressed()
		return

	if Input.is_action_just_pressed(ClientNames.INPUT_SHOOT):
		weapon_holder.start_trigger_pressed()
	elif Input.is_action_just_released(ClientNames.INPUT_SHOOT):
		weapon_holder.end_trigger_pressed()


func check_weapon_switch_input() -> void:
	if not GamepadFocusGuard.accepts_input():
		return

	if Input.is_action_just_pressed(ClientNames.INPUT_WEAPON_SLOT_1):
		try_switch_weapon_slot(1)
	elif Input.is_action_just_pressed(ClientNames.INPUT_WEAPON_SLOT_2):
		try_switch_weapon_slot(2)
	elif Input.is_action_just_pressed(ClientNames.INPUT_WEAPON_SLOT_3):
		try_switch_weapon_slot(3)
	elif Input.is_action_just_pressed(ClientNames.INPUT_WEAPON_PREVIOUS):
		cycle_weapon(-1)
	elif Input.is_action_just_pressed(ClientNames.INPUT_WEAPON_NEXT):
		cycle_weapon(1)


func cycle_weapon(direction: int) -> void:
	var slots: Array[int] = []
	for weapon_definition in WeaponCatalog.get_all_weapons():
		slots.append(weapon_definition.slot)

	if slots.is_empty():
		return

	slots.sort()
	var current_weapon_definition := WeaponCatalog.get_weapon(weapon_id)
	var current_slot_index := slots.find(current_weapon_definition.slot)
	if current_slot_index < 0:
		current_slot_index = 0

	var next_slot_index := wrapi(current_slot_index + direction, 0, slots.size())
	try_switch_weapon_slot(slots[next_slot_index])


func try_switch_weapon_slot(slot: int) -> void:
	var weapon_definition := WeaponCatalog.get_weapon_by_slot(slot)
	if weapon_definition == null:
		return

	try_switch_weapon(weapon_definition.id)


func try_switch_weapon(new_weapon_id: int) -> void:
	if weapon_id == new_weapon_id:
		return

	set_weapon_id(new_weapon_id)
	update_ammo_ui()

	if weapon_holder is LocalWeaponHolder:
		weapon_holder.reset_fire_state()

	get_tree().call_group(
		ClientNames.GROUP_LOBBY,
		ClientNames.METHOD_REQUEST_WEAPON_SWITCH,
		new_weapon_id
	)


func choose_anim() -> void:
	if not is_grounded:
		current_anim = AIR_ANIM
		return

	if velocity.x or velocity.z:
		current_anim = RUN_ANIM if is_sprinting else WALK_ANIM
		return
	current_anim = IDLE_ANIM


func can_jump() -> bool:
	return jumps_used < max_jumps


func jump() -> void:
	velocity.y = jump_velocity
	jumps_used += 1


func apply_jump_pad_impulse(vertical_velocity: float, horizontal_velocity: float = 0.0, direction: Vector3 = Vector3.ZERO) -> void:
	velocity.y = vertical_velocity

	var horizontal_direction := Vector3(direction.x, 0.0, direction.z).normalized()
	if not horizontal_direction.is_zero_approx():
		velocity.x = horizontal_direction.x * horizontal_velocity
		velocity.z = horizontal_direction.z * horizontal_velocity

	is_grounded = false
	reset_jumps()


func reset_jumps() -> void:
	jumps_used = 0


func handle_footsteps(direction: Vector3) -> void:
	if direction.is_zero_approx():
		return

	if not foot_step_timer.is_stopped():
		return

	AudioManager.play_sfx(AudioManager.SFXKeys.Footstep, Vector3.ZERO, FOOTSTEP_SFX_PITCH_RANDOM)

	var audio_interval := FOOTSTEP_SFX_RUN_INTERVAL if is_sprinting else FOOTSTEP_SFX_WALK_INTERVAL
	foot_step_timer.start(audio_interval)


func move() -> void:
	var has_input_focus := GamepadFocusGuard.accepts_input()
	var input_dir := Vector2.ZERO
	if has_input_focus:
		input_dir = Input.get_vector(ClientNames.INPUT_MOVE_LEFT, ClientNames.INPUT_MOVE_RIGHT, ClientNames.INPUT_MOVE_FORWARD, ClientNames.INPUT_MOVE_BACKWARD)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		is_sprinting = has_input_focus and Input.is_action_pressed(ClientNames.INPUT_SPRINT)

		if not is_grounded:
			is_grounded = true
			reset_jumps()
			AudioManager.play_sfx(AudioManager.SFXKeys.JumpLand, Vector3.ZERO, FOOTSTEP_SFX_PITCH_RANDOM)
		else:
			reset_jumps()

		handle_footsteps(direction)
	else:
		velocity.y -= gravity

		if is_grounded:
			is_grounded = false

	if (
		has_input_focus
		and not _is_action_blocked_after_resume(ClientNames.INPUT_JUMP)
		and Input.is_action_just_pressed(ClientNames.INPUT_JUMP)
		and can_jump()
	):
		jump()

	var speed := normal_speed if not is_sprinting else sprint_speed

	velocity.z = direction.z * speed
	velocity.x = direction.x * speed

	move_and_slide()


func _input(event) -> void:
	if GamepadFocusGuard.accepts_input() and event is InputEventMouseMotion:
		look_around(event.relative)


func handle_gamepad_look(delta: float) -> void:
	if not GamepadFocusGuard.accepts_input():
		return

	var look_input := Input.get_vector(
		ClientNames.INPUT_LOOK_LEFT,
		ClientNames.INPUT_LOOK_RIGHT,
		ClientNames.INPUT_LOOK_UP,
		ClientNames.INPUT_LOOK_DOWN
	)
	if look_input.is_zero_approx():
		return

	rotate_y(-look_input.x * gamepad_look_sensitivity * delta)
	head.rotate_x(-look_input.y * gamepad_look_sensitivity * delta)
	head.rotation.x = clampf(head.rotation.x, -PI / 2, PI / 2)


func check_throw_grenade_input() -> void:
	if not GamepadFocusGuard.accepts_input():
		return

	if _is_action_blocked_after_resume(ClientNames.INPUT_THROW_GRENADE):
		return

	if Input.is_action_just_pressed(ClientNames.INPUT_THROW_GRENADE):
		get_tree().call_group(ClientNames.GROUP_LOBBY, ClientNames.METHOD_TRY_THROW_GRENADE)


func _block_pressed_gameplay_actions() -> void:
	for action in RESUME_CONFLICT_ACTIONS:
		if Input.is_action_pressed(action):
			blocked_actions_after_resume[action] = true


func _is_action_blocked_after_resume(action: StringName) -> bool:
	if not blocked_actions_after_resume.has(action):
		return false

	if not Input.is_action_pressed(action):
		blocked_actions_after_resume.erase(action)

	return blocked_actions_after_resume.has(action)


func show_nearby_grenades() -> void:
	var grenades_data := {}
	var own_pos := Vector2(global_position.x, global_position.z)

	for grenade in nearby_grenades:
		var grenade_id := grenade.get_network_id()
		if grenade_id.is_empty():
			continue

		var grenade_pos := Vector2(grenade.global_position.x, grenade.global_position.z)
		grenades_data[grenade_id] = own_pos.angle_to_point(grenade_pos) + PI / 2 + rotation.y

	get_tree().call_group(ClientNames.GROUP_GRENADE_PROMPTS, ClientNames.METHOD_UPDATE_GRENADE_PROMPTS, grenades_data)


func update_grenades_left(grenades_left: int) -> void:
	grenade_amount_label.text = str(grenades_left)


func set_powerup_active(
	powerup_type: int,
	active: bool,
	damage_multiplier := 1.0,
	fire_rate_cooldown_multiplier := 1.0,
	duration_sec := 0.0
) -> void:
	super(powerup_type, active, damage_multiplier, fire_rate_cooldown_multiplier, duration_sec)

	if active:
		if duration_sec > 0.0:
			show_powerup_status(powerup_type, duration_sec)
		return

	hide_powerup_status(powerup_type)


func show_powerup_status(powerup_type: int, duration_sec: float) -> void:
	if powerup_status_container == null:
		return

	var status_item = powerup_status_items.get(powerup_type)
	if not is_instance_valid(status_item):
		status_item = PowerupStatusItemScene.instantiate()
		powerup_status_container.add_child(status_item)
		powerup_status_items[powerup_type] = status_item

	status_item.start_buff(powerup_type, duration_sec)


func hide_powerup_status(powerup_type: int) -> void:
	var status_item = powerup_status_items.get(powerup_type)
	if is_instance_valid(status_item):
		status_item.queue_free()

	powerup_status_items.erase(powerup_type)


func try_spend_current_weapon_ammo() -> bool:
	var spent := ammo_inventory.spend_for_shot(weapon_id)
	if spent:
		update_ammo_ui()

	return spent


func get_current_weapon_ammo() -> int:
	return ammo_inventory.get_ammo(weapon_id)


func set_weapon_ammo(target_weapon_id: int, ammo: int) -> void:
	ammo_inventory.set_ammo(target_weapon_id, ammo)
	update_ammo_ui()


func setup_spawn_ammo(selected_weapon_id: int) -> void:
	ammo_inventory.setup_spawn_ammo(selected_weapon_id)
	update_ammo_ui()


func apply_ammo_snapshot(ammo_snapshot: Dictionary) -> void:
	ammo_inventory.apply_snapshot(ammo_snapshot)
	update_ammo_ui()


func update_ammo_ui() -> void:
	if ammo_amount_label == null:
		return

	ammo_amount_label.text = str(get_current_weapon_ammo())


func look_around(relative: Vector2):
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -PI / 2, PI / 2)


func update_health_bar(current_health: int, max_health: int, changed_amount: int) -> void:
	super(current_health, max_health, changed_amount)
	if changed_amount < 0:
		get_tree().call_group(ClientNames.GROUP_CAMERA_SHAKE, ClientNames.METHOD_ADD_NOISE, absi(changed_amount) / float(max_health))

	get_tree().call_group(ClientNames.GROUP_HEALTH_CHANGE_MASK, ClientNames.METHOD_UPDATE_MASK, current_health / float(max_health))


func _unhandled_input(event: InputEvent) -> void:
	if GamepadFocusGuard.accepts_input() and event.is_action_pressed(ClientNames.INPUT_PAUSE):
		pause() if not is_paused else unpause()
		get_viewport().set_input_as_handled()


func _on_grenade_detection_area_area_entered(area: Area3D) -> void:
	nearby_grenades.append(area.get_parent())


func _on_grenade_detection_area_area_exited(area: Area3D) -> void:
	nearby_grenades.erase(area.get_parent())
