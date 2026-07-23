extends Node3D

const SMALL_VARIANT := 0
const MEDIUM_VARIANT := 1
const TALL_VARIANT := 2
const VARIANT_COUNT := 3

@export_group("Layout")
@export var random_seed := 41773
@export var ground_height := -28.5
@export_range(50.0, 500.0, 1.0) var city_half_extent := 220.0
@export_range(8.0, 40.0, 0.5) var grid_spacing := 18.0
@export var central_clearance := Vector2(68.0, 64.0)
@export_range(0.0, 1.0, 0.01) var occupancy := 0.72

@export_group("Building variants")
@export var small_building_size := Vector3(11.0, 16.0, 9.0)
@export var medium_building_size := Vector3(14.0, 26.0, 12.0)
@export var tall_building_size := Vector3(16.0, 38.0, 14.0)

@export_group("Color variation")
@export var building_colors: Array[Color] = [
	Color("465761"),
	Color("53636b"),
	Color("606b70"),
	Color("69645f"),
	Color("47515a"),
	Color("687176"),
]

@onready var _ground_plane: MeshInstance3D = $GroundPlane
@onready var _small_buildings: MultiMeshInstance3D = $BuildingBatches/SmallBuildings
@onready var _medium_buildings: MultiMeshInstance3D = $BuildingBatches/MediumBuildings
@onready var _tall_buildings: MultiMeshInstance3D = $BuildingBatches/TallBuildings


func _ready() -> void:
	_ground_plane.position.y = ground_height - 0.05
	_build_city()


func _build_city() -> void:
	var transforms_by_variant: Array = [[], [], []]
	var colors_by_variant: Array = [[], [], []]
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var grid_radius := floori(city_half_extent / grid_spacing)

	for grid_x in range(-grid_radius, grid_radius + 1):
		for grid_z in range(-grid_radius, grid_radius + 1):
			var x := float(grid_x) * grid_spacing + random.randf_range(-3.5, 3.5)
			var z := float(grid_z) * grid_spacing + random.randf_range(-3.5, 3.5)
			if absf(x) < central_clearance.x and absf(z) < central_clearance.y:
				continue
			if random.randf() > occupancy:
				continue

			var variant := _choose_variant(random)
			var base_size := _get_variant_size(variant)
			var scale := Vector3(
				random.randf_range(0.78, 1.18),
				random.randf_range(0.82, 1.15),
				random.randf_range(0.78, 1.18)
			)
			var angle := 0.0 if random.randf() < 0.5 else PI * 0.5
			var basis := Basis(Vector3.UP, angle).scaled(scale)
			var height := base_size.y * scale.y
			var origin := Vector3(x, ground_height + height * 0.5, z)

			transforms_by_variant[variant].append(Transform3D(basis, origin))
			colors_by_variant[variant].append(_choose_color(random))

	var material := _create_building_material()
	_configure_batch(
		_small_buildings,
		small_building_size,
		transforms_by_variant[SMALL_VARIANT],
		colors_by_variant[SMALL_VARIANT],
		material
	)
	_configure_batch(
		_medium_buildings,
		medium_building_size,
		transforms_by_variant[MEDIUM_VARIANT],
		colors_by_variant[MEDIUM_VARIANT],
		material
	)
	_configure_batch(
		_tall_buildings,
		tall_building_size,
		transforms_by_variant[TALL_VARIANT],
		colors_by_variant[TALL_VARIANT],
		material
	)


func _choose_variant(random: RandomNumberGenerator) -> int:
	var roll := random.randf()
	if roll < 0.52:
		return SMALL_VARIANT
	if roll < 0.84:
		return MEDIUM_VARIANT
	return TALL_VARIANT


func _get_variant_size(variant: int) -> Vector3:
	match variant:
		SMALL_VARIANT:
			return small_building_size
		MEDIUM_VARIANT:
			return medium_building_size
		TALL_VARIANT:
			return tall_building_size

	return small_building_size


func _choose_color(random: RandomNumberGenerator) -> Color:
	if building_colors.is_empty():
		return Color.WHITE

	var base_color := building_colors[random.randi_range(0, building_colors.size() - 1)]
	var brightness := random.randf_range(0.82, 1.12)
	return Color(
		minf(base_color.r * brightness, 1.0),
		minf(base_color.g * brightness, 1.0),
		minf(base_color.b * brightness, 1.0),
		1.0
	)


func _create_building_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.52, 0.55, 0.58, 1.0)
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return material


func _configure_batch(
	target: MultiMeshInstance3D,
	mesh_size: Vector3,
	transforms: Array,
	colors: Array,
	material: Material
) -> void:
	var box_mesh := BoxMesh.new()
	box_mesh.size = mesh_size
	box_mesh.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = box_mesh
	multimesh.instance_count = transforms.size()
	multimesh.visible_instance_count = transforms.size()

	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, colors[index])

	target.multimesh = multimesh
