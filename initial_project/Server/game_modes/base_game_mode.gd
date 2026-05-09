class_name BaseGameMode
extends RefCounted

var lobby: Lobby


func _init(p_lobby: Lobby) -> void:
	lobby = p_lobby


func start_match() -> void:
	push_error("start_match() not implemented for this game mode.")


func handle_player_death(dead_player_id: int, killer_id: int) -> void:
	push_error("handle_player_death() not implemented for this game mode.")


func update_scores() -> void:
	push_error("update_scores() not implemented for this game mode.")


func should_end_after_disconnect() -> bool:
	return false


func make_end_match_payload() -> Dictionary:
	push_error("make_end_match_payload() not implemented for this game mode.")
	return NetPayloads.make_end_match(0, 0, [])


func on_match_timer_finished() -> void:
	lobby.end_match()
