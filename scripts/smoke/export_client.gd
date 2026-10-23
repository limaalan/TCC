extends SceneTree
## External test driver: loads the real exported game, without changes to gameplay.

func _initialize() -> void:
	call_deferred("_run_export_check")

func _argument(key: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % key):
			return argument.trim_prefix("--%s=" % key)
	return fallback

func _run_export_check() -> void:
	var error := change_scene_to_file("res://game/main_game.tscn")
	if error != OK:
		_fail("Cannot open exported main scene")
		return
	await process_frame
	await process_frame
	var server: Node = root.get_node_or_null("Server")
	if server == null:
		_fail("Missing Server autoload")
		return
	server.call("reconnect_to_server", _argument("host", "127.0.0.1"), int(_argument("port", "17777")))
	var deadline := Time.get_ticks_msec() + 30000
	while not server.call("is_connected_to_server"):
		if Time.get_ticks_msec() > deadline:
			_fail("Connection timeout")
			return
		await create_timer(0.1).timeout
	if _argument("mode", "match") == "connect":
		printerr("EXPORT_CONNECT_OK")
		await create_timer(2.0).timeout
		quit(0)
		return
	var preset := _argument("preset", "tdm_highrise")
	server.call("try_connect_client_to_lobby", _argument("name", "Smoke"), StringName(preset))
	var selected := false
	while Time.get_ticks_msec() < deadline:
		for child in server.get_children():
			if not child.has_method("weapon_selected"):
				continue
			if not selected and child.get_node_or_null("Map") != null:
				for ui in get_nodes_in_group("WeaponSelectionUI"):
					if ui is Control and ui.visible:
						ui.call("weapon_selected", 0)
						selected = true
			var players: Dictionary = child.get("players")
			var states: Array = child.get("world_state_buffer")
			if child.is_physics_processing() and players.size() == 2 and states.size() >= 2:
				await create_timer(3.0).timeout
				printerr("EXPORT_MATCH_OK preset=%s players=%s" % [preset, players.size()])
				await create_timer(2.0).timeout
				if is_instance_valid(child) and child.is_inside_tree():
					child.set_physics_process(false)
					child.rpc_id(1, "c_client_quit_match")
				await create_timer(0.5).timeout
				quit(0)
				return
		await create_timer(0.1).timeout
	_fail("Map/spawn/world-state timeout for %s" % preset)

func _fail(message: String) -> void:
	printerr("EXPORT_CHECK_FAILED: %s" % message)
	quit(1)
