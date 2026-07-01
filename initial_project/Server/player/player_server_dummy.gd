extends CharacterBody3D
class_name ServerPlayerDummy

const CharacterVisual = preload("res://player/character/character_visual.gd")
const GAMEPLAY_HEAD_HEIGHT := 1.2
const PlayerBoneAimApplier = preload("res://shared/player/player_bone_aim_applier.gd")
const PlayerBoneAimConfig = preload("res://shared/player/player_bone_aim_config.gd")

@export var character_visual: CharacterVisual
@export var aim_pose_config: PlayerBoneAimConfig
@export var head: Node3D
@export var head_anchor: Node3D

var id: int
var bone_aim_cache := {}
var hitboxes: Array[RID] = []

func _ready() -> void:
	if character_visual != null:
		bone_aim_cache = PlayerBoneAimApplier.build_cache(character_visual.get_skeleton(), aim_pose_config)

	var skeleton := character_visual.get_skeleton() if character_visual != null else null
	if skeleton == null:
		return

	for bone in skeleton.get_children():
		for maybe_hitbox in bone.get_children():
			if maybe_hitbox is HitBox:
				hitboxes.append(maybe_hitbox.get_rid())
				maybe_hitbox.player = self


func update_body_geometry(player_data: Dictionary) -> void:
	position = player_data[NetKeys.POS]
	rotation.y = player_data[NetKeys.ROT_Y]

	if player_data.has(NetKeys.ANIM_POS) and character_visual != null:
		character_visual.sync_game_animation(player_data[NetKeys.ANIM], player_data[NetKeys.ANIM_POS])
		set_rot_x_visuals(player_data[NetKeys.ROT_X])

	_update_head_from_anchor(player_data[NetKeys.ROT_X])


func set_rot_x_visuals(rot_x: float) -> void:
	if character_visual == null:
		return

	PlayerBoneAimApplier.apply(
		character_visual.get_skeleton(),
		aim_pose_config,
		rot_x,
		bone_aim_cache
	)


func _update_head_from_anchor(rot_x: float) -> void:
	if head == null:
		return

	# The authoritative shot ray should match the local camera rig, not the visual head bone.
	head.position = Vector3(0.0, GAMEPLAY_HEAD_HEIGHT, 0.0)
	head.rotation.x = rot_x
	head.rotation.z = 0.0
