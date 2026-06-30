extends GameMap

func _ready() -> void:
	_strip_visual_nodes(self)


func _strip_visual_nodes(root: Node) -> void:
	for child in root.get_children():
		_strip_visual_nodes(child)

		if _should_remove_node(child):
			child.queue_free()


func _should_remove_node(node: Node) -> bool:
	return (
		node is MeshInstance3D
		or node is WorldEnvironment
		or node is DirectionalLight3D
		or node is AnimationPlayer
		or node is GPUParticles3D
		or node is AudioStreamPlayer
		or node is AudioStreamPlayer3D
	)
