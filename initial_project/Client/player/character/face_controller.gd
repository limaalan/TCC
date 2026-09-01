extends Node
class_name FaceController

enum FaceExpression {
	NORMAL,
	SAD,
	HIT,
	ANGRY,
	HEALED,
}

const LOW_HEALTH_THRESHOLD := 0.40
const HIT_DURATION := 0.25
const ANGRY_DURATION := 0.75
const HEALED_DURATION := 3

const EXPRESSION_TEXTURES := {
	FaceExpression.NORMAL: preload("res://assets/meus_assets/char/expressions/normal.png"),
	FaceExpression.SAD: preload("res://assets/meus_assets/char/expressions/cry.png"),
	FaceExpression.HIT: preload("res://assets/meus_assets/char/expressions/pain.png"),
	FaceExpression.ANGRY: preload("res://assets/meus_assets/char/expressions/angry.png"),
	FaceExpression.HEALED: preload("res://assets/meus_assets/char/expressions/healed.png"),
}

var _face_material: StandardMaterial3D
var _reaction_timer: Timer
var _temporary_expression := -1
var _current_health := 1
var _max_health := 1
var _current_expression := -1


func setup(head_mesh: MeshInstance3D, face_surface_slot: int) -> void:
	if head_mesh == null or head_mesh.mesh == null:
		push_warning("FaceController needs a valid head mesh.")
		return

	if face_surface_slot < 0 or face_surface_slot >= head_mesh.mesh.get_surface_count():
		push_warning("FaceController received an invalid face surface slot: %s." % face_surface_slot)
		return

	var original_material := head_mesh.get_active_material(face_surface_slot)
	_face_material = original_material.duplicate() as StandardMaterial3D if original_material != null else null
	if _face_material == null:
		push_warning("FaceController expected a StandardMaterial3D on the face surface.")
		return

	_face_material.resource_local_to_scene = true
	_face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_face_material.alpha_scissor_threshold = 0.5
	head_mesh.set_surface_override_material(face_surface_slot, _face_material)
	_ensure_reaction_timer()
	_resolve_base_expression()


func update_health(current_health: int, max_health: int, changed_amount: int) -> void:
	_current_health = current_health
	_max_health = max(max_health, 1)

	if changed_amount < 0:
		_start_temporary_expression(FaceExpression.HIT, HIT_DURATION)
		return

	if changed_amount > 0:
		_start_temporary_expression(FaceExpression.HEALED, HEALED_DURATION)
		return

	if _temporary_expression == -1:
		_resolve_base_expression()


func _start_temporary_expression(expression: int, duration: float) -> void:
	_ensure_reaction_timer()
	_temporary_expression = expression
	_set_expression(expression)
	_reaction_timer.start(duration)


func _ensure_reaction_timer() -> void:
	if _reaction_timer != null:
		return

	_reaction_timer = Timer.new()
	_reaction_timer.one_shot = true
	_reaction_timer.timeout.connect(_on_reaction_timer_timeout)
	add_child(_reaction_timer)


func _on_reaction_timer_timeout() -> void:
	if _temporary_expression == FaceExpression.HIT:
		_start_temporary_expression(FaceExpression.ANGRY, ANGRY_DURATION)
		return

	_temporary_expression = -1
	_resolve_base_expression()


func _resolve_base_expression() -> void:
	if _face_material == null:
		return

	var health_ratio := _current_health / float(_max_health)
	_set_expression(FaceExpression.SAD if health_ratio <= LOW_HEALTH_THRESHOLD else FaceExpression.NORMAL)


func _set_expression(expression: int) -> void:
	if _face_material == null or _current_expression == expression:
		return

	_face_material.albedo_texture = EXPRESSION_TEXTURES[expression]
	_current_expression = expression
