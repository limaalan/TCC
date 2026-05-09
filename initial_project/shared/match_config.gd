class_name MatchConfig
extends Resource

const DEFAULT_MODE := GameEnums.GameMode.TEAM_DEATHMATCH
const DEFAULT_MAP_ID := &"prototype"
const DEFAULT_TIME_LIMIT_SEC := 300
const DEFAULT_SCORE_TO_WIN := 2
const DEFAULT_LIVES_PER_PLAYER := 0
const DEFAULT_MAX_PLAYERS := 2

@export var mode: GameEnums.GameMode = DEFAULT_MODE
@export var map_id: StringName = DEFAULT_MAP_ID
@export var time_limit_sec := DEFAULT_TIME_LIMIT_SEC
@export var score_to_win := DEFAULT_SCORE_TO_WIN
# 0 keeps lives disabled for the current team deathmatch flow.
@export var lives_per_player := DEFAULT_LIVES_PER_PLAYER
@export var max_players := DEFAULT_MAX_PLAYERS
