class_name ServerLocator
extends RefCounted


static func get_server(tree: SceneTree) -> Node:
	if tree == null:
		return null

	return tree.root.get_node_or_null("Server")
