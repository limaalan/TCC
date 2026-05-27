extends Node3D
class_name HillZoneVisual

const EMPTY_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const CONTESTED_COLOR := Color(1.0, 0.84, 0.3, 0.2)
const BLUE_COLOR := Color(0.0, 0.53, 1.0, 0.22)
const RED_COLOR := Color(1.0, 0.3, 0.0, 0.22)
const DOME_ALPHA_SCALE := 0.35

@onready var cylinder_mesh_instance: MeshInstance3D = %CylinderMesh
@onready var dome_mesh_instance: MeshInstance3D = %DomeMesh

var objective_id := ""
var cylinder_material: StandardMaterial3D
var dome_material: StandardMaterial3D
var current_color := EMPTY_COLOR


func _ready() -> void:
	cylinder_material = _setup_runtime_material(cylinder_mesh_instance)
	dome_material = _setup_runtime_material(dome_mesh_instance)
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

	if cylinder_material == null:
		return

	cylinder_material.albedo_color = color
	cylinder_material.emission = color

	if dome_material != null:
		var dome_color := color
		dome_color.a *= DOME_ALPHA_SCALE
		dome_material.albedo_color = dome_color
		dome_material.emission = dome_color


func _setup_runtime_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var base_material := mesh_instance.material_override
	var runtime_material: StandardMaterial3D
	if base_material != null:
		runtime_material = base_material.duplicate() as StandardMaterial3D
	else:
		runtime_material = StandardMaterial3D.new()

	runtime_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	runtime_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	runtime_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	runtime_material.emission_enabled = true
	runtime_material.emission_energy_multiplier = 1.0

	mesh_instance.material_override = runtime_material
	return runtime_material
