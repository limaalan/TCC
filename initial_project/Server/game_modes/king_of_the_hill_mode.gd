class_name KingOfTheHillMode
extends "res://game_modes/base_game_mode.gd"

const SCORE_PER_SECOND := 1.0
const SCORE_BROADCAST_INTERVAL_SEC := 0.25
const HILL_STATE_BROADCAST_INTERVAL_SEC := 0.25
const HillZone = preload("res://game_modes/objectives/hill_zone.gd")

var hill_zone: HillZone
var scores := {
	GameEnums.Team.BLUE: 0.0,
	GameEnums.Team.RED: 0.0,
}
var score_broadcast_accumulator := 0.0
var hill_state_broadcast_accumulator := 0.0


func start_match() -> void:
	hill_zone = lobby.get_primary_hill_zone()

	if hill_zone == null:
		push_error("KING_OF_THE_HILL requires a HillZone objective.")
		lobby.end_match()
		return

	reset_scores()
	lobby.spawn_players()
	update_scores()
	update_hill_state()


func reset_scores() -> void:
	scores[GameEnums.Team.BLUE] = 0.0
	scores[GameEnums.Team.RED] = 0.0
	score_broadcast_accumulator = 0.0
	hill_state_broadcast_accumulator = 0.0


func physics_process(delta: float) -> void:
	if hill_zone == null:
		return

	var controlling_team: int = hill_zone.get_controlling_team()
	if controlling_team != GameEnums.NO_TEAM:
		add_score(controlling_team, delta)

	score_broadcast_accumulator += delta
	if score_broadcast_accumulator >= SCORE_BROADCAST_INTERVAL_SEC:
		score_broadcast_accumulator = 0.0
		update_scores()

	hill_state_broadcast_accumulator += delta
	if hill_state_broadcast_accumulator >= HILL_STATE_BROADCAST_INTERVAL_SEC:
		hill_state_broadcast_accumulator = 0.0
		update_hill_state()

	if has_score_limit_been_reached():
		update_scores()
		update_hill_state()
		lobby.end_match()


func add_score(team: int, delta: float) -> void:
	if not scores.has(team):
		return

	scores[team] += delta * SCORE_PER_SECOND


func handle_player_death(dead_player_id: int, killer_id: int) -> void:
	lobby.client_data.get(dead_player_id)[NetKeys.DEATHS] += 1

	if dead_player_id != killer_id:
		lobby.client_data.get(killer_id)[NetKeys.KILLS] += 1


func update_scores() -> void:
	for client_id in lobby.get_connected_clients():
		lobby.s_update_game_scores.rpc_id(
			client_id,
			get_blue_score_for_display(),
			get_red_score_for_display()
		)


func update_hill_state() -> void:
	lobby.update_hill_state(make_hill_state_payload())


func make_hill_state_payload() -> Dictionary:
	if hill_zone == null:
		return NetPayloads.make_hill_state(
			GameEnums.HillControlState.EMPTY,
			GameEnums.NO_TEAM,
			[]
		)

	return NetPayloads.make_hill_state(
		hill_zone.get_control_state(),
		hill_zone.get_controlling_team(),
		hill_zone.get_players_inside()
	)


func has_score_limit_been_reached() -> bool:
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


func on_match_timer_finished() -> void:
	lobby.end_match()


func make_end_match_payload() -> Dictionary:
	var players := lobby.make_end_match_players_payload()

	return NetPayloads.make_end_match(
		get_blue_score_for_display(),
		get_red_score_for_display(),
		players
	)


func get_blue_score_for_display() -> int:
	return floori(scores[GameEnums.Team.BLUE])


func get_red_score_for_display() -> int:
	return floori(scores[GameEnums.Team.RED])
