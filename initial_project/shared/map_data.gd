class_name MapData
extends Resource

@export var map_id: StringName = &""
@export var scene_path := ""

func _init(p_map_id: StringName = &"", p_scene_path: String = "") -> void:
	map_id = p_map_id
	scene_path = p_scene_path
