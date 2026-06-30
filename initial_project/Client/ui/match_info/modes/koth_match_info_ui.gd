extends Control

const KOTH_OBJECTIVE_TEXT := "Primeiro time a chegar a %s"

@onready var mode_objective_label: Label = %ModeObjectiveLabel
@onready var blue_team_progress_bar: ProgressBar = %BlueTeamProgressBar
@onready var red_team_progress_bar: ProgressBar = %RedTeamProgressBar
@onready var hill_state_label: Label = %HillStateLabel

var blue_score := 0
var red_score := 0
var score_to_win := 1


func _ready() -> void:
	update_score(0, 0)
	mode_objective_label.text = KOTH_OBJECTIVE_TEXT % score_to_win
	hill_state_label.text = "Hill vazia"


func update_match_meta(match_meta: Dictionary) -> void:
	if not NetPayloads.is_match_meta(match_meta):
		return

	score_to_win = maxi(1, match_meta[NetKeys.SCORE_TO_WIN])
	mode_objective_label.text = KOTH_OBJECTIVE_TEXT % score_to_win
	update_progress_bars()


func update_score(blue_score: int, red_score: int) -> void:
	self.blue_score = blue_score
	self.red_score = red_score
	update_progress_bars()


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


func update_progress_bars() -> void:
	blue_team_progress_bar.max_value = score_to_win
	red_team_progress_bar.max_value = score_to_win
	blue_team_progress_bar.value = clamp(blue_score, 0, score_to_win)
	red_team_progress_bar.value = clamp(red_score, 0, score_to_win)
