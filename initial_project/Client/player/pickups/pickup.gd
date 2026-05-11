extends Node3D
class_name Pickup

const READY_MATERIAL := preload("res://assets/materials/pickup_ready_material.tres")
const NOT_READY_MATERIAL := preload ("res://assets/materials/pickup_not_ready_material.tres")
const NetworkEntity = preload("res://shared/network_entity.gd")

@onready var platform: CSGCylinder3D = %Platform
@onready var mesh_holder: Node3D = $MeshHolder

var pickup_type :int = GameEnums.PickupType.HEALTH
var network_id: StringName

func _ready() -> void:
	match pickup_type:
		GameEnums.PickupType.HEALTH:
			mesh_holder.add_child(load("res://assets/meshes/items/health.tscn").instantiate())
		GameEnums.PickupType.GRENADE:
			mesh_holder.add_child(load("res://assets/meshes/items/grenade.tscn").instantiate())


func set_network_id(value: String) -> void:
	network_id = StringName(value)


func get_network_id() -> String:
	return NetworkEntity.to_wire(network_id)

func cooldown_started()->void:
	platform.material = NOT_READY_MATERIAL
	mesh_holder.hide()

func cooldown_ended()->void:
	platform.material = READY_MATERIAL
	mesh_holder.show()
