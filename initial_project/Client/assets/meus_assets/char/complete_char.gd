@tool
extends Node3D

enum PreviewState {
	IDLE,
	RUN,
	AIR,
}

@export_enum("idle", "run", "air") var preview_state: int = PreviewState.IDLE:
	set(value):
		preview_state = value
		if is_inside_tree():
			call_deferred("_apply_preview_state")

func _ready() -> void:
	_apply_preview_state()

func _get_part_root(node_name: String) -> Node:
	if has_node(node_name):
		return get_node(node_name)

	return find_child(node_name, true, false)

func _get_animation_player(node_name: String) -> AnimationPlayer:
	var part_root := _get_part_root(node_name)
	if part_root == null:
		return null

	for child in part_root.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer

	return part_root.find_child("AnimationPlayer", true, false) as AnimationPlayer

func _apply_preview_state() -> void:
	var char_player := _get_animation_player("char")
	var rings_player := _get_animation_player("rings")

	if char_player == null or rings_player == null:
		return

	match preview_state:
		PreviewState.IDLE:
			_play_animation(char_player, "Idle")
			_play_animation(rings_player, "idle")
		PreviewState.RUN:
			_play_animation(char_player, "hover_walk")
			_play_animation(rings_player, "hover_walk")
		PreviewState.AIR:
			_play_animation(char_player, "air")
			_play_animation(rings_player, "idle")

func _play_animation(player: AnimationPlayer, animation_name: String) -> void:
	if not player.has_animation(animation_name):
		push_warning("Animation '%s' not found on %s." % [animation_name, player.get_parent().name])
		return

	if player.current_animation == animation_name and player.is_playing():
		return

	player.play(animation_name)
