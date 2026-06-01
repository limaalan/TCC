extends Control

const BLUE_TEAM_COLOR := '0087FF'
const RED_TEAM_COLOR :='FF4D00'
const TDM_MATCH_INFO_UI_SCENE := preload("res://ui/match_info/modes/tdm_match_info_ui.tscn")
const KOTH_MATCH_INFO_UI_SCENE := preload("res://ui/match_info/modes/koth_match_info_ui.tscn")
const MODE_HUD_SCENES := {
	GameEnums.GameMode.TEAM_DEATHMATCH: TDM_MATCH_INFO_UI_SCENE,
	GameEnums.GameMode.KING_OF_THE_HILL: KOTH_MATCH_INFO_UI_SCENE,
}
const METHOD_UPDATE_MATCH_META := &"update_match_meta"
const METHOD_UPDATE_SCORE := &"update_score"
const METHOD_UPDATE_HILL_STATE := &"update_hill_state"

@onready var minutes_left_label: Label = %MinutesLeftLabel
@onready var seconds_left_label: Label = %SecondsLeftLabel
@onready var mode_hud_container: Control = %ModeHudContainer
@onready var elimination_text_container: VBoxContainer = %EliminationTextContainer

var blue_score := 0
var red_score := 0
var current_mode := -1
var current_hill_state := {}
var current_match_meta := {}
var mode_hud: Control

func _ready() -> void:
	update_match_time_left(0)
	
func update_score(blue_score:int , red_score:int)->void:
	self.blue_score = blue_score
	self.red_score = red_score
	_call_mode_hud(METHOD_UPDATE_SCORE, [blue_score, red_score])


func update_match_meta(match_meta: Dictionary) -> void:
	if not NetPayloads.is_match_meta(match_meta):
		return

	current_match_meta = match_meta.duplicate(true)
	var new_mode: int = match_meta[NetKeys.MODE]
	if current_mode != new_mode or mode_hud == null:
		current_mode = new_mode
		instantiate_mode_hud(new_mode)

	_apply_cached_mode_hud_state()

func update_match_time_left(time_left:int)->void:
	var minutes_left := time_left /60 
	var seconds_left := time_left - minutes_left*60
	
	minutes_left_label.text = str(minutes_left).lpad(2,"0")
	seconds_left_label.text = str(seconds_left).lpad(2,"0")

func update_hill_state(hill_state: Dictionary) -> void:
	if not NetPayloads.is_hill_state(hill_state):
		return

	current_hill_state = hill_state.duplicate(true)
	_call_mode_hud(METHOD_UPDATE_HILL_STATE, [hill_state])

func show_elimination_text(killer_id :int, victim_id:int , killer_name:String , killer_team:int , victim_name :String, victim_team : int)->void:
	var elimination_text := preload("res://ui/match_info/elimination_text.tscn").instantiate()
	var killer_color = BLUE_TEAM_COLOR if killer_team == GameEnums.Team.BLUE else RED_TEAM_COLOR
	var victim_color = BLUE_TEAM_COLOR if victim_team == GameEnums.Team.BLUE else RED_TEAM_COLOR
	
	elimination_text.text = "[color=#%s]%s[/color] eliminated [color=#%s]%s[/color]" %[
		killer_color,
		killer_name, 
		victim_color, 
		victim_name
	]
	elimination_text_container.add_child(elimination_text)


func instantiate_mode_hud(mode: int) -> void:
	if is_instance_valid(mode_hud):
		mode_hud.queue_free()
		mode_hud = null

	var scene: PackedScene = MODE_HUD_SCENES.get(mode)
	if scene == null:
		return

	mode_hud = scene.instantiate()
	mode_hud_container.add_child(mode_hud)


func _apply_cached_mode_hud_state() -> void:
	if not is_instance_valid(mode_hud):
		return

	if not current_match_meta.is_empty():
		_call_mode_hud(METHOD_UPDATE_MATCH_META, [current_match_meta])

	_call_mode_hud(METHOD_UPDATE_SCORE, [blue_score, red_score])

	if not current_hill_state.is_empty() and NetPayloads.is_hill_state(current_hill_state):
		_call_mode_hud(METHOD_UPDATE_HILL_STATE, [current_hill_state])


func _call_mode_hud(method_name: StringName, args: Array = []) -> void:
	if not is_instance_valid(mode_hud):
		return

	if not mode_hud.has_method(method_name):
		return

	mode_hud.callv(method_name, args)
