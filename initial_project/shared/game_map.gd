class_name GameMap
extends Node3D

@export var spawn_points_root: Node3D
@export var pickups_root: Node3D
@export var objectives_root: Node3D
@export var special_platforms_root: Node3D


func get_spawn_points() -> Array[Node3D]:
	return _get_node3d_children(spawn_points_root)


func get_pickups() -> Array[Pickup]:
	var result: Array[Pickup] = []
	if pickups_root == null:
		return result

	for child in pickups_root.get_children():
		if child is Pickup:
			result.append(child)

	return result


func get_objectives() -> Array[Node3D]:
	return _get_node3d_children(objectives_root)


func get_special_platforms() -> Array[Node3D]:
	return _get_node3d_children(special_platforms_root)


func _get_node3d_children(root: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = []
	if root == null:
		return result

	for child in root.get_children():
		if child is Node3D:
			result.append(child)

	return result
