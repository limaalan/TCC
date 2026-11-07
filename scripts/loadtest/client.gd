extends SceneTree
## Client driver for load testing with the game's scenes, physics, and RPCs.

class ShotObserver extends Node:
	var shots := 0
	func local_shot_fired() -> void:
		# Called only after LocalWeaponHolder actually spends ammunition and fires.
		shots += 1

const ACTIONS := ["move_left", "move_right", "move_forward", "move_backward", "sprint", "jump", "shoot", "throw_grenade"]
const BOOTSTRAP_TIMEOUT_MS := 90000
const ACTIVITY_WINDOW_SEC := 20.0
const MIN_WINDOW_DISTANCE_M := 1.0
const MAX_NO_ACTIVE_PLAYER_SEC := 20.0
const MIN_ACTIVE_RATIO := 0.5
const WORKLOAD_PROFILE := "smg-single-pulse-2s-v1"
const WORKLOAD_WEAPON_ID := 1
const SHOT_INTERVAL_MS := 2000

var server: Node
var observer: ShotObserver
var rng := RandomNumberGenerator.new()
var mode := "bot"
var expected_players := 2
var duration_sec := 30.0
var warmup_sec := 0.0
var start_file := ""
var stop_file := ""
var csv: FileAccess
var drive_enabled := false
var measurement_started := false
var activity_validated := false
var phase := "bootstrap"
var start_ms := 0
var last_csv_ms := 0
var next_selection_ms := 0
var previous_player_id := 0
var previous_position := Vector3.ZERO
var previous_health := 1.0
var last_motion_ms := 0
var recovery_until_ms := 0
var recovery_yaw := 0.0
var selection_count := 0
var selected_ui_activations := {}
var next_shot_ms := 0
var spawns := 0
var deaths := 0
var damage_updates := 0
var jumps_requested := 0
var grenade_requests := 0
var shot_attempts := 0
var distance_m := 0.0
var stationary_sec := 0.0
var active_physics_frames := 0
var snapshot_updates := 0
var active_sec := 0.0
var windows_checked := 0
var window_active_sec := 0.0
var window_distance_m := 0.0
var window_start_shots := 0
var last_frame_ms := 0
var no_active_player_since_ms := 0
var last_snapshot_timestamp := -1
var last_snapshot_update_ms := 0
var last_jump := false
var last_grenade := false
var last_shoot := false
var finished := false

func _initialize() -> void:
	call_deferred("_run")

func _argument(key: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % key):
			return argument.trim_prefix("--%s=" % key)
	return fallback

func _run() -> void:
	mode = _argument("mode", "bot")
	expected_players = int(_argument("players", "2"))
	duration_sec = float(_argument("duration", "30"))
	warmup_sec = float(_argument("warmup", "0"))
	start_file = _argument("start-file", "")
	stop_file = _argument("stop-file", "")
	rng.seed = int(_argument("seed", "1"))
	if mode not in ["bot", "human"] or expected_players < 2 or expected_players > 64 or duration_sec <= 0 or warmup_sec < 0:
		_fail("Invalid mode, players, duration or warmup")
		return
	var csv_path := _argument("activity-csv", "")
	if not csv_path.is_empty():
		csv = FileAccess.open(csv_path, FileAccess.WRITE)
		if csv == null:
			_fail("Cannot create activity CSV: %s" % csv_path)
			return
		csv.store_csv_line(PackedStringArray(["timestamp_ms", "elapsed_sec", "phase", "peer_id", "mode", "x", "y", "z", "distance_m", "shots", "shot_attempts", "jump_requests", "grenade_requests", "spawns", "deaths", "damage_updates", "active_physics_frames", "snapshots", "max_stationary_sec", "active_sec", "windows_checked", "window_active_sec", "window_distance_m", "window_shots"]))
	if change_scene_to_file("res://game/main_game.tscn") != OK:
		_fail("Cannot load real Client main scene")
		return
	await process_frame
	await process_frame
	server = root.get_node_or_null("Server")
	if server == null:
		_fail("Client Server autoload missing")
		return
	observer = ShotObserver.new()
	root.add_child(observer)
	observer.add_to_group("Lobby")
	physics_frame.connect(_drive_frame)
	server.call("reconnect_to_server", _argument("host", "127.0.0.1"), int(_argument("port", "17777")))
	var deadline := Time.get_ticks_msec() + BOOTSTRAP_TIMEOUT_MS
	while not server.call("is_connected_to_server"):
		if Time.get_ticks_msec() > deadline:
			_fail("Server connection timeout")
			return
		await create_timer(0.05).timeout
	server.call("try_connect_client_to_lobby", _argument("name", "LoadBot"), StringName(_argument("preset", "koth_highrise")))
	drive_enabled = true
	while not _match_ready():
		if Time.get_ticks_msec() > deadline or not server.call("is_connected_to_server"):
			_fail("Map, weapon selection or full-room startup timeout")
			return
		await create_timer(0.05).timeout
	phase = "ready"
	var ready_lobby := _lobby()
	var roster_peer_ids: Array = ready_lobby.get("player_names_and_teams").keys()
	roster_peer_ids.sort()
	print("LOADTEST_READY ", JSON.stringify({"peer_id": server.multiplayer.get_unique_id(), "mode": mode, "players": expected_players, "lobby_name": str(ready_lobby.name), "roster_peer_ids": roster_peer_ids, "workload_profile": _workload_profile()}))
	while not start_file.is_empty() and not FileAccess.file_exists(start_file):
		if Time.get_ticks_msec() > deadline or not _room_alive():
			_fail("Start barrier timeout or room ended")
			return
		await create_timer(0.05).timeout
	phase = "warmup"
	var warmup_end := Time.get_ticks_msec() + int(warmup_sec * 1000)
	while Time.get_ticks_msec() < warmup_end:
		if not _room_alive():
			_fail("Room ended during warmup")
			return
		await create_timer(0.05).timeout
	_reset_measurement()
	phase = "measure"
	measurement_started = true
	start_ms = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_ms < duration_sec * 1000:
		if not _room_alive():
			_fail("Room or connection ended before measurement completed")
			return
		if Time.get_ticks_msec() - last_snapshot_update_ms > 5000:
			_fail("No fresh snapshot for more than five seconds")
			return
		await create_timer(0.05).timeout
	_write_row()
	measurement_started = false
	if mode == "bot" and not _check_activity_window(true):
		return
	if mode == "bot" and active_sec < duration_sec * MIN_ACTIVE_RATIO:
		_fail("Insufficient live activity: %s" % JSON.stringify(_summary()))
		return
	if mode == "bot" and (distance_m < 1.0 or observer.shots < 1 or snapshot_updates < 2):
		_fail("Bot completed time without real movement, shots or fresh snapshots: %s" % JSON.stringify(_summary()))
		return
	activity_validated = mode == "bot"
	print("LOADTEST_DONE ", JSON.stringify(_summary()))
	phase = "hold"
	# Keep peers active until every Client has completed its own window.
	if not stop_file.is_empty():
		var stop_deadline := Time.get_ticks_msec() + 60000
		while not FileAccess.file_exists(stop_file):
			if not _room_alive() or Time.get_ticks_msec() > stop_deadline:
				_fail("Stop barrier timeout or room ended while waiting for other participants")
				return
			await create_timer(0.05).timeout
	await _finish()

func _lobby() -> Node:
	if not is_instance_valid(server):
		return null
	for child in server.get_children():
		if child.has_method("get_local_player") and child.has_method("weapon_selected"):
			return child
	return null

func _match_ready() -> bool:
	var lobby := _lobby()
	if lobby == null or not lobby.is_physics_processing():
		return false
	var players: Dictionary = lobby.get("players")
	var states: Array = lobby.get("world_state_buffer")
	var player = lobby.call("get_local_player")
	return players.size() == expected_players and states.size() >= 2 and is_instance_valid(player) and not bool(player.get("is_frozen"))

func _room_alive() -> bool:
	if not is_instance_valid(server) or not server.call("is_connected_to_server"):
		return false
	var lobby := _lobby()
	return lobby != null and lobby.is_physics_processing() and lobby.get("player_names_and_teams").size() == expected_players

func _reset_measurement() -> void:
	observer.shots = 0
	spawns = 0
	deaths = 0
	damage_updates = 0
	jumps_requested = 0
	grenade_requests = 0
	shot_attempts = 0
	distance_m = 0.0
	stationary_sec = 0.0
	active_physics_frames = 0
	snapshot_updates = 0
	active_sec = 0.0
	windows_checked = 0
	window_active_sec = 0.0
	window_distance_m = 0.0
	window_start_shots = 0
	last_frame_ms = Time.get_ticks_msec()
	no_active_player_since_ms = 0
	last_snapshot_timestamp = -1
	last_snapshot_update_ms = Time.get_ticks_msec()
	previous_player_id = 0
	last_csv_ms = 0

func _drive_frame() -> void:
	if not drive_enabled or finished:
		return
	var lobby := _lobby()
	if lobby == null:
		return
	var now := Time.get_ticks_msec()
	var frame_elapsed_sec := 0.0
	if last_frame_ms > 0:
		frame_elapsed_sec = maxf(0.0, (now - last_frame_ms) / 1000.0)
	last_frame_ms = now
	if measurement_started:
		_sample_feed(lobby, now)
	if mode == "bot":
		# Headless bots need to process input without window focus.
		var guard := root.get_node_or_null("GamepadFocusGuard")
		if guard != null:
			guard.set_process(false)
			guard.set("_application_has_focus", true)
		if now >= next_selection_ms:
			var selection_player = lobby.call("get_local_player")
			for ui in get_nodes_in_group("WeaponSelectionUI"):
				if not ui is Control or not ui.is_node_ready():
					continue
				var ui_id: int = ui.get_instance_id()
				var selection_timer = ui.get("auto_select_timer")
				var activated: bool = ui.visible and selection_timer is Timer and not selection_timer.is_stopped()
				if not activated:
					selected_ui_activations.erase(ui_id)
					continue
				# This scene is visible by default before activate() arrives. Only
				# its running timer proves a legitimate selection phase. Selecting
				# again while alive would ask the Server to spawn a duplicate peer.
				if is_instance_valid(selection_player) or selected_ui_activations.has(ui_id):
					continue
				selected_ui_activations[ui_id] = true
				var selected_weapon := WORKLOAD_WEAPON_ID
				selection_count += 1
				print("LOADTEST_SELECTION ", JSON.stringify({"count": selection_count,
					"weapon_id": selected_weapon, "phase": phase, "lobby_name": str(lobby.name),
					"ui_id": ui_id, "timer_running": true, "local_player_present": false}))
				ui.call("weapon_selected", selected_weapon)
			next_selection_ms = now + 100
	var player = lobby.call("get_local_player")
	if not is_instance_valid(player):
		if previous_player_id != 0:
			if measurement_started:
				deaths += 1
			previous_player_id = 0
		_check_no_active_player(now)
		_release_actions()
		return
	var player_active: bool = not bool(player.get("is_frozen")) and player.is_physics_processing()
	if player_active:
		no_active_player_since_ms = 0
	else:
		_check_no_active_player(now)
	var instance_id: int = player.get_instance_id()
	var position: Vector3 = player.global_position
	if instance_id != previous_player_id:
		previous_player_id = instance_id
		previous_position = position
		previous_health = float(player.health_bar.value)
		last_motion_ms = now
		# One input pulse per interval, staggered by seed. Never replenish ammo
		# or manufacture a respawn to keep this workload alive.
		next_shot_ms = now + rng.randi_range(0, SHOT_INTERVAL_MS - 1)
		if measurement_started:
			spawns += 1
	else:
		var displacement := Vector2(position.x - previous_position.x, position.z - previous_position.z).length()
		if measurement_started:
			distance_m += displacement
			if player_active:
				window_distance_m += displacement
				active_sec += frame_elapsed_sec
				window_active_sec += frame_elapsed_sec
		if displacement > 0.005:
			last_motion_ms = now
		var health := float(player.health_bar.value)
		if measurement_started and health < previous_health - 0.001:
			damage_updates += 1
		previous_health = health
	previous_position = position
	if measurement_started:
		active_physics_frames += 1
		stationary_sec = maxf(stationary_sec, (now - last_motion_ms) / 1000.0)
		if mode == "bot" and not _check_activity_window():
			return
	if mode == "bot" and not bool(player.get("is_frozen")):
		_drive_bot(lobby, player, now)

func _sample_feed(lobby: Node, now: int) -> void:
	# Snapshot reception continues while the local character is dead/selecting.
	var states: Array = lobby.get("world_state_buffer")
	if not states.is_empty():
		var stamp := int(states.back().get("t", -1))
		if stamp != last_snapshot_timestamp:
			snapshot_updates += 1
			last_snapshot_timestamp = stamp
			last_snapshot_update_ms = now
	if now - last_csv_ms >= 1000:
		_write_row()
		last_csv_ms = now

func _check_no_active_player(now: int) -> void:
	if not measurement_started or mode != "bot":
		return
	if no_active_player_since_ms == 0:
		no_active_player_since_ms = now
	elif now - no_active_player_since_ms > MAX_NO_ACTIVE_PLAYER_SEC * 1000:
		_fail("No active player for more than %s seconds (death/selection/freeze): %s" % [MAX_NO_ACTIVE_PLAYER_SEC, JSON.stringify(_summary())])

func _check_activity_window(final_window := false) -> bool:
	# Windows accumulate live time across respawns. Dying never erases an
	# inactive partial window; spawn displacement is excluded upstream.
	if window_active_sec < ACTIVITY_WINDOW_SEC and not final_window:
		return true
	if final_window and window_active_sec < 5.0:
		return true
	var minimum_distance := MIN_WINDOW_DISTANCE_M * minf(1.0, window_active_sec / ACTIVITY_WINDOW_SEC)
	var window_shots := observer.shots - window_start_shots
	if window_distance_m < minimum_distance or window_shots < 1:
		_fail("Unsustained bot activity: %s" % JSON.stringify({
			"peer_id": server.multiplayer.get_unique_id(), "window_active_sec": window_active_sec,
			"window_distance_m": window_distance_m, "window_shots": window_shots,
			"required_distance_m": minimum_distance, "required_shots": 1,
			"windows_checked": windows_checked, "elapsed_sec": (Time.get_ticks_msec() - start_ms) / 1000.0}))
		return false
	windows_checked += 1
	window_active_sec = 0.0
	window_distance_m = 0.0
	window_start_shots = observer.shots
	return true

func _drive_bot(lobby: Node, player: Node3D, now: int) -> void:
	var seconds := now / 1000.0
	var seed_offset := float(rng.seed % 97) / 13.0
	var target: Node3D = null
	var target_distance := INF
	# Prioritize visible ammo/weapon pickups if ammunition runs out.
	if int(player.call("get_current_weapon_ammo")) == 0:
		for pickup in lobby.get("pickups").values():
			if is_instance_valid(pickup) and int(pickup.get("pickup_type")) in [2, 3] and pickup.mesh_holder.visible:
				var distance: float = player.global_position.distance_squared_to(pickup.global_position)
				if distance < target_distance:
					target = pickup
					target_distance = distance
	else:
		for other in lobby.call("get_remote_players").values():
			if is_instance_valid(other) and int(other.get("team")) != int(player.get("team")):
				var distance: float = player.global_position.distance_squared_to(other.global_position)
				if distance < target_distance:
					target = other
					target_distance = distance
	var desired_yaw := player.rotation.y + 0.012 * sin(seconds + seed_offset)
	var desired_pitch := 0.0
	if is_instance_valid(target):
		var aim_position := target.global_position + Vector3(0, 0.9, 0)
		var difference: Vector3 = aim_position - player.head.global_position
		desired_yaw = atan2(-difference.x, -difference.z)
		desired_pitch = atan2(difference.y, Vector2(difference.x, difference.z).length())
	if now - last_motion_ms > 1800 and now > recovery_until_ms:
		recovery_until_ms = now + 1500
		recovery_yaw = player.rotation.y + rng.randf_range(0.9, 2.3) * [-1.0, 1.0][rng.randi_range(0, 1)]
	if now < recovery_until_ms:
		desired_yaw = recovery_yaw
	var yaw_delta := wrapf(player.rotation.y - desired_yaw, -PI, PI)
	player.call("look_around", Vector2(yaw_delta / float(player.mouse_sensitivity), (player.head.rotation.x - desired_pitch) / float(player.mouse_sensitivity)))
	var moving_forward := target_distance > 16.0 or now < recovery_until_ms
	_set_action("move_forward", moving_forward)
	_set_action("move_backward", not moving_forward and fmod(seconds + seed_offset, 6.0) < 1.0)
	_set_action("move_left", fmod(seconds + seed_offset, 5.0) < 1.6)
	_set_action("move_right", fmod(seconds + seed_offset, 5.0) > 3.3)
	_set_action("sprint", moving_forward)
	var jump := fmod(seconds + seed_offset, 1.8) < 0.08
	_set_action("jump", jump)
	if jump and not last_jump and measurement_started:
		jumps_requested += 1
	last_jump = jump
	# A single physics-frame pulse goes through the ordinary automatic weapon
	# trigger/cooldown path; this is deliberately not continuous SMG fire.
	var shoot := now >= next_shot_ms
	if shoot:
		next_shot_ms = now + SHOT_INTERVAL_MS
	_set_action("shoot", shoot)
	if shoot and not last_shoot and measurement_started:
		shot_attempts += 1
	last_shoot = shoot
	var grenade := fmod(seconds + seed_offset, 9.0) < 0.08
	_set_action("throw_grenade", grenade)
	if grenade and not last_grenade and measurement_started:
		grenade_requests += 1
	last_grenade = grenade

func _set_action(action: StringName, pressed: bool) -> void:
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	elif Input.is_action_pressed(action):
		Input.action_release(action)

func _release_actions() -> void:
	if mode != "bot":
		return
	for action in ACTIONS:
		Input.action_release(action)

func _summary() -> Dictionary:
	return {"peer_id": server.multiplayer.get_unique_id(), "mode": mode, "players": expected_players,
		"workload_profile": _workload_profile(),
		"elapsed_sec": (Time.get_ticks_msec() - start_ms) / 1000.0, "distance_m": distance_m,
		"shots": observer.shots, "shot_attempts": shot_attempts, "jump_requests": jumps_requested, "grenade_requests": grenade_requests,
		"spawns": spawns, "deaths": deaths, "damage_updates": damage_updates,
		"active_physics_frames": active_physics_frames, "snapshots": snapshot_updates,
		"max_stationary_sec": stationary_sec, "active_sec": active_sec,
		"activity_windows_checked": windows_checked, "activity_validated": activity_validated,
		"last_snapshot_age_sec": (Time.get_ticks_msec() - last_snapshot_update_ms) / 1000.0}

func _workload_profile() -> String:
	return WORKLOAD_PROFILE if mode == "bot" else "human-manual"

func _write_row() -> void:
	if csv == null:
		return
	var player = null
	var lobby := _lobby()
	if lobby != null:
		player = lobby.call("get_local_player")
	var position := Vector3.ZERO
	if is_instance_valid(player):
		position = player.global_position
	csv.store_csv_line(PackedStringArray([
		str(int(Time.get_unix_time_from_system() * 1000)), str((Time.get_ticks_msec() - start_ms) / 1000.0),
		phase, str(server.multiplayer.get_unique_id()), mode, str(position.x), str(position.y), str(position.z),
		str(distance_m), str(observer.shots), str(shot_attempts), str(jumps_requested), str(grenade_requests), str(spawns), str(deaths),
		str(damage_updates), str(active_physics_frames), str(snapshot_updates), str(stationary_sec),
		str(active_sec), str(windows_checked), str(window_active_sec), str(window_distance_m),
		str(observer.shots - window_start_shots)]))
	csv.flush()

func _finish() -> void:
	finished = true
	drive_enabled = false
	_release_actions()
	if csv != null:
		csv.flush()
		csv.close()
	var lobby := _lobby()
	if lobby != null and server.call("is_connected_to_server"):
		lobby.set_physics_process(false)
		lobby.rpc_id(1, "c_client_quit_match")
	await create_timer(0.3).timeout
	quit(0)

func _fail(message: String) -> void:
	if finished:
		return
	finished = true
	drive_enabled = false
	_release_actions()
	if csv != null:
		csv.flush()
	print("LOADTEST_FAILED ", message)
	quit(1)
