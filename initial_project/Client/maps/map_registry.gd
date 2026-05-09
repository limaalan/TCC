class_name MapRegistry
extends RefCounted

const FARM_MAP_ID := &"farm"
const MAP_SCENE_PATHS := {
	FARM_MAP_ID: "res://maps/map_farm.tscn",
}

static func get_map_data(map_id: StringName) -> MapData:
	if not MAP_SCENE_PATHS.has(map_id):
		return null

	return MapData.new(map_id, "Farm", MAP_SCENE_PATHS[map_id])


static func get_map_scene(map_id: StringName) -> PackedScene:
	var map_data := get_map_data(map_id)
	if map_data == null:
		return null

	return load(map_data.scene_path) as PackedScene
