extends PlayerCharacter
class_name PlayerRemote

const CharacterVisual = preload("res://player/character/character_visual.gd")
const PlayerBoneAimApplier = preload("res://shared/player/player_bone_aim_applier.gd")
const PlayerBoneAimConfig = preload("res://shared/player/player_bone_aim_config.gd")
const ANIM_BLEND_TIME := 0.2
const RED_MATERIAL: StandardMaterial3D = preload("res://assets/materials/red_team_material.tres")
const BLUE_MATERIAL: StandardMaterial3D = preload("res://assets/materials/blue_team_material.tres")
const BLUE_SKIN_COLORS: Array[Color] = [
	Color("6FA8FF"),
	Color("4F93F5"),
	Color("4CB8E6"),
	Color("6F8BE8"),
	Color("8C78D9"),
]
const RED_SKIN_COLORS: Array[Color] = [
	Color("9A3A35"),
	Color("B95042"),
	Color("CD6940"),
	Color("D98A46"),
	Color("D7A85A"),
]

@export var character_visual: CharacterVisual
@export var aim_pose_config: PlayerBoneAimConfig
@export var name_tag_player: Label

var bone_aim_cache := {}
var display_name := ""
var skin_color := Color.WHITE
var skin_color_team := GameEnums.NO_TEAM

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
	if skin_color_team != team:
		skin_color_team = team
		skin_color = (BLUE_SKIN_COLORS if team == GameEnums.Team.BLUE else RED_SKIN_COLORS).pick_random()

	var team_variant_material := team_material.duplicate() as StandardMaterial3D
	team_variant_material.albedo_color = skin_color
	character_visual.apply_team_material(team_variant_material)


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


func update_health_bar(current_health: int, max_health: int, changed_amount: int) -> void:
	super(current_health, max_health, changed_amount)
	if character_visual != null:
		character_visual.update_face_health(current_health, max_health, changed_amount)


func play_shoot_fx() -> void:
	if weapon_holder != null and weapon_holder.weapon != null:
		weapon_holder.weapon.play_shoot_fx()


func play_footstep_sfx() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.Footstep, global_position, 0.2)
