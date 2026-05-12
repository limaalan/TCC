extends Area3D
class_name DeathZone

var lobby: Lobby


func _ready() -> void:
	lobby = find_parent_lobby()
	body_entered.connect(_on_body_entered)


func find_parent_lobby() -> Lobby:
	var current := get_parent()
	while current != null:
		if current is Lobby:
			return current
		current = current.get_parent()

	push_warning("DeathZone '%s' is not inside a Lobby." % name)
	return null


func _on_body_entered(body: Node3D) -> void:
	if lobby == null:
		return

	if not body is PlayerServerReal:
		return

	var player := body as PlayerServerReal
	if player.lobby != lobby:
		return

	var player_id := player.name.to_int()
	player.die(player_id)
