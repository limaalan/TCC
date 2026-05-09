class_name MapData
extends Resource

@export var map_id: StringName = &""
@export var display_name: String = ""
@export var scene_path: String = ""

func _init(
	p_map_id: StringName = &"",
	p_display_name: String = "",
	p_scene_path: String = ""
) -> void:
	map_id = p_map_id
	display_name = p_display_name
	scene_path = p_scene_path
