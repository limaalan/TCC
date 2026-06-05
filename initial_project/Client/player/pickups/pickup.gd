extends Node3D
class_name Pickup

const NetworkEntity = preload("res://shared/network_entity.gd")
const PickupPresentationRegistryScript = preload("res://player/pickups/pickup_presentation_registry.gd")

@onready var platform: CSGCylinder3D = %Platform
@onready var mesh_holder: Node3D = $MeshHolder

var pickup_type :int = GameEnums.PickupType.HEALTH
var pickup_subtype := -1
var network_id: StringName
var data

func _ready() -> void:
	data = PickupPresentationRegistryScript.get_pickup_data(pickup_type, pickup_subtype)

	if data.mesh_scene != null:
		mesh_holder.add_child(data.mesh_scene.instantiate())

	if data.ready_material != null:
		platform.material = data.ready_material


func set_network_id(value: String) -> void:
	network_id = StringName(value)


func get_network_id() -> String:
	return NetworkEntity.to_wire(network_id)

func cooldown_started()->void:
	if data != null and data.not_ready_material != null:
		platform.material = data.not_ready_material

	mesh_holder.hide()

func cooldown_ended()->void:
	if data != null and data.ready_material != null:
		platform.material = data.ready_material

	mesh_holder.show()
