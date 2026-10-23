extends SceneTree
## Transport check only. Match/RPC compatibility is checked with exported clients.

var peer := ENetMultiplayerPeer.new()
var finished := false

func _initialize() -> void:
	call_deferred("_connect_probe")

func _argument(key: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % key):
			return argument.trim_prefix("--%s=" % key)
	return fallback

func _connect_probe() -> void:
	var host := _argument("host", "127.0.0.1")
	var port := int(_argument("port", "7777"))
	var seconds := float(_argument("timeout", "10"))
	get_multiplayer().connected_to_server.connect(_connected)
	get_multiplayer().connection_failed.connect(_failed)
	var error := peer.create_client(host, port)
	if error != OK:
		_failed()
		return
	get_multiplayer().multiplayer_peer = peer
	create_timer(seconds).timeout.connect(_failed)

func _connected() -> void:
	if finished:
		return
	finished = true
	print("ENET_PROBE_CONNECTED")
	peer.close()
	quit(0)

func _failed() -> void:
	if finished:
		return
	finished = true
	printerr("ENET_PROBE_FAILED")
	peer.close()
	quit(1)
