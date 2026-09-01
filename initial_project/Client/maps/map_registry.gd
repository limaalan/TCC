class_name MapRegistry
extends RefCounted

const PROTOTYPE_MAP_ID := &"prototype"
const HIGHRISE_MAP_ID := &"highrise"

const MAP_SCENE_PATHS := {
	PROTOTYPE_MAP_ID: "res://maps/map_prototype.tscn",
	HIGHRISE_MAP_ID: "res://maps/highrise/map_highrise.tscn"
}

const MAP_DISPLAY_NAMES := {
	PROTOTYPE_MAP_ID: "Prototype",
}

static func get_map_data(map_id: StringName) -> MapData:
	if not MAP_SCENE_PATHS.has(map_id):
		return null

	return MapData.new(
		map_id,
		MAP_DISPLAY_NAMES.get(map_id, String(map_id)),
		MAP_SCENE_PATHS[map_id]
	)


static func get_map_scene(map_id: StringName) -> PackedScene:
	var map_data := get_map_data(map_id)
	if map_data == null:
		return null

	return load(map_data.scene_path) as PackedScene
