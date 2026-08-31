extends PlayerCharacter
class_name PlayerRemote

const CharacterVisual = preload("res://player/character/character_visual.gd")
const PlayerBoneAimApplier = preload("res://shared/player/player_bone_aim_applier.gd")
const PlayerBoneAimConfig = preload("res://shared/player/player_bone_aim_config.gd")
const ANIM_BLEND_TIME := 0.2
const RED_MATERIAL: StandardMaterial3D = preload("res://assets/materials/red_team_material.tres")
const BLUE_MATERIAL: StandardMaterial3D = preload("res://assets/materials/blue_team_material.tres")
const SKIN_VALUE_VARIATIONS := [-0.035, 0.0, 0.035]

@export var character_visual: CharacterVisual
@export var aim_pose_config: PlayerBoneAimConfig
@export var name_tag_player: Label

var bone_aim_cache := {}
var display_name := ""
var skin_value_offset: float = float(SKIN_VALUE_VARIATIONS.pick_random())

func _ready() -> void:
	super()

	if character_visual != null:
		bone_aim_cache = PlayerBoneAimApplier.build_cache(character_visual.get_skeleton(), aim_pose_config)

	update_player_colors()
	update_name_tag()


func update_body_geometry(old_data: Dictionary, new_data: Dictionary, lerp_weight: float) -> void:
	position = lerp(old_data[NetKeys.POS], new_data[NetKeys.POS], lerp_weight)
	rotation.y = lerp_angle(old_data[NetKeys.ROT_Y], new_data[NetKeys.ROT_Y], lerp_weight)
	set_anim(new_data[NetKeys.ANIM])
	set_rot_x_visuals(lerp_angle(old_data[NetKeys.ROT_X], new_data[NetKeys.ROT_X], lerp_weight))


func update_player_colors() -> void:
	if character_visual == null:
		return

	var team_material := BLUE_MATERIAL if team == GameEnums.Team.BLUE else RED_MATERIAL
	character_visual.apply_team_material(team_material)
	character_visual.apply_skin_variation(team_material, skin_value_offset)


func set_rot_x_visuals(rot_x: float) -> void:
	if character_visual == null:
		return

	PlayerBoneAimApplier.apply(
		character_visual.get_skeleton(),
		aim_pose_config,
		rot_x,
		bone_aim_cache
	)


func set_anim(anim_name: String) -> void:
	if character_visual == null:
		return

	if character_visual.is_game_animation_active(ClientNames.ANIM_AIR) and anim_name != ClientNames.ANIM_AIR:
		AudioManager.play_sfx(AudioManager.SFXKeys.JumpLand, global_position, 0.2)

	if character_visual.is_game_animation_active(anim_name):
		return

	character_visual.play_game_animation(anim_name, ANIM_BLEND_TIME)


func update_name_tag() -> void:
	name_tag_player.text = display_name


func play_shoot_fx() -> void:
	if weapon_holder != null and weapon_holder.weapon != null:
		weapon_holder.weapon.play_shoot_fx()


func play_footstep_sfx() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.Footstep, global_position, 0.2)
