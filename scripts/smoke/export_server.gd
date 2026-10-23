extends SceneTree
## Check the actual dedicated export and keep it running for the client tests.

func _initialize() -> void:
	call_deferred("_verify_server")

func _verify_server() -> void:
	var server: Node = root.get_node_or_null("Server")
	if server == null or not OS.has_feature("dedicated_server"):
		printerr("EXPORT_SERVER_FAILED: missing dedicated server feature/autoload")
		quit(1)
		return
	var peer: ENetMultiplayerPeer = server.get("peer")
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		printerr("EXPORT_SERVER_FAILED: could not listen")
		quit(1)
		return
	var texture := load("res://assets/meshes/props/construction_mesh_green_transparent.png")
	if not texture is PlaceholderTexture2D:
		printerr("EXPORT_SERVER_FAILED: expected stripped texture placeholder")
		quit(1)
		return
	printerr("EXPORT_SERVER_READY dedicated_server=true strip_visuals=true")
