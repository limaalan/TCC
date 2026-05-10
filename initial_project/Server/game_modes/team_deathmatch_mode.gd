class_name TeamDeathmatchMode
extends "res://game_modes/base_game_mode.gd"


func start_match() -> void:
	lobby.spawn_players()
	update_scores()


func handle_player_death(dead_player_id: int, killer_id: int) -> void:
	lobby.client_data.get(dead_player_id)[NetKeys.DEATHS] += 1

	if dead_player_id != killer_id:
		lobby.client_data.get(killer_id)[NetKeys.KILLS] += 1

	update_scores()

	if has_score_limit_been_reached():
		lobby.end_match()


func calculate_scores() -> Dictionary:
	var scores := {
		GameEnums.Team.BLUE: 0,
		GameEnums.Team.RED: 0,
	}

	for data in lobby.client_data.values():
		if not data.has(NetKeys.TEAM):
			continue

		if data[NetKeys.TEAM] == GameEnums.Team.BLUE:
			scores[GameEnums.Team.RED] += data[NetKeys.DEATHS]
		else:
			scores[GameEnums.Team.BLUE] += data[NetKeys.DEATHS]

	return scores


func update_scores() -> void:
	var scores := calculate_scores()

	for client_id in lobby.get_connected_clients():
		lobby.s_update_game_scores.rpc_id(
			client_id,
			scores[GameEnums.Team.BLUE],
			scores[GameEnums.Team.RED]
		)


func has_score_limit_been_reached() -> bool:
	var scores := calculate_scores()

	return (
		scores[GameEnums.Team.BLUE] >= lobby.match_config.score_to_win
		or scores[GameEnums.Team.RED] >= lobby.match_config.score_to_win
	)


func should_end_after_disconnect() -> bool:
	var connected_blue_players := 0
	var connected_red_players := 0

	for client_id in lobby.get_connected_clients():
		var data: Dictionary = lobby.client_data.get(client_id)

		if not data.has(NetKeys.TEAM):
			return false

		if data[NetKeys.TEAM] == GameEnums.Team.BLUE:
			connected_blue_players += 1
		else:
			connected_red_players += 1

	return not connected_blue_players or not connected_red_players


func make_end_match_payload() -> Dictionary:
	var scores := calculate_scores()
	var players := lobby.make_end_match_players_payload()

	return NetPayloads.make_end_match(
		scores[GameEnums.Team.BLUE],
		scores[GameEnums.Team.RED],
		players
	)
