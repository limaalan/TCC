extends SceneTree
## Real grenade/Area3D regression: the thrower's node may die before detonation.

var grenade_scene: PackedScene
var player_script: Script
var victim_script: GDScript


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Load after autoload registration: Lobby references the Server singleton.
	grenade_scene = load("res://player/grenade/grenade.tscn")
	player_script = load("res://player/player_server_real.gd")
	victim_script = GDScript.new()
	victim_script.source_code = "extends \"res://player/player_server_real.gd\"\nvar received_damage := false\nvar observed_killer_id := -1\nfunc change_health(_amount: int, killer_id: int = 0) -> void:\n\treceived_damage = true\n\tobserved_killer_id = killer_id\n"
	if victim_script.reload() != OK:
		_fail("Could not compile the damage-capturing subclass")
		return
	if not await _check_detonation_after_owner_freed(795800544, false):
		return
	if not await _check_detonation_after_owner_freed(820382737, true):
		return
	print("LOADTEST_GRENADE_OWNER_OK cases=2 real_physics=true")
	quit(0)


func _check_detonation_after_owner_freed(peer_id: int, explicit_id: bool) -> bool:
	var owner = player_script.new()
	owner.name = "RenamedThrower" if explicit_id else str(peer_id)
	owner.position = Vector3(20, 0, 0)
	root.add_child(owner)
	var victim = victim_script.new()
	victim.name = "Victim"
	victim.collision_layer = 2
	victim.collision_mask = 0
	var body_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	body_shape.shape = sphere
	victim.add_child(body_shape)
	root.add_child(victim)
	var grenade: RigidBody3D = grenade_scene.instantiate()
	grenade.gravity_scale = 0.0
	grenade.set("lifetime", 60.0)
	grenade.set("throw_impulse_strength", 0.0)
	if explicit_id:
		grenade.call("set_data", null, Vector3.ZERO, owner, peer_id)
	else:
		grenade.call("set_data", null, Vector3.ZERO, owner)
	root.add_child(grenade)
	# Allow the real physics server to populate the grenade's overlap list.
	for frame in 4:
		await physics_frame
	await process_frame
	if not grenade.get_node("ExplosionDamageArea").get_overlapping_bodies().has(victim):
		_fail("Fixture did not produce a real grenade/victim overlap")
		return false
	owner.free()
	grenade.call("explode")
	if not victim.received_damage or victim.observed_killer_id != peer_id:
		_fail("Freed thrower lost attribution: expected=%s observed=%s explicit=%s" % [peer_id, victim.observed_killer_id, explicit_id])
		return false
	victim.free()
	await process_frame
	return true


func _fail(message: String) -> void:
	printerr("LOADTEST_GRENADE_OWNER_FAILED: %s" % message)
	quit(1)
