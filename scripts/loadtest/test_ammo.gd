extends SceneTree
## Real inventory/catalog regression: large experimental ammunition, normal defaults.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog = load("res://shared/weapons/weapon_catalog.gd")
	var inventory_script = load("res://shared/weapons/weapon_ammo_inventory.gd")
	var experimental := OS.get_cmdline_user_args().has("--expect-loadtest")
	var defaults := {0: 36, 1: 90, 2: 18}
	for weapon in catalog.get_all_weapons():
		var expected: int = 10000 if experimental else defaults[weapon.id]
		var inventory = inventory_script.new()
		inventory.setup_spawn_ammo(weapon.id)
		if inventory.get_ammo(weapon.id) != expected:
			_fail("Spawn ammunition: weapon=%s expected=%s observed=%s" % [weapon.id, expected, inventory.get_ammo(weapon.id)])
			return
		if not inventory.spend_for_shot(weapon.id) or inventory.get_ammo(weapon.id) != expected - 1:
			_fail("Real shots must still consume one ammunition")
			return
		var recipient = inventory_script.new()
		recipient.apply_snapshot(inventory.make_snapshot())
		if recipient.get_ammo(weapon.id) != expected - 1:
			_fail("Server/client snapshots must not clamp the experimental ammunition back to normal capacity")
			return
		var path: String = catalog.WEAPON_DEFINITION_PATHS[weapon.id]
		var original = load(path)
		if original.start_ammo != defaults[weapon.id]:
			_fail("Experimental catalog must not mutate the cached original weapon resource")
			return
	print("LOADTEST_AMMO_OK weapons=3 experimental=%s" % experimental)
	quit(0)

func _fail(message: String) -> void:
	printerr("LOADTEST_AMMO_FAILED: ", message)
	quit(1)
