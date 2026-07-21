extends Resource
class_name PlayerBoneAimConfig

const PlayerBoneAimEntry = preload("res://shared/player/player_bone_aim_entry.gd")

@export var min_camera_rot_x := -PI / 2.0
@export var max_camera_rot_x := PI / 2.0
@export var entries: Array[PlayerBoneAimEntry] = []
