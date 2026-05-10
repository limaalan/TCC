extends Control

const BLUE_TEAM_COLOR := '0087FF'
const RED_TEAM_COLOR :='FF4D00'
@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var minutes_left_label: Label = %MinutesLeftLabel
@onready var seconds_left_label: Label = %SecondsLeftLabel
@onready var hill_state_label: Label = %HillStateLabel
@onready var elimination_text_container: VBoxContainer = %EliminationTextContainer

func _ready() -> void:
	update_score(0,0)
	update_match_time_left(0)
	hill_state_label.visible = false
	
func update_score(blue_score:int , red_score:int)->void:
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)

func update_match_time_left(time_left:int)->void:
	var minutes_left := time_left /60 
	var seconds_left := time_left - minutes_left*60
	
	minutes_left_label.text = str(minutes_left).lpad(2,"0")
	seconds_left_label.text = str(seconds_left).lpad(2,"0")

func update_hill_state(hill_state: Dictionary) -> void:
	if not NetPayloads.is_hill_state(hill_state):
		return

	hill_state_label.visible = true

	var control_state: int = hill_state[NetKeys.HILL_CONTROL_STATE]
	var controlling_team: int = hill_state[NetKeys.HILL_CONTROLLING_TEAM]

	match control_state:
		GameEnums.HillControlState.EMPTY:
			hill_state_label.text = "Hill: empty"
		GameEnums.HillControlState.CONTESTED:
			hill_state_label.text = "Hill: contested"
		GameEnums.HillControlState.CONTROLLED:
			if controlling_team == GameEnums.Team.BLUE:
				hill_state_label.text = "Hill: BLUE controlling"
			elif controlling_team == GameEnums.Team.RED:
				hill_state_label.text = "Hill: RED controlling"
			else:
				hill_state_label.text = "Hill: controlled"
		_:
			hill_state_label.text = "Hill: unknown"

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
