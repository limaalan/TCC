class_name MapRegistry
extends RefCounted

const FARM_MAP_ID := &"farm"
const PROTOTYPE_MAP_ID := &"prototype"

const MAP_SCENE_PATHS := {
	FARM_MAP_ID: "res://maps/server_map_farm.tscn",
	PROTOTYPE_MAP_ID: "res://maps/server_map_farm.tscn",
}

const MAP_DISPLAY_NAMES := {
	FARM_MAP_ID: "Farm",
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

	print(
		"Server MapRegistry resolved map_id '%s' (%s) to scene '%s'."
		% [String(map_data.map_id), map_data.display_name, map_data.scene_path]
	)

	return load(map_data.scene_path) as PackedScene
