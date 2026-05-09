class_name HillZone
extends Area3D

enum ControlState {
	EMPTY,
	CONTROLLED,
	CONTESTED,
}

const NO_TEAM := -1

var lobby
var players_inside: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func setup(p_lobby) -> void:
	lobby = p_lobby
	clear_all_players()


func _on_body_entered(body: Node3D) -> void:
	var client_id := get_client_id_from_body(body)
	if client_id == 0:
		return

	players_inside[client_id] = true


func _on_body_exited(body: Node3D) -> void:
	var client_id := get_client_id_from_body(body)
	if client_id == 0:
		return

	clear_player(client_id)


func get_client_id_from_body(body: Node) -> int:
	if body == null:
		return 0

	var body_name := String(body.name)
	if not body_name.is_valid_int():
		return 0

	var client_id := body_name.to_int()
	if lobby == null:
		return 0

	if not lobby.server_players.has(client_id):
		return 0

	return client_id


func get_players_inside() -> Array[int]:
	var result: Array[int] = []

	for key in players_inside.keys():
		var client_id := int(key)
		if is_player_valid_for_control(client_id):
			result.append(client_id)

	return result


func get_teams_inside() -> Array[int]:
	var teams: Array[int] = []
	if lobby == null:
		return teams

	for client_id in get_players_inside():
		var data: Dictionary = lobby.client_data[client_id]
		if not data.has(NetKeys.TEAM):
			continue

		var team := int(data[NetKeys.TEAM])
		if not teams.has(team):
			teams.append(team)

	return teams


func get_control_state() -> int:
	var teams := get_teams_inside()
	if teams.is_empty():
		return ControlState.EMPTY

	if teams.size() > 1:
		return ControlState.CONTESTED

	return ControlState.CONTROLLED


func get_controlling_team() -> int:
	var teams := get_teams_inside()
	if teams.size() != 1:
		return NO_TEAM

	return teams[0]


func is_player_valid_for_control(client_id: int) -> bool:
	if lobby == null:
		return false

	if not lobby.client_data.has(client_id):
		return false

	var data: Dictionary = lobby.client_data[client_id]
	if not data.get(NetKeys.CONNECTED, false):
		return false

	if not data.has(NetKeys.TEAM):
		return false

	if not lobby.server_players.has(client_id):
		return false

	return true


func clear_player(client_id: int) -> void:
	players_inside.erase(client_id)


func clear_all_players() -> void:
	players_inside.clear()
