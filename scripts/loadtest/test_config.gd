extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	var options_script = load("res://shared/loadtest_config.gd")
	if options_script == null:
		_fail("Missing loadtest configuration implementation")
		return

	var baseline: Dictionary = options_script.parse(PackedStringArray())
	_check(baseline.ok and not baseline.enabled, "No flags must leave loadtest disabled")
	var unrelated: Dictionary = options_script.parse(PackedStringArray(["--port=17777", "--preset=koth_highrise"]))
	_check(unrelated.ok and not unrelated.enabled, "Unrelated game arguments must not enable loadtest")
	var defaults: Dictionary = options_script.parse(PackedStringArray(["--loadtest-players=8"]))
	_check(defaults.ok and defaults.enabled, "Explicit player count must enable loadtest")
	_check(defaults.players == 8 and defaults.duration == 900 and defaults.score == 10000, "Experimental defaults must keep a full observation window")
	_check(defaults.get("ammo") == 10000, "Experimental ammunition must last the observation window")
	var ammo_custom: Dictionary = options_script.parse(PackedStringArray(["--loadtest-players=2", "--loadtest-ammo=15000"]))
	_check(ammo_custom.ok and ammo_custom.get("ammo") == 15000, "Experimental ammunition override must be validated")
	var custom: Dictionary = options_script.parse(PackedStringArray([
		"--loadtest-score=1234", "--loadtest-players=3", "--loadtest-duration=1200",
	]))
	_check(custom.ok and custom.players == 3 and custom.duration == 1200 and custom.score == 1234, "Validated overrides must preserve supplied values")
	var invalid_cases := [
		["--loadtest-players=1"], ["--loadtest-players=65"],
		["--loadtest-players=128"], ["--loadtest-players=0"],
		["--loadtest-players=-2"], ["--loadtest-players=2.0"],
		["--loadtest-players=2abc"], ["--loadtest-players="],
		["--loadtest-players"], ["--loadtest-players=+2"],
		["--loadtest-players=2", "--loadtest-players=4"],
		["--loadtest-duration=900"], ["--loadtest-score=10000"],
		["--loadtest-players=2", "--loadtest-duration=0"],
		["--loadtest-players=2", "--loadtest-duration=-1"],
		["--loadtest-players=2", "--loadtest-duration=1.5"],
		["--loadtest-players=2", "--loadtest-duration=900", "--loadtest-duration=901"],
		["--loadtest-players=2", "--loadtest-score=0"],
		["--loadtest-players=2", "--loadtest-score=abc"],
		["--loadtest-players=2", "--loadtest-score=10", "--loadtest-score=20"],
		["--loadtest-players=99999999999999999999999999"],
		["--loadtest-players=2", "--loadtest-duration=999999999999999999999"],
		["--loadtest-players=2", "--loadtest-typo=2"],
		["--loadtest-ammo=10000"],
		["--loadtest-players=2", "--loadtest-ammo=0"],
		["--loadtest-players=2", "--loadtest-ammo=abc"],
		["--loadtest-players=2", "--loadtest-ammo=10000", "--loadtest-ammo=12000"],
	]
	for args in invalid_cases:
		var invalid: Dictionary = options_script.parse(PackedStringArray(args))
		_check(not invalid.ok and not str(invalid.error).is_empty(), "Invalid loadtest flags must be rejected: %s" % str(args))

	var registry = load("res://shared/match_preset_registry.gd")
	if OS.get_cmdline_user_args().has("--test-registry-invalid"):
		var rejected = registry.make_match_config(&"koth_highrise")
		_check(rejected == null, "Invalid runtime arguments must not return a usable match configuration")
		return
	for preset in [&"tdm_highrise", &"koth_highrise"]:
		var config = registry.make_match_config(preset)
		if OS.get_cmdline_user_args().has("--test-expect-custom"):
			_check(config.max_players == 3 and config.time_limit_sec == 1200 and config.score_to_win == 1234, "Registry must apply runtime overrides")
		elif OS.get_cmdline_user_args().has("--test-expect-loadtest"):
			_check(config.max_players == 8 and config.time_limit_sec == 900 and config.score_to_win == 10000, "Registry must use opt-in experimental defaults")
		else:
			_check(config.max_players == 2 and config.time_limit_sec == 300 and config.score_to_win == 20, "Production preset values must remain unchanged")
		_check(config.map_id == &"highrise" and config.lives_per_player == 0, "Overrides must preserve the existing map and lives rules")
		_check(config.mode == (0 if preset == &"tdm_highrise" else 1), "Overrides must preserve each preset's game mode")
	if failures == 0:
		print("LOADTEST_CONFIG_OK checks=%s" % checks)
	quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	printerr("LOADTEST_CONFIG_FAILED: %s" % message)
	quit(1)
