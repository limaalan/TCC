class_name MatchPresetRegistry
extends RefCounted

const LoadTestConfig = preload("res://shared/loadtest_config.gd")

const TDM_HIGHRISE := &"tdm_highrise"
const KOTH_HIGHRISE := &"koth_highrise"

const DEFAULT_PRESET_ID := KOTH_HIGHRISE

static func is_valid_preset_id(preset_id: StringName) -> bool:
	return preset_id == TDM_HIGHRISE or preset_id == KOTH_HIGHRISE


static func get_display_name(preset_id: StringName) -> String:
	match preset_id:
		TDM_HIGHRISE:
			return "Team Deathmatch"
		KOTH_HIGHRISE:
			return "King of the Hill"
		_:
			return "Unknown"


static func make_match_config(preset_id: StringName) -> MatchConfig:
	var config := MatchConfig.new()

	match preset_id:
		TDM_HIGHRISE:
			config.mode = GameEnums.GameMode.TEAM_DEATHMATCH
			config.map_id = &"highrise"
			config.time_limit_sec = 300
			config.score_to_win = 20
			config.lives_per_player = 0
			config.max_players = 2

		KOTH_HIGHRISE:
			config.mode = GameEnums.GameMode.KING_OF_THE_HILL
			config.map_id = &"highrise"
			config.time_limit_sec = 300
			config.score_to_win = 20
			config.lives_per_player = 0
			config.max_players = 2

		_:
			push_warning("Invalid match preset '%s'. Using default preset." % String(preset_id))
			return make_match_config(DEFAULT_PRESET_ID)

	var experimental := LoadTestConfig.parse(OS.get_cmdline_user_args())
	if not experimental.ok:
		printerr("LOADTEST_CONFIG_FAILED: %s" % experimental.error)
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.quit(2)
		return null
	if experimental.enabled:
		config.max_players = experimental.players
		config.time_limit_sec = experimental.duration
		config.score_to_win = experimental.score
	return config
