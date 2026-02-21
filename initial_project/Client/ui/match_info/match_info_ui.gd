extends Control

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel

func _ready() -> void:
	update_score(0,0)
	
func update_score(blue_score:int , red_score:int)->void:
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)
