extends Node3D

func _ready() -> void:
	_disable_collisions_recursive(self)

func _disable_collisions_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			child.set_deferred("disabled", true)

		if child is CollisionObject3D:
			child.collision_layer = 0
			child.collision_mask = 0

		_disable_collisions_recursive(child)
