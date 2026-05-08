extends Control
class_name MatchEndInfoUI

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var blue_team_player_info_container: VBoxContainer = %BlueTeamPlayerInfoContainer
@onready var red_team_player_info_container: VBoxContainer = %RedTeamPlayerInfoContainer

var player_info_row_container_scene := preload("res://ui/match_end_info/player_info_row_container.tscn")

func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	
func show_score_infos(end_match_data: Dictionary)->void:
	if not NetPayloads.is_end_match(end_match_data):
		push_warning("Invalid end_match payload in MatchEndInfoUI")
		return

	blue_team_score_label.text = str(end_match_data[NetKeys.BLUE_SCORE])
	red_team_score_label.text = str(end_match_data[NetKeys.RED_SCORE])

	for data in end_match_data[NetKeys.PLAYERS]:
		var player_info_row: PlayerInfoRowContainer = player_info_row_container_scene.instantiate()
		
		player_info_row.set_data(data[NetKeys.DISPLAY_NAME], data[NetKeys.KILLS], data[NetKeys.DEATHS])
		
		var target_player_info_container: VBoxContainer
		
		if data[NetKeys.TEAM] == GameEnums.Team.BLUE :
			target_player_info_container = blue_team_player_info_container
		else :
			target_player_info_container = red_team_player_info_container
		
		target_player_info_container.add_child(player_info_row)


func _on_exit_button_pressed() -> void:
	get_tree().call_group(ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER, ClientNames.METHOD_CHANGE_SCENE, "res://ui/main_menu/main_menu.tscn")
