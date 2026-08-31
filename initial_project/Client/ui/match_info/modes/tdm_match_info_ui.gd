extends Control

const TDM_OBJECTIVE_TEXT := "Meta: %s"

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var mode_objective_label: Label = %ModeObjectiveLabel

var score_to_win := 20


func _ready() -> void:
	update_score(0, 0)
	mode_objective_label.text = TDM_OBJECTIVE_TEXT % score_to_win


func update_match_meta(match_meta: Dictionary) -> void:
	if not NetPayloads.is_match_meta(match_meta):
		return

	score_to_win = maxi(1, match_meta[NetKeys.SCORE_TO_WIN])
	mode_objective_label.text = TDM_OBJECTIVE_TEXT % score_to_win


func update_score(blue_score: int, red_score: int) -> void:
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)
