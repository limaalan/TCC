extends Control

const BLUE_TEAM_COLOR := '0087FF'
const RED_TEAM_COLOR :='FF4D00'
const KOTH_OBJECTIVE_TEXT := "Primeiro time a chegar a %s"

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var minutes_left_label: Label = %MinutesLeftLabel
@onready var seconds_left_label: Label = %SecondsLeftLabel
@onready var mode_objective_label: Label = %ModeObjectiveLabel
@onready var progress_bars_container: VBoxContainer = %ProgressBarsContainer
@onready var blue_team_progress_bar: ProgressBar = %BlueTeamProgressBar
@onready var red_team_progress_bar: ProgressBar = %RedTeamProgressBar
@onready var hill_state_label: Label = %HillStateLabel
@onready var elimination_text_container: VBoxContainer = %EliminationTextContainer

var blue_score := 0
var red_score := 0
var score_to_win := 1
var current_mode := -1

func _ready() -> void:
	update_score(0,0)
	update_match_time_left(0)
	mode_objective_label.visible = false
	progress_bars_container.visible = false
	hill_state_label.visible = false
	
func update_score(blue_score:int , red_score:int)->void:
	self.blue_score = blue_score
	self.red_score = red_score
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)
	update_progress_bars()


func update_match_meta(match_meta: Dictionary) -> void:
	if not NetPayloads.is_match_meta(match_meta):
		return

	current_mode = match_meta[NetKeys.MODE]
	score_to_win = maxi(1, match_meta[NetKeys.SCORE_TO_WIN])
	mode_objective_label.text = KOTH_OBJECTIVE_TEXT % score_to_win

	var is_koth_mode := current_mode == GameEnums.GameMode.KING_OF_THE_HILL
	mode_objective_label.visible = is_koth_mode
	progress_bars_container.visible = is_koth_mode
	hill_state_label.visible = is_koth_mode

	if is_koth_mode and hill_state_label.text.is_empty():
		hill_state_label.text = "Hill vazia"

	update_progress_bars()

func update_match_time_left(time_left:int)->void:
	var minutes_left := time_left /60 
	var seconds_left := time_left - minutes_left*60
	
	minutes_left_label.text = str(minutes_left).lpad(2,"0")
	seconds_left_label.text = str(seconds_left).lpad(2,"0")

func update_hill_state(hill_state: Dictionary) -> void:
	if not NetPayloads.is_hill_state(hill_state):
		return

	var control_state: int = hill_state[NetKeys.HILL_CONTROL_STATE]
	var controlling_team: int = hill_state[NetKeys.HILL_CONTROLLING_TEAM]

	match control_state:
		GameEnums.HillControlState.EMPTY:
			hill_state_label.text = "Hill vazia"
		GameEnums.HillControlState.CONTESTED:
			hill_state_label.text = "Hill disputada"
		GameEnums.HillControlState.CONTROLLED:
			if controlling_team == GameEnums.Team.BLUE:
				hill_state_label.text = "Azul controlando"
			elif controlling_team == GameEnums.Team.RED:
				hill_state_label.text = "Vermelho controlando"
			else:
				hill_state_label.text = "Hill controlada"
		_:
			hill_state_label.text = "Hill desconhecida"

	hill_state_label.visible = current_mode == GameEnums.GameMode.KING_OF_THE_HILL


func update_progress_bars() -> void:
	blue_team_progress_bar.max_value = score_to_win
	red_team_progress_bar.max_value = score_to_win
	blue_team_progress_bar.value = clamp(blue_score, 0, score_to_win)
	red_team_progress_bar.value = clamp(red_score, 0, score_to_win)

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
