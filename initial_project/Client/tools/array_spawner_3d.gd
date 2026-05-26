@tool
extends Node3D
class_name ArraySpawner3D

const GENERATED_CONTAINER_NAME := "_Generated"

var _scene: PackedScene
var _count := 1
var _step_offset := Vector3(2, 0, 0)
var _step_rotation_degrees := Vector3.ZERO
var _centered := false
var _auto_rebuild_in_editor := true

@export var scene: PackedScene:
	get:
		return _scene
	set(value):
		_scene = value
		_request_rebuild()

@export_range(1, 256, 1) var count: int:
	get:
		return _count
	set(value):
		_count = maxi(1, value)
		_request_rebuild()

@export var step_offset: Vector3:
	get:
		return _step_offset
	set(value):
		_step_offset = value
		_request_rebuild()

@export var step_rotation_degrees: Vector3:
	get:
		return _step_rotation_degrees
	set(value):
		_step_rotation_degrees = value
		_request_rebuild()

@export var centered: bool:
	get:
		return _centered
	set(value):
		_centered = value
		_request_rebuild()

@export var auto_rebuild_in_editor: bool:
	get:
		return _auto_rebuild_in_editor
	set(value):
		_auto_rebuild_in_editor = value
		_request_rebuild()

@export var rebuild_now: bool:
	get:
		return false
	set(value):
		if not value:
			return

		if Engine.is_editor_hint():
			_rebuild()

@export var clear_now: bool:
	get:
		return false
	set(value):
		if not value:
			return

		if Engine.is_editor_hint():
			_clear_generated_children()


func _ready() -> void:
	if Engine.is_editor_hint() and _auto_rebuild_in_editor:
		_request_rebuild()


func _request_rebuild() -> void:
	if not Engine.is_editor_hint():
		return

	if not is_inside_tree():
		return

	if not _auto_rebuild_in_editor:
		return

	call_deferred("_rebuild")


func _rebuild() -> void:
	if not Engine.is_editor_hint():
		return

	_clear_generated_children()

	if _scene == null:
		return

	var container := _get_or_create_generated_container()
	var start_position := Vector3.ZERO
	if _centered and _count > 1:
		start_position = -_step_offset * float(_count - 1) * 0.5

	for i in range(_count):
		var instance := _scene.instantiate()
		if not instance is Node3D:
			push_error("ArraySpawner3D requires a PackedScene whose root extends Node3D.")
			instance.free()
			return

		var item := instance as Node3D
		item.name = "%s_%02d" % [_get_scene_name(), i + 1]
		item.position = start_position + _step_offset * i
		item.rotation_degrees = _step_rotation_degrees * i
		container.add_child(item)
		item.owner = _get_scene_owner()


func _clear_generated_children() -> void:
	var container := get_node_or_null(GENERATED_CONTAINER_NAME)
	if container == null:
		return

	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _get_or_create_generated_container() -> Node3D:
	var container := get_node_or_null(GENERATED_CONTAINER_NAME) as Node3D
	if container != null:
		return container

	container = Node3D.new()
	container.name = GENERATED_CONTAINER_NAME
	add_child(container)
	container.owner = _get_scene_owner()
	return container


func _get_scene_owner() -> Node:
	if owner != null:
		return owner

	return self


func _get_scene_name() -> String:
	if _scene == null:
		return "Item"

	var file_name := _scene.resource_path.get_file().get_basename()
	if file_name.is_empty():
		return "Item"

	return file_name.capitalize()
