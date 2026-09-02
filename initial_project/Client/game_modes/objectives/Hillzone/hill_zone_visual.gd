extends Node3D
class_name HillZoneVisual

const EMPTY_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const CONTESTED_COLOR := Color(1.0, 0.84, 0.3, 0.15)
const BLUE_COLOR := Color(0.0, 0.53, 1.0,0.15)
const RED_COLOR := Color(1.0, 0.3, 0.0, 0.15)

@onready var cylinder_mesh_instance: MeshInstance3D = %CylinderMesh
@onready var dome_mesh_instance: MeshInstance3D = %DomeMesh

var objective_id := ""
var current_color := EMPTY_COLOR


func _ready() -> void:
	_apply_color(current_color)


func configure(new_objective_id: String, new_position: Vector3) -> void:
	objective_id = new_objective_id
	position = new_position


func update_hill_state(hill_state: Dictionary) -> void:
	if not NetPayloads.is_hill_state(hill_state):
		return

	var control_state: int = hill_state[NetKeys.HILL_CONTROL_STATE]
	var controlling_team: int = hill_state[NetKeys.HILL_CONTROLLING_TEAM]

	match control_state:
		GameEnums.HillControlState.EMPTY:
			_apply_color(EMPTY_COLOR)
		GameEnums.HillControlState.CONTESTED:
			_apply_color(CONTESTED_COLOR)
		GameEnums.HillControlState.CONTROLLED:
			if controlling_team == GameEnums.Team.BLUE:
				_apply_color(BLUE_COLOR)
			elif controlling_team == GameEnums.Team.RED:
				_apply_color(RED_COLOR)
			else:
				_apply_color(EMPTY_COLOR)
		_:
			_apply_color(EMPTY_COLOR)


func _apply_color(color: Color) -> void:
	current_color = color

	_set_team_color(cylinder_mesh_instance, color)
	_set_team_color(dome_mesh_instance, color)


func _set_team_color(mesh_instance: MeshInstance3D, color: Color) -> void:
	var shader_mat := mesh_instance.material_override as ShaderMaterial
	if shader_mat != null:
		shader_mat.set_shader_parameter("grid_color", color)
		return

	var standard_mat := mesh_instance.material_override as StandardMaterial3D
	if standard_mat == null:
		return

	standard_mat.albedo_color = color
	standard_mat.emission = color
