extends Node3D
class_name CharacterVisual

const FALLBACK_ANIMATION := &"idle"
const LOOPED_CHAR_ANIMATIONS: Array[StringName] = [&"idle", &"air", &"hover_walk"]
const LOOPED_RINGS_ANIMATIONS: Array[StringName] = [&"idle", &"hover_walk"]
const CHAR_ANIMATION_MAP := {
	&"Idle": &"idle",
	&"Idle_Shoot": &"idle",
	&"Jump_Idle": &"air",
	&"Walk_Shoot": &"hover_walk",
	&"Run_Shoot": &"hover_walk",
}
const RINGS_ANIMATION_MAP := {
	&"Idle": &"idle",
	&"Idle_Shoot": &"idle",
	&"Jump_Idle": &"idle",
	&"Walk_Shoot": &"hover_walk",
	&"Run_Shoot": &"hover_walk",
}

@export var char_animation_player_path: NodePath
@export var rings_animation_player_path: NodePath
@export var skeleton_path: NodePath

var current_game_animation: StringName = &""

func _ready() -> void:
	_configure_gameplay_animation_loops()


func get_skeleton() -> Skeleton3D:
	return get_node_or_null(skeleton_path) as Skeleton3D


func get_current_animation_position() -> float:
	var player := _get_char_animation_player()
	if player == null:
		return 0.0

	return player.current_animation_position


func is_game_animation_active(anim_name: StringName) -> bool:
	if current_game_animation != anim_name:
		return false

	return _is_resolved_animation_active(_get_char_animation_player(), _resolve_char_animation(anim_name)) \
		and _is_resolved_animation_active(_get_rings_animation_player(), _resolve_rings_animation(anim_name))


func play_game_animation(anim_name: StringName, blend_time := 0.0) -> void:
	current_game_animation = anim_name
	_play_resolved_animation(_get_char_animation_player(), _resolve_char_animation(anim_name), blend_time)
	_play_resolved_animation(_get_rings_animation_player(), _resolve_rings_animation(anim_name), blend_time)


func sync_game_animation(anim_name: StringName, anim_position: float) -> void:
	current_game_animation = anim_name
	_sync_resolved_animation(_get_char_animation_player(), _resolve_char_animation(anim_name), anim_position)
	_sync_resolved_animation(_get_rings_animation_player(), _resolve_rings_animation(anim_name), anim_position)


func _get_char_animation_player() -> AnimationPlayer:
	return get_node_or_null(char_animation_player_path) as AnimationPlayer


func _get_rings_animation_player() -> AnimationPlayer:
	return get_node_or_null(rings_animation_player_path) as AnimationPlayer


func _configure_gameplay_animation_loops() -> void:
	_set_animation_loops(_get_char_animation_player(), LOOPED_CHAR_ANIMATIONS)
	_set_animation_loops(_get_rings_animation_player(), LOOPED_RINGS_ANIMATIONS)


func _set_animation_loops(player: AnimationPlayer, animation_names: Array[StringName]) -> void:
	if player == null:
		return

	for animation_name in animation_names:
		var animation := player.get_animation(animation_name)
		if animation == null:
			continue

		animation.loop_mode = Animation.LOOP_LINEAR


func _resolve_char_animation(anim_name: StringName) -> StringName:
	return _resolve_animation(_get_char_animation_player(), anim_name, CHAR_ANIMATION_MAP)


func _resolve_rings_animation(anim_name: StringName) -> StringName:
	return _resolve_animation(_get_rings_animation_player(), anim_name, RINGS_ANIMATION_MAP)


func _resolve_animation(
	player: AnimationPlayer,
	anim_name: StringName,
	anim_map: Dictionary
) -> StringName:
	if player == null:
		return &""

	if player.has_animation(anim_name):
		return anim_name

	var mapped_name := StringName(anim_map.get(anim_name, anim_name))
	if player.has_animation(mapped_name):
		return mapped_name

	if player.has_animation(FALLBACK_ANIMATION):
		return FALLBACK_ANIMATION

	return &""


func _play_resolved_animation(player: AnimationPlayer, resolved_animation: StringName, blend_time: float) -> void:
	if player == null or resolved_animation == &"":
		return

	if player.current_animation == resolved_animation and player.is_playing():
		return

	player.play(resolved_animation, blend_time)


func _is_resolved_animation_active(player: AnimationPlayer, resolved_animation: StringName) -> bool:
	if player == null or resolved_animation == &"":
		return false

	return player.current_animation == resolved_animation and player.is_playing()


func _sync_resolved_animation(player: AnimationPlayer, resolved_animation: StringName, anim_position: float) -> void:
	if player == null or resolved_animation == &"":
		return

	if player.current_animation != resolved_animation or not player.is_playing():
		player.play(resolved_animation)

	player.seek(anim_position, true)
	player.pause()
