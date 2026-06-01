extends Node

const PLAYER_SCENE := preload("res://_debug/player_local_preview.tscn")

@export var map_scene: PackedScene
@export var fallback_spawn_position := Vector3(0, 1, 0)
@export var fallback_spawn_rotation_degrees := Vector3.ZERO

var current_map: Node3D
var current_player: CharacterBody3D


func _ready() -> void:
	if map_scene == null:
		push_error("Preview runner requires a map_scene.")
		return

	_load_preview()


func _load_preview() -> void:
	current_map = map_scene.instantiate() as Node3D
	if current_map == null:
		push_error("Configured map_scene did not instantiate a Node3D.")
		return

	current_map.name = "Map"
	add_child(current_map, true)

	current_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	if current_player == null:
		push_error("Player preview scene did not instantiate a CharacterBody3D.")
		return

	current_player.name = "PlayerLocalPreview"

	_place_player(current_player, current_map)
	add_child(current_player, true)


func _place_player(player: CharacterBody3D, map_root: Node) -> void:
	var spawn_points: Array = []
	if map_root.has_method("get_spawn_points"):
		var maybe_spawn_points = map_root.call("get_spawn_points")
		if maybe_spawn_points is Array:
			spawn_points = maybe_spawn_points

	for spawn_point in spawn_points:
		if spawn_point is Node3D and is_instance_valid(spawn_point):
			player.global_transform = spawn_point.global_transform
			return

	player.global_position = fallback_spawn_position
	player.rotation_degrees = fallback_spawn_rotation_degrees


func change_scene(_path_to_scene: String, _maybe_extra_args = null) -> void:
	get_tree().quit()


func clear_scenes() -> void:
	for child in get_children():
		if child == current_map or child == current_player:
			child.queue_free()

	current_map = null
	current_player = null
